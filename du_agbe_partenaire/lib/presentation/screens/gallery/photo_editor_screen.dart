import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/services/storage_service.dart';
import '../../../presentation/common_widgets/custom_button.dart';
import '../../../presentation/common_widgets/loading_indicator.dart';

class PhotoEditorScreen extends StatefulWidget {
  final String imageUrl;
  final String imageId;
  final String establishmentId;
  final String? description;

  const PhotoEditorScreen({
    Key? key,
    required this.imageUrl,
    required this.imageId,
    required this.establishmentId,
    this.description,
  }) : super(key: key);

  @override
  _PhotoEditorScreenState createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  late TextEditingController _descriptionController;
  File? _editedImage;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.description ?? '',
    );
    _descriptionController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final hasTextChanges =
        _descriptionController.text != (widget.description ?? '');
    final hasImageChanges = _editedImage != null;

    setState(() {
      _hasChanges = hasTextChanges || hasImageChanges;
    });
  }

  Future<void> _cropImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      final tempFile = await storageService.downloadImageToTemp(
        widget.imageUrl,
      );

      if (tempFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de télécharger l\'image pour édition'),
          ),
        );
        return;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: tempFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer l\'image',
            toolbarColor: ColorConstants.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Recadrer l\'image'),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _editedImage = File(croppedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'édition: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      // Update description if changed
      if (_descriptionController.text != (widget.description ?? '')) {
        await storageService.updateImageMetadata(
          establishmentId: widget.establishmentId,
          imageId: widget.imageId,
          description: _descriptionController.text,
        );
      }

      // Update image if edited
      if (_editedImage != null) {
        await storageService.updateImage(
          establishmentId: widget.establishmentId,
          imageId: widget.imageId,
          newImageFile: _editedImage!,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modifications enregistrées avec succès')),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteImage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette image ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final storageService = Provider.of<StorageService>(
          context,
          listen: false,
        );
        await storageService.deleteImage(
          establishmentId: widget.establishmentId,
          imageId: widget.imageId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image supprimée avec succès')),
        );

        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: ${e.toString()}'),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditer la photo'),
        backgroundColor: ColorConstants.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteImage(), // Correction ici pour VoidCallback
            tooltip: 'Supprimer l\'image',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: LoadingIndicator(message: 'Traitement en cours...'),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          _editedImage != null
                              ? Image.file(_editedImage!, fit: BoxFit.contain)
                              : Image.network(
                                widget.imageUrl,
                                fit: BoxFit.contain,
                              ),
                    ),

                    const SizedBox(height: 16),

                    CustomButton(
                      text: 'Recadrer l\'image',
                      icon: Icons.crop,
                      onPressed:
                          () =>
                              _cropImage(), // Correction ici pour VoidCallback
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Enregistrer les modifications',
                      onPressed:
                          _hasChanges
                              ? () => _saveChanges()
                              : null, // Correction ici pour VoidCallback
                      backgroundColor: ColorConstants.accentColor,
                    ),
                  ],
                ),
              ),
    );
  }
}
