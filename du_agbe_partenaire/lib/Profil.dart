import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';


class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;

  ThemeProvider(this._isDarkMode);

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  ThemeData get themeData =>
      _isDarkMode
          ? ThemeData.dark().copyWith(
            primaryColor: Colors.teal,
            colorScheme: const ColorScheme.dark(
              primary: Colors.teal,
              secondary: Colors.tealAccent,
              onPrimary: Colors.white,
            ),
          )
          : ThemeData.light().copyWith(
            primaryColor: Colors.teal,
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              secondary: Colors.tealAccent,
              onPrimary: Colors.white,
            ),
          );
}

class LocaleProvider with ChangeNotifier {
  String _currentLocale = 'fr';

  String get currentLocale => _currentLocale;

  LocaleProvider() {
    _loadLocaleFromPrefs();
  }

  void setLocale(String locale) {
    _currentLocale = locale;
    _saveLocaleToPrefs();
    notifyListeners();
  }

  Future<void> _loadLocaleFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLocale = prefs.getString('locale') ?? 'fr';
    notifyListeners();
  }

  Future<void> _saveLocaleToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('locale', _currentLocale);
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.request().isGranted) {
      return true;
    }
    return false;
  }

  Future<void> enableNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', true);
  }

  Future<void> disableNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', false);
  }

  Future<bool> areNotificationsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationsEnabled') ?? false;
  }
}

// La classe wrapper qui encapsule le ProfileSettingsPage avec les providers nécessaires
class ProfileSettingsWrapper extends StatelessWidget {
  const ProfileSettingsWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialiser les providers ici et les passer au widget enfant
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Récupérer les préférences utilisateur
        final prefs = snapshot.data!;
        final isDarkMode = prefs.getBool('isDarkMode') ?? false;

        // Fournir les providers nécessaires
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(isDarkMode),
            ),
            ChangeNotifierProvider<LocaleProvider>(
              create: (_) => LocaleProvider(),
            ),
          ],
          child: const ProfileSettingsPage(),
        );
      },
    );
  }
}

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final NotificationService _notificationService = NotificationService();

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _notificationsEnabled = false;

  // Informations du profil
  String _name = '';
  String _email = '';
  String _role = '';
  String _phone = '';
  String _photoUrl = '';
  String _restaurantName = '';
  String _restaurantDescription = '';
  List<String> _availableRoles = [
    'Gérant',
    'Employé',
    'Chef cuisinier',
    'Administrateur',
  ];

  // Pour l'édition du profil
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _restaurantNameController =
      TextEditingController();
  final TextEditingController _restaurantDescriptionController =
      TextEditingController();

  // Pour le changement de mot de passe
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showPassword = false;
  bool _passwordError = false;
  String _passwordErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _checkNotificationSettings();
    _notificationService.initialize();
  }

  Future<void> _checkNotificationSettings() async {
    bool enabled = await _notificationService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _restaurantNameController.dispose();
    _restaurantDescriptionController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData =
            await _firestore.collection('partners').doc(user.uid).get();

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          setState(() {
            _name = data['name'] ?? '';
            _email = user.email ?? '';
            _role = data['role'] ?? 'Gérant';
            _phone = data['phone'] ?? '';
            _photoUrl = data['photoUrl'] ?? '';
            _restaurantName = data['restaurantName'] ?? '';
            _restaurantDescription = data['description'] ?? '';

            _nameController.text = _name;
            _phoneController.text = _phone;
            _restaurantNameController.text = _restaurantName;
            _restaurantDescriptionController.text = _restaurantDescription;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Mise à jour du profil dans Firestore
        await _firestore.collection('partners').doc(user.uid).update({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'role': _role,
          'restaurantName': _restaurantNameController.text,
          'description': _restaurantDescriptionController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _name = _nameController.text;
          _phone = _phoneController.text;
          _restaurantName = _restaurantNameController.text;
          _restaurantDescription = _restaurantDescriptionController.text;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        User? user = _auth.currentUser;
        if (user != null) {
          File imageFile = File(image.path);

          // Télécharger l'image vers Firebase Storage
          Reference ref = _storage.ref().child('profile_images/${user.uid}');
          UploadTask uploadTask = ref.putFile(imageFile);
          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();

          // Mettre à jour l'URL de la photo dans Firestore
          await _firestore.collection('partners').doc(user.uid).update({
            'photoUrl': downloadUrl,
          });

          setState(() {
            _photoUrl = downloadUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de profil mise à jour')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement: $e')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = true;
        _passwordErrorMessage = 'Les mots de passe ne correspondent pas';
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _passwordError = true;
        _passwordErrorMessage =
            'Le mot de passe doit contenir au moins 6 caractères';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _passwordError = false;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null && _auth.currentUser?.email != null) {
        // Réauthentifier l'utilisateur
        AuthCredential credential = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // Changer le mot de passe
        await user.updatePassword(_newPasswordController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe mis à jour avec succès')),
        );

        // Réinitialiser les contrôleurs
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      String errorMessage = 'Erreur lors du changement de mot de passe';
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password') {
          errorMessage = 'Mot de passe actuel incorrect';
        }
      }

      setState(() {
        _passwordError = true;
        _passwordErrorMessage = errorMessage;
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // Navigation vers la page de connexion ou d'accueil
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
      );
    }
  }

  void _toggleNotifications(bool value) async {
    if (value) {
      bool hasPermission = await _notificationService.requestPermissions();
      if (hasPermission) {
        await _notificationService.enableNotifications();
        setState(() {
          _notificationsEnabled = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez accorder les permissions de notification dans les paramètres',
            ),
          ),
        );
      }
    } else {
      await _notificationService.disableNotifications();
      setState(() {
        _notificationsEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Assurez-vous que les providers sont disponibles
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil & Paramètres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor:
              themeProvider.isDarkMode ? Colors.tealAccent : Colors.teal,
          tabs: const [
            Tab(text: 'Profil', icon: Icon(Icons.person)),
            Tab(text: 'Sécurité', icon: Icon(Icons.security)),
            Tab(text: 'Paramètres', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Profil
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Photo de profil
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 3,
                                    color:
                                        themeProvider.isDarkMode
                                            ? Colors.tealAccent
                                            : Colors.teal,
                                  ),
                                ),
                                child:
                                    _photoUrl.isNotEmpty
                                        ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: _photoUrl,
                                            fit: BoxFit.cover,
                                            placeholder:
                                                (context, url) =>
                                                    const CircularProgressIndicator(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                    ),
                                          ),
                                        )
                                        : const Icon(Icons.person, size: 60),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.tealAccent
                                              : Colors.teal,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Informations personnelles
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informations personnelles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nom complet',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.person),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  readOnly: true,
                                  initialValue: _email,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.email),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Téléphone',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.phone),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _role,
                                  decoration: InputDecoration(
                                    labelText: 'Rôle',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.work),
                                  ),
                                  items:
                                      _availableRoles.map((String role) {
                                        return DropdownMenuItem<String>(
                                          value: role,
                                          child: Text(role),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _role = newValue!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Informations du restaurant
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informations de l\'établissement',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _restaurantNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nom de l\'établissement',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.store),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _restaurantDescriptionController,
                                  decoration: InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.description),
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bouton de sauvegarde
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateUserProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  themeProvider.isDarkMode
                                      ? Colors.tealAccent
                                      : Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child:
                                _isSaving
                                    ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    )
                                    : const Text(
                                      'Sauvegarder',
                                      style: TextStyle(fontSize: 16),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Sécurité
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Changer le mot de passe',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _currentPasswordController,
                                  obscureText: !_showPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Mot de passe actuel',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showPassword = !_showPassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: !_showPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Nouveau mot de passe',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.lock_open),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_showPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmer le mot de passe',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                  ),
                                ),
                                if (_passwordError) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _passwordErrorMessage,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSaving ? null : _changePassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          themeProvider.isDarkMode
                                              ? Colors.tealAccent
                                              : Colors.teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child:
                                        _isSaving
                                            ? const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            )
                                            : const Text(
                                              'Mettre à jour le mot de passe',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sessions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.tealAccent.withOpacity(
                                                0.2,
                                              )
                                              : Colors.teal.withOpacity(0.2),
                                    ),
                                    child: Icon(
                                      Icons.phone_android,
                                      color:
                                          themeProvider.isDarkMode
                                              ? Colors.tealAccent
                                              : Colors.teal,
                                    ),
                                  ),
                                  title: const Text('Cet appareil'),
                                  subtitle: const Text(
                                    'Dernière connexion: Aujourd\'hui',
                                  ),
                                  trailing: const Text(
                                    'Actif',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                                const Divider(),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.exit_to_app),
                                    onPressed: _signOut,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    label: const Text('Se déconnecter'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 3: Paramètres
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Card pour l'apparence
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Apparence',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  title: const Text('Mode sombre'),
                                  subtitle: const Text(
                                    'Activer/désactiver le thème sombre',
                                  ),
                                  trailing: FlutterSwitch(
                                    width: 60,
                                    height: 30,
                                    toggleSize: 25,
                                    activeColor: Colors.tealAccent,
                                    inactiveColor: Colors.grey,
                                    value: themeProvider.isDarkMode,
                                    onToggle: (value) {
                                      themeProvider.toggleTheme();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Préférences de langue
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Langue',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                RadioListTile<String>(
                                  title: const Text('Français'),
                                  value: 'fr',
                                  groupValue: localeProvider.currentLocale,
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      localeProvider.setLocale(value);
                                    }
                                  },
                                  activeColor:
                                      themeProvider.isDarkMode
                                          ? Colors.tealAccent
                                          : Colors.teal,
                                ),
                                RadioListTile<String>(
                                  title: const Text('English'),
                                  value: 'en',
                                  groupValue: localeProvider.currentLocale,
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      localeProvider.setLocale(value);
                                    }
                                  },
                                  activeColor:
                                      themeProvider.isDarkMode
                                          ? Colors.tealAccent
                                          : Colors.teal,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Notifications
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notifications',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  title: const Text(
                                    'Activer les notifications',
                                  ),
                                  subtitle: const Text(
                                    'Recevoir des alertes pour les nouvelles commandes',
                                  ),
                                  trailing: FlutterSwitch(
                                    width: 60,
                                    height: 30,
                                    toggleSize: 25,
                                    activeColor: Colors.tealAccent,
                                    inactiveColor: Colors.grey,
                                    value: _notificationsEnabled,
                                    onToggle: _toggleNotifications,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // À propos de l'application
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'À propos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: Icon(
                                    Icons.info_outline,
                                    color:
                                        themeProvider.isDarkMode
                                            ? Colors.tealAccent
                                            : Colors.teal,
                                  ),
                                  title: const Text(
                                    'Version de l\'application',
                                  ),
                                  subtitle: const Text('1.0.0'),
                                ),
                                const Divider(),
                                ListTile(
                                  leading: Icon(
                                    Icons.policy_outlined,
                                    color:
                                        themeProvider.isDarkMode
                                            ? Colors.tealAccent
                                            : Colors.teal,
                                  ),
                                  title: const Text(
                                    'Politique de confidentialité',
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    // Navigation vers la politique de confidentialité
                                  },
                                ),
                                const Divider(),
                                ListTile(
                                  leading: Icon(
                                    Icons.description_outlined,
                                    color:
                                        themeProvider.isDarkMode
                                            ? Colors.tealAccent
                                            : Colors.teal,
                                  ),
                                  title: const Text(
                                    'Conditions d\'utilisation',
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    
                                  },
                                ),
                                const Divider(),
                                ListTile(
                                  leading: Icon(
                                    Icons.help_outline,
                                    color:
                                        themeProvider.isDarkMode
                                            ? Colors.tealAccent
                                            : Colors.teal,
                                  ),
                                  title: const Text('Centre d\'aide'),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    // Navigation vers le centre d'aide
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
