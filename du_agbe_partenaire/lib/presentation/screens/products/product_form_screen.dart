import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patenaire/data/models/product_model.dart';
import 'package:patenaire/presentation/state/establishment_provider.dart';
import 'package:patenaire/data/services/firebase_service.dart';
import 'package:provider/provider.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId;

  const ProductFormScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCategory = 'Plat';
  bool _isAvailable = true;
  Map<String, dynamic>? _promotion;
  List<String> _photoUrls = [];

  File? _imageFile;
  bool _isEditMode = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.productId != null;
    if (_isEditMode) {
      _loadProductDetails();
    }
  }

  Future<void> _loadProductDetails() async {
    final product = await FirebaseService().getProductById(widget.productId!);
    setState(() {
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _selectedCategory = product.category;
      _isAvailable = product.available;
      _promotion = product.promotion;
      _photoUrls = product.photoUrls;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final establishmentProvider =
        Provider.of<EstablishmentProvider>(context, listen: false);
    final establishmentId =
        establishmentProvider.currentEstablishment!.id; // assure-toi qu'il existe

    String imageUrl = '';
    if (_imageFile != null) {
      imageUrl = await FirebaseService().uploadImage(_imageFile!);
      _photoUrls.add(imageUrl); // Ajoute à la liste des URLs
    }

    final product = Product(
      id: _isEditMode ? widget.productId! : '',
      establishmentId: establishmentId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      available: _isAvailable,
      category: _selectedCategory,
      photoUrls: _photoUrls,
      promotion: _promotion,
      options: [], // tu peux adapter plus tard si tu gères des options
    );

    if (_isEditMode) {
      await FirebaseService().updateProduct(product);
    } else {
      await FirebaseService().addProduct(product);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier le produit' : 'Ajouter un produit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du produit'),
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer un nom' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer un prix' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'Plat', child: Text('Plat')),
                  DropdownMenuItem(value: 'Boisson', child: Text('Boisson')),
                  DropdownMenuItem(value: 'Dessert', child: Text('Dessert')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration:
                    const InputDecoration(labelText: 'Catégorie du produit'),
              ),
              SwitchListTile(
                title: const Text('Disponible'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Prix en promotion (optionnel)'),
                keyboardType: TextInputType.number,
                initialValue: _promotion != null
                    ? _promotion!['price']?.toString()
                    : '',
                onChanged: (value) {
                  final promoPrice = double.tryParse(value);
                  setState(() {
                    _promotion = (promoPrice != null && promoPrice > 0)
                        ? {'price': promoPrice}
                        : null;
                  });
                },
              ),
              const SizedBox(height: 10),
              _imageFile != null
                  ? Image.file(_imageFile!, height: 150)
                  : _photoUrls.isNotEmpty
                      ? Image.network(_photoUrls.first, height: 150)
                      : const Text('Aucune image sélectionnée'),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Sélectionner une image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(_isEditMode ? 'Mettre à jour' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
