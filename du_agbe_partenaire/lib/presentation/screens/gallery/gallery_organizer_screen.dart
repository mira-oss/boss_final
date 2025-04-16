import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/data/services/storage_service.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';
import 'package:patenaire/presentation/common_widgets/custom_button.dart';

class GalleryOrganizerScreen extends StatefulWidget {
  final String establishmentId;

  const GalleryOrganizerScreen({Key? key, required this.establishmentId})
    : super(key: key);

  @override
  _GalleryOrganizerScreenState createState() => _GalleryOrganizerScreenState();
}

class _GalleryOrganizerScreenState extends State<GalleryOrganizerScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<String> _allImages = [];
  Map<String, List<String>> _productImages = {};
  List<String> _unusedImages = [];

  @override
  void initState() {
    super.initState();
    _loadGalleryData();
  }

  Future<void> _loadGalleryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      // Charger toutes les images de l'établissement
      _allImages = await storageService.getEstablishmentImages(
        establishmentId: widget.establishmentId,
      );

      // Charger les associations produit-images
      _productImages = await storageService.getProductImagesMapping(
        establishmentId: widget.establishmentId,
      );

      // Déterminer les images non utilisées
      _unusedImages = _getUnusedImages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _getUnusedImages() {
    // Créer une liste de toutes les images utilisées par les produits
    final usedImages = _productImages.values.expand((i) => i).toList();

    // Filtrer les images non utilisées
    return _allImages.where((image) => !usedImages.contains(image)).toList();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      // Sauvegarder les associations produit-images
      await storageService.updateProductImagesMapping(
        establishmentId: widget.establishmentId,
        productImages: _productImages,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation sauvegardée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _moveImageToProduct(
    String imageUrl,
    String? fromProduct,
    String toProduct,
  ) {
    setState(() {
      // Retirer l'image de sa collection actuelle
      if (fromProduct == null) {
        _unusedImages.remove(imageUrl);
      } else {
        _productImages[fromProduct]?.remove(imageUrl);
      }

      // Ajouter l'image à la nouvelle collection
      if (_productImages.containsKey(toProduct)) {
        _productImages[toProduct]!.add(imageUrl);
      } else {
        _productImages[toProduct] = [imageUrl];
      }
    });
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      // Utiliser la nouvelle méthode pour supprimer l'image
      await storageService.deleteImageByUrl(imageUrl);

      // Supprimer l'image des collections locales
      setState(() {
        _allImages.remove(imageUrl);
        _unusedImages.remove(imageUrl);
        _productImages.forEach((productId, images) {
          images.remove(imageUrl);
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image supprimée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organiser la galerie'),
        backgroundColor: ColorConstants.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGalleryData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: LoadingIndicator(message: 'Chargement de la galerie...'),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Images non utilisées
                          _buildSection(
                            'Images non attribuées',
                            _unusedImages,
                            null,
                            Icons.image_not_supported_outlined,
                          ),
                          const Divider(height: 32),

                          // Images par produit
                          ..._productImages.entries.map(
                            (entry) => _buildSection(
                              'Produit: ${entry.key}',
                              entry.value,
                              entry.key,
                              Icons.category,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bouton de sauvegarde
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child:
                        _isSaving
                            ? const Center(child: CircularProgressIndicator())
                            : CustomButton(
                              text: 'Enregistrer les modifications',
                              onPressed: _saveChanges,
                              backgroundColor: ColorConstants.accentColor,
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> images,
    String? productId,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: ColorConstants.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              '(${images.length})',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (images.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Aucune image dans cette catégorie',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageUrl = images[index];
              return _buildImageTile(imageUrl, productId);
            },
          ),
      ],
    );
  }

  Widget _buildImageTile(String imageUrl, String? productId) {
    return Stack(
      children: [
        // Image
        GestureDetector(
          onTap: () => _showImageOptions(imageUrl, productId),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
        ),

        // Icône de suppression
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _confirmDeleteImage(imageUrl),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteImage(String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette image ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteImage(imageUrl);
                },
                child: const Text('Supprimer'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  void _showImageOptions(String imageUrl, String? currentProductId) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Déplacer l\'image vers'),
                enabled: false,
              ),
              if (currentProductId != null)
                ListTile(
                  leading: const Icon(Icons.image_not_supported_outlined),
                  title: const Text('Images non attribuées'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _productImages[currentProductId]!.remove(imageUrl);
                      _unusedImages.add(imageUrl);
                    });
                  },
                ),

              // Liste des produits disponibles
              ..._productImages.keys
                  .where((id) => id != currentProductId)
                  .map(
                    (id) => ListTile(
                      leading: const Icon(Icons.category),
                      title: Text('Produit: $id'),
                      onTap: () {
                        Navigator.pop(context);
                        _moveImageToProduct(imageUrl, currentProductId, id);
                      },
                    ),
                  ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Supprimer l\'image'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteImage(imageUrl);
                },
              ),
            ],
          ),
    );
  }
}
