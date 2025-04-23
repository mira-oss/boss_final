import 'package:du_agbe_pro/changerMotdePasse.dart';
import 'package:du_agbe_pro/dashboard.dart';
import 'package:du_agbe_pro/services/auth.dart';
import 'package:du_agbe_pro/sign.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});
  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showPassword = false;
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Déconnecter l'utilisateur pour forcer la connexion
    Future.delayed(Duration.zero, () async {
      // S'il y a un utilisateur déjà connecté, on le déconnecte pour forcer une nouvelle connexion
      if (_auth.currentUser != null) {
        debugPrint('Utilisateur déjà connecté: ${_auth.currentUser!.email}');
        debugPrint(
          'Déconnexion forcée pour exiger une nouvelle authentification',
        );
        await _auth.signOut();
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      // Afficher l'email utilisé pour le débogage
      debugPrint('Tentative de connexion avec: ${emailController.text.trim()}');
      // Méthode directe de Firebase Auth plutôt que votre méthode Auth() personnalisée
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      debugPrint('Connexion réussie: ${userCredential.user?.uid}');

      // Vérifier si l'utilisateur doit changer son mot de passe
      final userDoc =
          await _firestore
              .collection('users')
              .doc(userCredential.user?.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        // Vérifier si l'attribut a_changer_mdp existe et est à false
        if (userData != null &&
            userData.containsKey('a_changer_mdp') &&
            userData['a_changer_mdp'] == false) {
          // L'utilisateur doit changer son mot de passe
          debugPrint('Utilisateur doit changer son mot de passe');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangePasswordPage(),
              ),
            );
            return;
          }
        }
      }

      // Si tout est en ordre, rediriger vers le dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur FirebaseAuth: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _checkUserExists() async {
    if (emailController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer un email pour vérifier'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() => isLoading = true);
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(
        emailController.text.trim(),
      );
      debugPrint('Méthodes de connexion disponibles: $methods');
      if (mounted) {
        if (methods.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aucun compte associé à cet email. Veuillez vous inscrire.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Un compte existe avec cet email. Méthodes de connexion: ${methods.join(", ")}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(
        'Erreur lors de la vérification de l\'existence de l\'utilisateur: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la vérification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleSocialLogin(
    Future<UserCredential> Function() socialSignIn,
  ) async {
    try {
      setState(() => isLoading = true);
      final userCredential = await socialSignIn();

      // Vérifier si l'utilisateur doit changer son mot de passe après connexion sociale
      final userDoc =
          await _firestore
              .collection('users')
              .doc(userCredential.user?.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        // Vérifier si l'attribut a_changer_mdp existe et est à false
        if (userData != null &&
            userData.containsKey('a_changer_mdp') &&
            userData['a_changer_mdp'] == false) {
          // L'utilisateur doit changer son mot de passe
          debugPrint(
            'Utilisateur connecté via réseau social doit changer son mot de passe',
          );
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangePasswordPage(),
              ),
            );
            return;
          }
        }
      }

      // Si tout est en ordre, rediriger vers le dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
    } catch (e) {
      debugPrint('Erreur de connexion sociale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de connexion: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    debugPrint('Erreur de connexion: [${e.code}] ${e.message}');
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email. Vérifiez l\'orthographe ou inscrivez-vous.';
      case 'wrong-password':
        return 'Mot de passe incorrect. Veuillez réessayer.';
      case 'invalid-email':
        return 'Format d\'email invalide. Exemple: utilisateur@domaine.com';
      case 'user-disabled':
        return 'Ce compte a été désactivé. Contactez le support.';
      case 'too-many-requests':
        return 'Trop de tentatives de connexion. Veuillez réessayer plus tard.';
      case 'network-request-failed':
        return 'Problème de connexion réseau. Vérifiez votre connexion internet.';
      case 'invalid-credential':
        return 'Identifiants invalides. Vérifiez votre email et mot de passe.';
      default:
        return 'Erreur de connexion: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.02),
            // Utiliser un placeholder si l'image ne charge pas
            Container(
              width: size.width * 0.9,
              height: size.height * 0.36,
              decoration: BoxDecoration(
                color:
                    Colors
                        .grey
                        .shade200, // Couleur par défaut si l'image ne charge pas
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://tse4.mm.bing.net/th?id=OIP.r7BYYWaRTSnYsX1Y-Hm69QHaFj&pid=Api&P=0&h=180',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Déboguer pourquoi l'image ne charge pas
                    debugPrint('Erreur de chargement d\'image: $error');
                    return const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Content de vous revoir !',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.005),
            const Text(
              'Connectez-vous pour continuer votre aventure.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.03),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      // Simple validation pour l'email
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      // Réinitialiser les messages d'erreur lors de la modification
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    onEditingComplete: _checkUserExists,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      labelText: 'Email',
                      hintText: 'ex : elisha@gmail.com',
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      // Réinitialiser les messages d'erreur lors de la modification
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: "Mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed:
                            () => setState(() => showPassword = !showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: size.width * 0.88,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child:
                          isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "Se connecter",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // Navigation vers la page de réinitialisation de mot de passe
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.015),
            const Text(
              'Ou se connecter avec',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            SizedBox(height: size.height * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    //  _handleSocialLogin(() => Auth().signInWithGoogle());
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Image.asset(
                      'assets/images/google.jpg',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Erreur de chargement image Google: $error');
                        return const Icon(Icons.g_mobiledata_rounded, size: 40);
                      },
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 30,
                  child: Image.asset(
                    'assets/images/fa.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Erreur de chargement image Facebook: $error');
                      return const Icon(
                        Icons.facebook,
                        size: 40,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pas de compte ?'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InscriptionPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'S\'inscrire',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            // Bouton de vérification d'utilisateur
            TextButton(
              onPressed: _checkUserExists,
              child: const Text('Vérifier si l\'email existe'),
            ),
          ],
        ),
      ),
    );
  }
}
