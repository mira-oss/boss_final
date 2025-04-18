import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AjoutLieu extends StatefulWidget {
  const AjoutLieu({super.key});

  @override
  State<AjoutLieu> createState() => _AjoutLieuState();
}

class _AjoutLieuState extends State<AjoutLieu> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  String _categorie = 'Centre de bien-être';
  List<String> _selectedMoods = [];
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Centre de bien-être',
    'Spa',
    'Yoga studio',
    'Maison de thé',
    'Parc tranquille',
    'Bibliothèque calme',
    'Cabin en nature',
    'Espace de méditation',
    'Restaurant',
    'Bar',
    'Cafe',
    'Hotel',
    'Plage',
    'Espace coworking',
    'Supermarche',
  ];

  final List<String> _allMoods = [
    'Calme',
    'Serein',
    'Zen',
    'Apaisant',
    'Respirant',
    'Harmonieux',
    'Naturel',
    'Minimaliste',
    'Chaleureux',
    'Inspirant',
    'Enveloppant',
    'Lumineux'
  ];

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _generateTempPassword() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _ajouterLieu() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final tempPassword = _generateTempPassword();
      final nomLieu = _nomController.text;
      
      // Ajout dans la collection 'lieux'
      final lieuRef = await FirebaseFirestore.instance.collection('lieux').add({
        'nom': nomLieu,
        'categorie': _categorie,
        'statut': 'en_attente',
        'date_creation': FieldValue.serverTimestamp(),
        'mot_de_passe_temp': tempPassword,
        'a_changer_mdp': true,
        'moods': _selectedMoods, // Stocke aussi les moods directement dans le lieu
      });

      // Ajout dans la collection 'relax_moods' pour faciliter les recherches
      if (_selectedMoods.isNotEmpty) {
        for (final mood in _selectedMoods) {
          await FirebaseFirestore.instance.collection('relax_moods').add({
            'lieu_id': lieuRef.id,
            'nom_lieu': nomLieu,
            'mood': mood,
            'categorie': _categorie,
            'date_ajout': FieldValue.serverTimestamp(),
          });
        }
      }

      _showSnack('Demande envoyée avec succès! Mot de passe temporaire: $tempPassword');
      _nomController.clear();
      setState(() {
        _selectedMoods = [];
      });
    } catch (e) {
      _showSnack('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un lieu de détente'),
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
                  labelText: 'Nom du lieu',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  prefixIcon: Icon(Icons.place, color: Colors.blue),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _categorie,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  prefixIcon: Icon(Icons.category, color: Colors.blue),
                ),
                items: _categories.map((categorie) => DropdownMenuItem<String>(
                  value: categorie,
                  child: Text(categorie),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _categorie = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Ambiances relaxantes',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  prefixIcon: Icon(Icons.mood, color: Colors.blue),
                ),
                child: Column(
                  children: [
                    Text(
                      'Sélectionnez les ambiances qui correspondent à ce lieu',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _allMoods.map((mood) {
                        return FilterChip(
                          label: Text(mood),
                          selected: _selectedMoods.contains(mood),
                          selectedColor: Colors.blue,
                          checkmarkColor: Colors.blue,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMoods.add(mood);
                              } else {
                                _selectedMoods.remove(mood);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_selectedMoods.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Text(
                        'Ambiances sélectionnées:',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: _selectedMoods.map((mood) => Chip(
                          label: Text(mood),
                          backgroundColor: Colors.teal[50],
                          deleteIconColor: Colors.teal[800],
                          onDeleted: () {
                            setState(() {
                              _selectedMoods.remove(mood);
                            });
                          },
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _ajouterLieu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Envoyer la demande'),
              ),
              const SizedBox(height: 20),
              Text(
                'Ce lieu sera évalué pour s\'assurer qu\'il offre une véritable expérience de détente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.teal[800], fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }
}