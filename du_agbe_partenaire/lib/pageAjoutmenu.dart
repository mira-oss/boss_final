import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMenuPage extends StatefulWidget {
  const AddMenuPage({Key? key}) : super(key: key);

  @override
  _AddMenuPageState createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  File? _image;
  final _picker = ImagePicker();
  bool _isLoading = false;
  
  // Liste des catégories disponibles
  final List<String> _categories = [
    'Entrées',
    'Plats principaux',
    'Pizzas',
    'Pâtes',
    'Salades',
    'Desserts',
    'Boissons',
    'Vins',
    'Spécialités'
  ];
  
  // Valeur sélectionnée dans le dropdown
  String? _selectedCategory;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Réduire la qualité pour optimiser la taille
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Convertir l'image en base64
  Future<String> _imageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  Future<void> _addMenu() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Convertir l'image en base64
        String imageBase64 = await _imageToBase64(_image!);
        
        // Appeler la fonction d'ajout à Firebase
        await _addMenuToFirebase(
          nom: _titleController.text,
          description: _descriptionController.text,
          prix: double.parse(_priceController.text),
          categorie: _selectedCategory!,
          imageBase64: imageBase64,
        );
        
        // Réinitialiser le formulaire
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        setState(() {
          _image = null;
          _selectedCategory = null;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addMenuToFirebase({
    required String nom,
    required String description,
    required double prix,
    required String categorie,
    required String imageBase64,
  }) async {
    try {
      // Valider les données d'entrée
      if (nom.isEmpty || description.isEmpty || prix <= 0 || categorie.isEmpty) {
        throw 'Tous les champs sont obligatoires et le prix doit être positif';
      }

      final CollectionReference menus = 
          FirebaseFirestore.instance.collection('menus');

      await menus.add({
        'nom': nom,
        'description': description,
        'prix': prix,
        'categorie': categorie,
        'imageBase64': imageBase64, // Image stockée en base64
        'dateCreation': FieldValue.serverTimestamp(), // Date/heure automatique
        'disponible': true, // Par défaut le menu est disponible
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu ajouté avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Propager l'erreur pour la gérer dans _addMenu
      throw 'Erreur lors de l\'ajout du menu: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un menu'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Ajout du menu en cours...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Catégorie du menu (dropdown)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Sélectionnez une catégorie'),
                            value: _selectedCategory,
                            icon: const Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            style: const TextStyle(color: Colors.black, fontSize: 16),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            },
                            items: _categories.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Titre du menu
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre du menu',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un titre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Description du menu
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer une description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Prix du menu
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Prix (€)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.euro),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un prix';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Image du menu
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _image != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _image!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _image = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 20, color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image, size: 50, color: Colors.grey),
                                    const SizedBox(height: 10),
                                    const Text('Aucune image sélectionnée'),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: _pickImage,
                                      icon: const Icon(Icons.add_photo_alternate),
                                      label: const Text('Choisir une image'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Bouton d'ajout
                      ElevatedButton(
                        onPressed: _addMenu,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'AJOUTER',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}