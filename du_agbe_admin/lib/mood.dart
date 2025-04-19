import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleMoodForm extends StatefulWidget {
  const SimpleMoodForm({super.key});

  @override
  State<SimpleMoodForm> createState() => _SimpleMoodFormState();
}

class _SimpleMoodFormState extends State<SimpleMoodForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  
  String _name = '';
  
  Future<void> _saveMood() async {
    if (_formKey.currentState!.validate()) {
      // Récupérer la valeur du champ
      _name = _nameController.text.trim();

      try {
        // Créer l'objet à enregistrer
        final moodData = {
          'name': _name,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Enregistrer dans Firestore
        await _firestore.collection('moods').add(moodData);

        // Afficher un message de succès
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood ajouté avec succès!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Réinitialiser le formulaire
        _nameController.clear();
      } catch (e) {
        // Afficher un message d'erreur
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un Mood'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Champ pour le nom du mood
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du mood',
                  hintText: 'Ex: Relax, Festif, Romantique...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mood),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom pour le mood';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Bouton d'ajout
              Center(
                child: ElevatedButton(
                  onPressed: _saveMood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'AJOUTER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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