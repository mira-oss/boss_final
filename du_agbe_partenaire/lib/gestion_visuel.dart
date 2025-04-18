import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

// Modèle de données pour les images
class GalleryImage {
  final String id;
  final String url;
  final String type; // Menu, Salle, Ambiance
  final DateTime uploadDate;
  final String fileName;

  GalleryImage({
    required this.id,
    required this.url,
    required this.type,
    required this.uploadDate,
    required this.fileName,
  });

  factory GalleryImage.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return GalleryImage(
      id: doc.id,
      url: data['url'] ?? '',
      type: data['type'] ?? 'Menu',
      uploadDate: (data['uploadDate'] as Timestamp).toDate(),
      fileName: data['fileName'] ?? 'image.jpg',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'fileName': fileName,
    };
  }
}

// Provider pour gérer l'état des images
class GalleryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String partnerId;

  List<GalleryImage> _images = [];
  bool _isLoading = false;
  String _filterType = 'Tous';

  GalleryProvider({required this.partnerId}) {
    fetchImages();
  }

  List<GalleryImage> get images {
    if (_filterType == 'Tous') {
      return _images;
    } else {
      return _images.where((img) => img.type == _filterType).toList();
    }
  }

  bool get isLoading => _isLoading;
  String get filterType => _filterType;

  void setFilter(String filter) {
    _filterType = filter;
    notifyListeners();
  }

  Future<void> fetchImages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot =
          await _firestore
              .collection('partners')
              .doc(partnerId)
              .collection('gallery')
              .orderBy('uploadDate', descending: true)
              .get();

      _images =
          snapshot.docs.map((doc) => GalleryImage.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors du chargement des images: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadImage(File file, String type) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Générer un ID unique pour l'image
      final String imageId = const Uuid().v4();
      final String fileName = path.basename(file.path);
      final String fileExtension = path.extension(fileName);
      final String storagePath =
          'partners/$partnerId/gallery/$imageId$fileExtension';

      // Uploader l'image vers Firebase Storage
      final ref = _storage.ref().child(storagePath);
      await ref.putFile(file);

      // Récupérer l'URL de téléchargement
      final String downloadUrl = await ref.getDownloadURL();

      // Créer un document dans Firestore
      final GalleryImage newImage = GalleryImage(
        id: imageId,
        url: downloadUrl,
        type: type,
        uploadDate: DateTime.now(),
        fileName: fileName,
      );

      await _firestore
          .collection('partners')
          .doc(partnerId)
          .collection('gallery')
          .doc(imageId)
          .set(newImage.toMap());

      // Ajouter à la liste locale
      _images.insert(0, newImage);
    } catch (e) {
      print('Erreur lors de l\'upload: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteImage(GalleryImage image) async {
    try {
      // Supprimer de Firestore
      await _firestore
          .collection('partners')
          .doc(partnerId)
          .collection('gallery')
          .doc(image.id)
          .delete();

      // Supprimer de Firebase Storage
      await _storage.refFromURL(image.url).delete();

      // Supprimer de la liste locale
      _images.removeWhere((img) => img.id == image.id);
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la suppression: $e');
    }
  }
}

class VisualsManagementPage extends StatefulWidget {
  final String partnerId;

  const VisualsManagementPage({Key? key, required this.partnerId})
    : super(key: key);

  @override
  _VisualsManagementPageState createState() => _VisualsManagementPageState();
}

class _VisualsManagementPageState extends State<VisualsManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _selectedType = 'Menu';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      final provider = Provider.of<GalleryProvider>(context, listen: false);
      switch (_tabController.index) {
        case 0:
          provider.setFilter('Tous');
          break;
        case 1:
          provider.setFilter('Menu');
          break;
        case 2:
          provider.setFilter('Salle');
          break;
        case 3:
          provider.setFilter('Ambiance');
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Afficher la boîte de dialogue pour choisir le type
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Catégorie d\'image'),
                content: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Choisissez une catégorie pour cette image:',
                        ),
                        const SizedBox(height: 20),
                        DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'Menu',
                              child: Text('Menu / Plats'),
                            ),
                            DropdownMenuItem(
                              value: 'Salle',
                              child: Text('Salle / Intérieur'),
                            ),
                            DropdownMenuItem(
                              value: 'Ambiance',
                              child: Text('Ambiance / Événements'),
                            ),
                          ],
                          onChanged: (value) {
                            setStateDialog(() {
                              _selectedType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Image.file(
                          File(pickedFile.path),
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ],
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() {
                        _isUploading = true;
                      });

                      // Upload de l'image
                      final provider = Provider.of<GalleryProvider>(
                        context,
                        listen: false,
                      );
                      await provider.uploadImage(
                        File(pickedFile.path),
                        _selectedType,
                      );

                      setState(() {
                        _isUploading = false;
                      });

                      // Feedback utilisateur
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image téléchargée avec succès!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Télécharger'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      print('Erreur lors de la sélection d\'image: $e');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter une photo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF2F7FB),
                  child: Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF2F7FB),
                  child: Icon(Icons.photo_library, color: Colors.orange),
                ),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<GalleryImage> images) {
    // Filtrer par recherche si nécessaire
    final filteredImages =
        _searchQuery.isEmpty
            ? images
            : images
                .where(
                  (img) => img.fileName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();

    if (filteredImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Aucune image correspondant à "$_searchQuery"'
                  : 'Aucune image dans cette catégorie',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Ajouter des photos'),
              onPressed: _showImageOptions,
            ),
          ],
        ),
      );
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      padding: const EdgeInsets.all(10),
      itemCount: filteredImages.length,
      itemBuilder: (context, index) {
        final image = filteredImages[index];
        return GestureDetector(
          onTap: () => _showImageDetails(image),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Image avec chargement progressif
                CachedNetworkImage(
                  imageUrl: image.url,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          color: Colors.white,
                          height: index % 3 == 0 ? 200 : 140,
                        ),
                      ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                // Badge pour le type d'image
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getColorForType(image.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      image.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Menu':
        return Colors.green;
      case 'Salle':
        return Colors.blue;
      case 'Ambiance':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  void _showImageDetails(GalleryImage image) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  // Poignée de défilement
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Détails et image
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Image en grand
                        Hero(
                          tag: 'image_${image.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: CachedNetworkImage(
                              imageUrl: image.url,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      color: Colors.white,
                                      height: 300,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Informations
                        ListTile(
                          leading: const Icon(Icons.image, color: Colors.blue),
                          title: const Text('Nom du fichier'),
                          subtitle: Text(image.fileName),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.category,
                            color: Colors.green,
                          ),
                          title: const Text('Catégorie'),
                          subtitle: Text(image.type),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _getColorForType(image.type),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              image.type,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.calendar_today,
                            color: Colors.purple,
                          ),
                          title: const Text('Date d\'ajout'),
                          subtitle: Text(
                            '${image.uploadDate.day}/${image.uploadDate.month}/${image.uploadDate.year}',
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.share),
                              label: const Text('Partager'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () {
                                // Implémenter le partage
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Fonctionnalité de partage à implémenter',
                                    ),
                                  ),
                                );
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.delete),
                              label: const Text('Supprimer'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmDelete(image);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(GalleryImage image) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer cette image?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cette action est irréversible. Êtes-vous sûr de vouloir supprimer cette image?',
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: image.url,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // Animation de chargement
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  // Supprimer l'image
                  final provider = Provider.of<GalleryProvider>(
                    context,
                    listen: false,
                  );
                  await provider.deleteImage(image);

                  // Fermer l'animation de chargement
                  Navigator.pop(context);

                  // Feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image supprimée avec succès'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GalleryProvider(partnerId: widget.partnerId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des Photos'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Tous'),
              Tab(text: 'Menu / Plats'),
              Tab(text: 'Salle / Intérieur'),
              Tab(text: 'Ambiance / Événements'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Conseils pour de bonnes photos'),
                        content: const SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📸 Conseils pour de meilleures photos:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '• Utilisez un bon éclairage, de préférence naturel',
                              ),
                              Text(
                                '• Prenez vos plats sous leur meilleur angle',
                              ),
                              Text(
                                '• Gardez votre appareil stable pour éviter le flou',
                              ),
                              Text(
                                '• Montrez l\'ambiance de votre établissement',
                              ),
                              Text(
                                '• Variez les types de photos pour attirer différents clients',
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Compris'),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une image...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // Contenu principal
            Expanded(
              child: Consumer<GalleryProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Stack(
                    children: [
                      TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGrid(provider.images),
                          _buildGrid(
                            provider.images
                                .where((img) => img.type == 'Menu')
                                .toList(),
                          ),
                          _buildGrid(
                            provider.images
                                .where((img) => img.type == 'Salle')
                                .toList(),
                          ),
                          _buildGrid(
                            provider.images
                                .where((img) => img.type == 'Ambiance')
                                .toList(),
                          ),
                        ],
                      ),
                      if (_isUploading)
                        Container(
                          color: Colors.black45,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 20),
                                Text(
                                  'Téléchargement en cours...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showImageOptions,
          child: const Icon(Icons.add_photo_alternate),
          tooltip: 'Ajouter une photo',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

// Point d'entrée pour cette page
// Supprimez cette partie si vous avez déjà un fichier main.dart
// void main() {
//   runApp(MaterialApp(
//     title: 'Gestion des Visuels',
//     theme: ThemeData(
//       primarySwatch: Colors.blue,
//       visualDensity: VisualDensity.adaptivePlatformDensity,
//     ),
//     home: VisualsManagementPage(partnerId: 'partner123'),
//   ));
// }
