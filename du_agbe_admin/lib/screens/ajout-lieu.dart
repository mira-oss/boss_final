import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AjoutPartenaire extends StatefulWidget {
  const AjoutPartenaire({super.key});
  @override
  State<AjoutPartenaire> createState() => _AjoutPartenaireState();
}

class _AjoutPartenaireState extends State<AjoutPartenaire> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _categorie = '';
  List<String> _selectedMoods = [];
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<String> _categories = [];
  List<String> _allMoods = [];
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndMoods();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        final metadata = user.metadata;
        if (metadata.creationTime?.isBefore(metadata.lastSignInTime ?? DateTime.now()) ?? false) {
          await _firestore.collection('partenaires').doc(user.uid).update({
            'a_changer_mdp': true,
            'dernier_mdp_change': FieldValue.serverTimestamp()
          });
        }
      }
    });
  }

  Future<void> _loadCategoriesAndMoods() async {
    try {
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();
      
      final moodsSnapshot = await _firestore
          .collection('moods')
          .orderBy('name')
          .get();
      
      setState(() {
        _categories = categoriesSnapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();
        
        _allMoods = moodsSnapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();
        
        if (_categories.isNotEmpty) {
          _categorie = _categories.first;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Erreur de chargement: ${e.toString()}');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _generateTempPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#&*';
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(12, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<void> _ajouterPartenaire() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categories.isEmpty || _allMoods.isEmpty) {
      _showSnack('Veuillez charger les catégories et ambiances');
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final email = _emailController.text.trim();
      final nomLieu = _nomController.text;
      final phone = _phoneController.text.trim();

      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        _showSnack('Cet email est déjà utilisé');
        return;
      }

      final tempPassword = _generateTempPassword();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );
      
      final userId = credential.user!.uid;

      await _firestore.collection('partenaires').doc(userId).set({
        'nom': nomLieu,
        'email': email,
        'phone': phone,
        'categorie': _categorie,
        'statut': 'en_attente',
        'date_creation': FieldValue.serverTimestamp(),
        'a_changer_mdp': false,
        'moods': _selectedMoods,
        'uid': userId,
        'dernier_mdp_change': null,
      });

      await _auth.sendPasswordResetEmail(email: email);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Succès'),
          content: const Text('Le partenaire a été créé et un lien de réinitialisation a été envoyé.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      _resetForm();
    } catch (e) {
      _showSnack('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _nomController.clear();
    _emailController.clear();
    _phoneController.clear();
    setState(() {
      _selectedMoods = [];
      if (_categories.isNotEmpty) _categorie = _categories.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un partenaire'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom du partenaire',
                  prefixIcon: Icon(Icons.business, color: Colors.blue),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Colors.blue),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value?.contains('@') ?? false ? null : 'Email invalide',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone, color: Colors.blue),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _categorie,
                items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => setState(() => _categorie = value ?? ''),
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Ambiances',
                  prefixIcon: Icon(Icons.mood, color: Colors.blue),
                ),
                child: Wrap(
                  spacing: 8,
                  children: _allMoods.map((mood) => FilterChip(
                    label: Text(mood),
                    selected: _selectedMoods.contains(mood),
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: _selectedMoods.contains(mood) 
                        ? Colors.blue[800]
                        : Colors.black,
                    ),
                    onSelected: (v) => setState(() => v 
                      ? _selectedMoods.add(mood) 
                      : _selectedMoods.remove(mood)),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _ajouterPartenaire,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'CRÉER LE PARTENAIRE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}