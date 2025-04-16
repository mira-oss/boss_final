import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/services/storage_service.dart';
import '../../../presentation/common_widgets/loading_indicator.dart';
import 'photo_upload_screen.dart';
import 'photo_editor_screen.dart';
import 'gallery_organizer_screen.dart';

class GalleryScreen extends StatefulWidget {
  final String establishmentId;

  const GalleryScreen({Key? key, required this.establishmentId})
    : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _galleryItems = [];

  @override
  void initState() {
    super.initState();
    _loadGalleryItems();
  }

  Future<void> _loadGalleryItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      // Obtenir les URLs des images
      final imageUrls = await storageService.getEstablishmentImages(
        establishmentId: widget.establishmentId,
      );

      // Convertir les URLs en objets avec des propriétés similaires à ce que vous attendez
      final List<Map<String, dynamic>> formattedItems = [];
      for (int i = 0; i < imageUrls.length; i++) {
        formattedItems.add({
          'id': 'img_$i', // Générer un ID temporaire
          'url': imageUrls[i],
          'description': '', // Description vide par défaut
          'order': i, // Ordre basé sur l'index
        });
      }

      setState(() {
        _galleryItems = formattedItems;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du chargement des images: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToPhotoUpload() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                PhotoUploadScreen(establishmentId: widget.establishmentId),
      ),
    );

    if (result == true) {
      // Reload gallery if new photos were added
      _loadGalleryItems();
    }
  }

  Future<void> _navigateToGalleryOrganizer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                GalleryOrganizerScreen(establishmentId: widget.establishmentId),
      ),
    );

    if (result == true) {
      // Reload gallery if changes were made
      _loadGalleryItems();
    }
  }

  Future<void> _viewImage(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PhotoEditorScreen(
              imageUrl: _galleryItems[index]['url'],
              imageId: _galleryItems[index]['id'],
              establishmentId: widget.establishmentId,
              description: _galleryItems[index]['description'],
            ),
      ),
    );

    if (result == true) {
      // Reload gallery if changes were made
      _loadGalleryItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galerie photos'),
        backgroundColor: ColorConstants.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed:
                _galleryItems.isNotEmpty ? _navigateToGalleryOrganizer : null,
            tooltip: 'Organiser la galerie',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: LoadingIndicator(message: 'Chargement de la galerie...'),
              )
              : _galleryItems.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Votre galerie est vide',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const Text(
                      'Ajoutez des photos pour mettre en valeur votre établissement',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _galleryItems.length,
                itemBuilder: (context, index) {
                  final item = _galleryItems[index];
                  return GestureDetector(
                    onTap: () => _viewImage(index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(item['url'], fit: BoxFit.cover),
                            if (item['description'] != null &&
                                item['description'].isNotEmpty)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    item['description'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToPhotoUpload,
        backgroundColor: ColorConstants.accentColor,
        child: const Icon(Icons.add_photo_alternate),
        tooltip: 'Ajouter des photos',
      ),
    );
  }
}
