import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/services/storage_service.dart';
import '../../../presentation/common_widgets/custom_button.dart';
import '../../../presentation/common_widgets/loading_indicator.dart';

class PhotoUploadScreen extends StatefulWidget {
  final String establishmentId;

  const PhotoUploadScreen({Key? key, required this.establishmentId})
    : super(key: key);

  @override
  _PhotoUploadScreenState createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isUploading = false;
  String _description = '';

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImages.add(photo);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une image'),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      for (var image in _selectedImages) {
        await storageService.uploadProductImage(
          widget.establishmentId,
          File(image.path),
          description: _description,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Images téléchargées avec succès')),
      );

      setState(() {
        _selectedImages = [];
        _description = '';
      });

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des photos'),
        backgroundColor: ColorConstants.primaryColor,
      ),
      body:
          _isUploading
              ? const Center(
                child: LoadingIndicator(message: 'Téléchargement en cours...'),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Galerie',
                            icon: Icons.photo_library,
                            onPressed: () => _pickImages(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: 'Appareil photo',
                            icon: Icons.camera_alt,
                            onPressed: () => _takePicture(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (_selectedImages.isNotEmpty) ...[
                      const Text(
                        'Photos sélectionnées:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Stack(
                                children: [
                                  Image.file(
                                    File(_selectedImages[index].path),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnelle)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _description = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Télécharger',
                      onPressed:
                          _selectedImages.isNotEmpty
                              ? () => _uploadImages()
                              : null,
                      backgroundColor: ColorConstants.accentColor,
                    ),
                  ],
                ),
              ),
    );
  }
}
