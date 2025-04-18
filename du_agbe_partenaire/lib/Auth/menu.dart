import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:du_agbe_pro/pageAjoutmenu.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RestaurantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Restaurant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: RestaurantHomePage(),
    );
  }
}

class RestaurantHomePage extends StatefulWidget {
  @override
  _RestaurantHomePageState createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  int _selectedIndex = 1;
  String _selectedCategory = 'Tous';
  final List<String> _categories = [
    'Tous',
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
  
  // Map pour stocker les plats par catégorie
  Map<String, List<MenuItem>> _menuItems = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialiser les catégories avec des listes vides
    for (var category in _categories) {
      _menuItems[category] = [];
    }
    // Charger les données depuis Firestore
    _loadMenuItems();
  }

  // Fonction pour charger les menus depuis Firestore
  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('menus')
          .orderBy('dateCreation', descending: true)
          .get();

      // Réinitialiser les listes
      for (var category in _categories) {
        _menuItems[category] = [];
      }

      // Remplir les données
      for (var doc in querySnapshot.docs) {
        // Extraire les données du document
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Construire un objet MenuItem
        MenuItem item = MenuItem(
          id: doc.id,
          name: data['nom'] ?? 'Sans nom',
          description: data['description'] ?? 'Pas de description',
          price: (data['prix'] ?? 0.0).toDouble(),
          imageBase64: data['imageBase64'] ?? '',
          category: data['categorie'] ?? 'Tous',
          isAvailable: data['disponible'] ?? true,
        );

        // Ajouter à la catégorie spécifique
        if (_categories.contains(item.category)) {
          _menuItems[item.category]!.add(item);
        }
        
        // Ajouter à la catégorie "Tous"
        if (!_menuItems.containsKey('Tous')) {
          _menuItems['Tous'] = [];
        }
        _menuItems['Tous']!.add(item);
      }

      // Mettre à jour l'interface
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des menus: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors du chargement des menus. Veuillez réessayer.';
        });
      }
    }
  }

  // Fonction pour supprimer un menu
  Future<void> _deleteMenuItem(String id) async {
    try {
      // Afficher une boîte de dialogue de confirmation
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirmation'),
          content: Text('Voulez-vous vraiment supprimer ce menu ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Supprimer de Firestore
      await FirebaseFirestore.instance
          .collection('menus')
          .doc(id)
          .delete();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      // Mettre à jour la liste
      _loadMenuItems();

      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu supprimé avec succès')),
      );
    } catch (e) {
      // Fermer l'indicateur de chargement s'il est affiché
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fonction pour changer la disponibilité d'un menu
  Future<void> _toggleAvailability(MenuItem item) async {
    try {
      // Mettre à jour dans Firestore
      await FirebaseFirestore.instance
          .collection('menus')
          .doc(item.id)
          .update({
        'disponible': !item.isAvailable,
      });

      // Mettre à jour la liste
      _loadMenuItems();

      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !item.isAvailable 
                ? 'Menu marqué comme disponible' 
                : 'Menu marqué comme indisponible'
          ),
        ),
      );
    } catch (e) {
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _editMenuItem(MenuItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMenuPage(menuItem: item),
      ),
    ).then((value) {
      if (value == true) {
        _loadMenuItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'La Bonne Table',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMenuItems,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un plat...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10.0),
              ),
            ),
          ),
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () => _onCategorySelected(category),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 5.0),
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
                    : _buildMenuList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigation avec rafraîchissement au retour
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMenuPage()),
          );
          
          // Si un nouveau menu a été ajouté, rafraîchir la liste
          if (result == true) {
            _loadMenuItems();
          }
        },
        backgroundColor: const Color.fromARGB(255, 53, 161, 249),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildMenuList() {
    final items = _menuItems[_selectedCategory] ?? [];
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text('Aucun plat disponible dans cette catégorie'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            color: Colors.red,
            child: Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Confirmation'),
                content: Text('Voulez-vous vraiment supprimer ce menu ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            _deleteMenuItem(item.id);
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: InkWell(
              onTap: () => _showMenuOptions(item),
              child: Row(
                children: [
                  // Image du menu (from base64 or placeholder)
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                    ),
                    child: item.imageBase64.isNotEmpty
                        ? Image.memory(
                            base64Decode(item.imageBase64),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print("Erreur d'affichage de l'image: $error");
                              return _buildPlaceholderImage();
                            },
                          )
                        : _buildPlaceholderImage(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                              if (!item.isAvailable)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Indisponible',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 5.0),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14.0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 5.0),
                          Text(
                            '${item.price.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () => _showMenuOptions(item),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMenuOptions(MenuItem item) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  _editMenuItem(item);
                },
              ),
              ListTile(
                leading: Icon(
                  item.isAvailable ? Icons.visibility_off : Icons.visibility,
                  color: item.isAvailable ? Colors.orange : Colors.green,
                ),
                title: Text(
                  item.isAvailable ? 'Marquer comme indisponible' : 'Marquer comme disponible'
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleAvailability(item);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMenuItem(item.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[300],
      child: Icon(Icons.restaurant, color: Colors.grey[500], size: 40),
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageBase64;
  final String category;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageBase64,
    this.category = 'Tous',
    this.isAvailable = true,
  });
}

// Page de modification de menu
class EditMenuPage extends StatefulWidget {
  final MenuItem menuItem;

  const EditMenuPage({Key? key, required this.menuItem}) : super(key: key);

  @override
  _EditMenuPageState createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  File? _image;
  final _picker = ImagePicker();
  bool _isLoading = false;
  String? _selectedCategory;
  String? _existingImageBase64;
  bool _isAvailable = true;
  
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.menuItem.name);
    _descriptionController = TextEditingController(text: widget.menuItem.description);
    _priceController = TextEditingController(text: widget.menuItem.price.toString());
    _selectedCategory = widget.menuItem.category;
    _existingImageBase64 = widget.menuItem.imageBase64;
    _isAvailable = widget.menuItem.isAvailable;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Réduire la qualité pour optimiser la taille
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _existingImageBase64 = null; // Réinitialiser l'image existante
      });
    }
  }

  // Convertir l'image en base64
  Future<String> _imageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  Future<void> _updateMenu() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      if (_image == null && _existingImageBase64 == null) {
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
        // Déterminer quelle image utiliser
        String imageBase64;
        if (_image != null) {
          // Nouvelle image sélectionnée
          imageBase64 = await _imageToBase64(_image!);
        } else {
          // Utiliser l'image existante
          imageBase64 = _existingImageBase64!;
        }
        
        // Mettre à jour dans Firebase
        await FirebaseFirestore.instance
            .collection('menus')
            .doc(widget.menuItem.id)
            .update({
          'nom': _titleController.text,
          'description': _descriptionController.text,
          'prix': double.parse(_priceController.text),
          'categorie': _selectedCategory!,
          'imageBase64': imageBase64,
          'disponible': _isAvailable,
        });
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu mis à jour avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Retourner à la page précédente avec indication de mise à jour
        Navigator.pop(context, true);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le menu'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Mise à jour du menu en cours...'),
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
                      // Switch pour la disponibilité
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Disponible', 
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                            )
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: (value) {
                              setState(() {
                                _isAvailable = value;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
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
                            : _existingImageBase64 != null && _existingImageBase64!.isNotEmpty
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          base64Decode(_existingImageBase64!),
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error, size: 40, color: Colors.red),
                                                  Text("Erreur de chargement de l'image"),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _existingImageBase64 = null;
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
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
),
                                      ],
                                    ),
                                  ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Bouton de mise à jour
                      ElevatedButton(
                        onPressed: _updateMenu,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'Mettre à jour le menu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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