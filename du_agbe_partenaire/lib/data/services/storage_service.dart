import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart'; // Pour getTemporaryDirectory
import 'package:http/http.dart' as http; // Pour télécharger l'image

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = Uuid();

  Future<String> uploadProductImage(
    String establishmentId,
    File imageFile, {
    String? description,
  }) async {
    try {
      final imageId = _uuid.v4();
      final fileName = '$imageId${path.extension(imageFile.path)}';
      final ref = _storage.ref().child(
        'establishments/$establishmentId/products/$fileName',
      );

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType:
              'image/${path.extension(imageFile.path).replaceAll('.', '')}',
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (description != null && description.isNotEmpty) {
        await _firestore
            .collection('establishments')
            .doc(establishmentId)
            .collection('productImageMetadata')
            .doc(imageId)
            .set({
              'description': description,
              'url': downloadUrl,
              'uploadedAt': FieldValue.serverTimestamp(),
            });
      }

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload product image: $e');
    }
  }

  Future<String> uploadEstablishmentImage(
    String establishmentId,
    File imageFile,
  ) async {
    try {
      final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
      final ref = _storage.ref().child(
        'establishments/$establishmentId/profile/$fileName',
      );

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType:
              'image/${path.extension(imageFile.path).replaceAll('.', '')}',
        ),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload establishment image: $e');
    }
  }

  Future<List<String>> uploadGalleryImages(
    String establishmentId,
    List<File> imageFiles,
  ) async {
    try {
      List<String> urls = [];

      for (var imageFile in imageFiles) {
        final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
        final ref = _storage.ref().child(
          'establishments/$establishmentId/gallery/$fileName',
        );

        final uploadTask = ref.putFile(
          imageFile,
          SettableMetadata(
            contentType:
                'image/${path.extension(imageFile.path).replaceAll('.', '')}',
          ),
        );

        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw Exception('Failed to upload gallery images: $e');
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete product image: $e');
    }
  }

  Future<void> deleteEstablishmentImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete establishment image: $e');
    }
  }

  Future<void> deleteGalleryImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete gallery image: $e');
    }
  }

  Future<List<String>> getEstablishmentImages({
    required String establishmentId,
  }) async {
    try {
      final results =
          await _storage
              .ref()
              .child('establishments/$establishmentId/gallery')
              .listAll();

      List<String> urls = [];
      for (var item in results.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw Exception('Failed to get establishment images: $e');
    }
  }

  Future<Map<String, List<String>>> getProductImagesMapping({
    required String establishmentId,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('establishments')
              .doc(establishmentId)
              .collection('productImages')
              .get();

      Map<String, List<String>> result = {};
      for (var doc in snapshot.docs) {
        result[doc.id] = List<String>.from(doc.data()['images'] ?? []);
      }
      return result;
    } catch (e) {
      throw Exception('Failed to get product images mapping: $e');
    }
  }

  Future<void> updateProductImagesMapping({
    required String establishmentId,
    required Map<String, List<String>> productImages,
  }) async {
    try {
      final batch = _firestore.batch();
      final collectionRef = _firestore
          .collection('establishments')
          .doc(establishmentId)
          .collection('productImages');

      final existingDocs = await collectionRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      for (var entry in productImages.entries) {
        if (entry.value.isNotEmpty) {
          final docRef = collectionRef.doc(entry.key);
          batch.set(docRef, {'images': entry.value});
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update product images mapping: $e');
    }
  }

  Future<void> deleteImageFromStorageOnly(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  Future<File?> downloadImageToTemp(String imageUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final file = File(tempPath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      return null;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image: $e');
      return null;
    }
  }

  Future<void> updateImageMetadata({
    required String establishmentId,
    required String imageId,
    required String description,
  }) async {
    try {
      await _firestore
          .collection('establishments')
          .doc(establishmentId)
          .collection('imageMetadata')
          .doc(imageId)
          .set({'description': description}, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update image metadata: $e');
    }
  }

  Future<void> updateImage({
    required String establishmentId,
    required String imageId,
    required File newImageFile,
  }) async {
    try {
      final fileName = '$imageId${path.extension(newImageFile.path)}';
      final ref = _storage.ref().child(
        'establishments/$establishmentId/gallery/$fileName',
      );

      final uploadTask = ref.putFile(
        newImageFile,
        SettableMetadata(
          contentType:
              'image/${path.extension(newImageFile.path).replaceAll('.', '')}',
        ),
      );

      await uploadTask;
    } catch (e) {
      throw Exception('Failed to update image: $e');
    }
  }

  Future<void> deleteImage({
    required String establishmentId,
    required String imageId,
  }) async {
    try {
      final ref = _storage.ref().child(
        'establishments/$establishmentId/gallery/$imageId',
      );
      await ref.delete();

      // Supprimer aussi les métadonnées associées si nécessaire
      await _firestore
          .collection('establishments')
          .doc(establishmentId)
          .collection('imageMetadata')
          .doc(imageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Nouvelle méthode pour supprimer une image via son URL
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      // Si vous devez également supprimer les métadonnées, vous devrez extraire establishmentId et imageId
      // String path = ref.fullPath;
      // Extraire establishmentId et imageId à partir du chemin si nécessaire
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
