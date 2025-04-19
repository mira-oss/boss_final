import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleCategoryForm extends StatefulWidget {
  const SimpleCategoryForm({super.key});

  @override
  State<SimpleCategoryForm> createState() => _SimpleCategoryFormState();
}

class _SimpleCategoryFormState extends State<SimpleCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();

  String _name = '';
  String _icon = 'utensils';
  String _color = '#2196F3';
  int _order = 0;

  // Liste des icônes de base
  final List<Map<String, dynamic>> _icons = [
    {'name': 'utensils', 'icon': FontAwesomeIcons.utensils},
    {'name': 'shopping-bag', 'icon': FontAwesomeIcons.shoppingBag},
    {'name': 'music', 'icon': FontAwesomeIcons.music},
  ];

  // Couleurs de base
  final List<String> _colors = [
    '#2196F3', // Bleu
    '#4CAF50', // Vert
    '#FF9800', // Orange
  ];

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      // Récupérer les valeurs des champs
      _name = _nameController.text;
      _order = int.tryParse(_orderController.text) ?? 0;

      try {
        // Créer l'objet à enregistrer
        final categoryData = {
          'name': _name,
          'icon': _icon,
          'color': _color,
          'order': _order,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Enregistrer dans Firestore
        await _firestore.collection('categories').add(categoryData);

        // Afficher un message de succès
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catégorie ajoutée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );

        // Réinitialiser le formulaire
        _nameController.clear();
        _orderController.clear();
        setState(() {
          _icon = 'utensils';
          _color = '#2196F3';
        });
      } catch (e) {
        // Afficher un message d'erreur
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une Catégorie'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Champ pour le nom
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la catégorie',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sélection d'icône
              const Text('Icône', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: _icons.map((iconData) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: FaIcon(
                        iconData['icon'],
                        color: _icon == iconData['name'] ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _icon = iconData['name'];
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Sélection de couleur
              const Text('Couleur', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: _colors.map((colorHex) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _color = colorHex;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _parseColor(colorHex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color == colorHex ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Champ pour l'ordre
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(
                  labelText: 'Ordre d\'affichage',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un ordre';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Bouton d'ajout
              Center(
                child: ElevatedButton(
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text(
                    'AJOUTER',
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
      ),
    );
  }

  // Fonction helper pour convertir les couleurs hexadécimales
  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}