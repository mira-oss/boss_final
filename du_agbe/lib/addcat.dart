import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddCategoryForm extends StatefulWidget {
  final Map<String, dynamic>? existingCategory;

  const AddCategoryForm({Key? key, this.existingCategory}) : super(key: key);

  @override
  _AddCategoryFormState createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<AddCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variables pour les champs du formulaire
  String _name = '';
  String _icon = 'utensils';
  String _color = '#2196F3'; // Changé pour la couleur bleue principale
  bool _isActive = true;
  int _order = 0;

  // Liste des icônes disponibles
  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'utensils', 'icon': FontAwesomeIcons.utensils, 'label': 'Restaurant'},
    {'name': 'umbrella-beach', 'icon': FontAwesomeIcons.umbrellaBeach, 'label': 'Plage'},
    {'name': 'shopping-bag', 'icon': FontAwesomeIcons.shoppingBag, 'label': 'Shopping'},
    {'name': 'music', 'icon': FontAwesomeIcons.music, 'label': 'Événement'},
    {'name': 'landmark', 'icon': FontAwesomeIcons.landmark, 'label': 'Culture'},
    {'name': 'mug-hot', 'icon': FontAwesomeIcons.mugHot, 'label': 'Café'},
  ];

  // Liste des couleurs prédéfinies (adaptée à la nouvelle palette)
  final List<String> _availableColors = [
    '#2196F3', // Bleu primaire
    '#64B5F6', // Bleu clair
    '#0D47A1', // Bleu foncé
    '#00A859', // Vert
    '#FF6B00', // Orange
    '#6E3BFF', // Violet
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      _name = widget.existingCategory!['name'];
      _icon = widget.existingCategory!['icon'];
      _color = widget.existingCategory!['color'];
      _isActive = widget.existingCategory!['isActive'];
      _order = widget.existingCategory!['order'];
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final categoryData = {
          'name': _name,
          'icon': _icon,
          'color': _color,
          'isActive': _isActive,
          'order': _order,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.existingCategory == null) {
          categoryData['createdAt'] = FieldValue.serverTimestamp();
          await _firestore.collection('categories').add(categoryData);
        } else {
          await _firestore
              .collection('categories')
              .doc(widget.existingCategory!['id'])
              .update(categoryData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catégorie ${widget.existingCategory == null ? 'ajoutée' : 'modifiée'} avec succès!'),
            backgroundColor: HexColor('#2196F3'),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCategory == null ? 'Nouvelle Catégorie' : 'Modifier Catégorie'),
        backgroundColor: HexColor('#2196F3'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Champ Nom
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Nom de la catégorie',
                  hintText: 'Ex: Restaurants',
                  enabledBorder: OutlineInputBorder( // Bordure normale
                    borderSide: BorderSide(color: HexColor('#2196F3')),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder( // Bordure quand le champ est sélectionné
                    borderSide: BorderSide(color: HexColor('#0D47A1'), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelStyle: TextStyle(color: HexColor('#2196F3')),
                ),
              ),
              SizedBox(height: 20),

              // Sélection d'icône
              Text('Icône', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HexColor('#2196F3'),
                  )),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _availableIcons.map((iconData) {
                  return ChoiceChip(
                    label: FaIcon(iconData['icon'], color: Colors.white),
                    selected: _icon == iconData['name'],
                    onSelected: (selected) {
                      setState(() {
                        _icon = iconData['name'];
                      });
                    },
                    backgroundColor: Colors.grey[300],
                    selectedColor: HexColor('#2196F3'),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),

              // Sélection de couleur
              Text('Couleur', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HexColor('#2196F3'),
                  )),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _availableColors.map((colorHex) {
                  return ChoiceChip(
                    label: Container(width: 24, height: 24),
                    selected: _color == colorHex,
                    onSelected: (selected) {
                      setState(() {
                        _color = colorHex;
                      });
                    },
                    backgroundColor: HexColor(colorHex),
                    selectedColor: HexColor(colorHex),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),

              // Ordre
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Ordre d\'affichage',
                  hintText: 'Ex: 1, 2, 3...',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: HexColor('#2196F3')),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: HexColor('#0D47A1'), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder( // Bordure en cas d'erreur
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Active/Inactive
              SwitchListTile(
                title: Text('Catégorie active',
                    style: TextStyle(color: HexColor('#2196F3'))),
                value: _isActive,
                activeColor: HexColor('#2196F3'),
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              SizedBox(height: 30),

              // Bouton de soumission
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: Text(
                      widget.existingCategory == null ? 'AJOUTER' : 'MODIFIER',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor('#2196F3'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
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

// Helper pour les couleurs hexadécimales
class HexColor extends Color {
  HexColor(final String hexColor) : super(_parseHexColor(hexColor));

  static int _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return int.parse(hexColor, radix: 16);
  }
}