import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:du_agbe_pro/Auth/login.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final formKey = GlobalKey<FormState>();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;

  Future<void> updatePassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final user = auth.currentUser;

      if (user == null) throw Exception('Utilisateur non connecté');

      // Vérifier que les mots de passe correspondent
      if (newPasswordController.text != confirmPasswordController.text) {
        throw Exception('Les mots de passe ne correspondent pas');
      }

      // Mettre à jour le mot de passe
      await user.updatePassword(newPasswordController.text.trim());
      
      // Mettre à jour Firestore
      await firestore.collection('users').doc(user.uid).update({
        'a_changer_mdp': true,
      });

      // Rediriger vers la page de connexion
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ConnexionPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changement de mot de passe obligatoire'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              const Text(
                'Pour des raisons de sécurité, vous devez changer votre mot de passe avant de continuer.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: newPasswordController,
                obscureText: !showPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ obligatoire';
                  if (value.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(showPassword 
                        ? Icons.visibility 
                        : Icons.visibility_off),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: !showPassword,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: isLoading ? null : updatePassword,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Confirmer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}