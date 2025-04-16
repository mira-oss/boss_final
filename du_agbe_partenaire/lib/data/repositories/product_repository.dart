import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patenaire/data/models/product_model.dart';
import 'package:patenaire/data/services/firebase_service.dart';
import 'package:patenaire/data/services/storage_service.dart';

class ProductRepository {
  final FirebaseService _firebaseService;
  final StorageService _storageService;

  ProductRepository(this._firebaseService, this._storageService);

  // Version Future pour la méthode getProductsByEstablishment
  Future<List<Product>> getProductsByEstablishment(
    String establishmentId,
  ) async {
    final snapshot =
        await _firebaseService.products
            .where('establishmentId', isEqualTo: establishmentId)
            .orderBy('priority', descending: true)
            .get();

    return snapshot.docs
        .map(
          (doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // Version Stream (conservée pour d'autres usages)
  Stream<List<Product>> watchProductsByEstablishment(String establishmentId) {
    return _firebaseService.products
        .where('establishmentId', isEqualTo: establishmentId)
        .orderBy('priority', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Product.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  Future<Product> getProductById(String productId) async {
    final doc = await _firebaseService.products.doc(productId).get();
    if (!doc.exists) throw Exception('Product not found');
    return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<String> addProduct(Product product, {List<File>? images}) async {
    try {
      // Upload images if provided
      final photoUrls =
          images != null
              ? await _uploadProductImages(
                product.establishmentId,
                product.id,
                images,
              )
              : <String>[];

      // Create product with image URLs
      final productWithImages = product.copyWith(photoUrls: photoUrls);
      final docRef = _firebaseService.products.doc();
      await docRef.set(productWithImages.copyWith(id: docRef.id).toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(Product product, {List<File>? newImages}) async {
    try {
      List<String> updatedPhotoUrls = product.photoUrls;

      // Handle new images
      if (newImages != null && newImages.isNotEmpty) {
        final newUrls = await _uploadProductImages(
          product.establishmentId,
          product.id,
          newImages,
        );
        updatedPhotoUrls = [...product.photoUrls, ...newUrls];
      }

      await _firebaseService.products
          .doc(product.id)
          .update(product.copyWith(photoUrls: updatedPhotoUrls).toMap());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final product = await getProductById(productId);

      // Delete all associated images
      await _deleteProductImages(product.photoUrls);

      // Delete product document
      await _firebaseService.products.doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Helper method for image uploads
  Future<List<String>> _uploadProductImages(
    String establishmentId,
    String productId,
    List<File> images,
  ) async {
    return await Future.wait(
      images.map(
        (file) => _storageService.uploadProductImage(establishmentId, file),
      ),
    );
  }

  // Helper method for image deletion
  Future<void> _deleteProductImages(List<String> imageUrls) async {
    await Future.wait(
      imageUrls.map((url) => _storageService.deleteProductImage(url)),
    );
  }

  // Update availability
  Future<void> updateProductAvailability(
    String productId,
    bool available,
  ) async {
    await _firebaseService.products.doc(productId).update({
      'available': available,
    });
  }

  // Promotion
  Future<void> setProductPromotion(
    String productId,
    Map<String, dynamic> promotion,
  ) async {
    await _firebaseService.products.doc(productId).update({
      'promotion': promotion,
    });
  }

  Future<void> removeProductPromotion(String productId) async {
    await _firebaseService.products.doc(productId).update({
      'promotion': FieldValue.delete(),
    });
  }

  Future<void> deleteProductImage(String productId, String imageUrl) async {
    await _storageService.deleteProductImage(imageUrl);
    await _firebaseService.products.doc(productId).update({
      'photoUrls': FieldValue.arrayRemove([imageUrl]),
    });
  }

  // Méthode pour récupérer les statistiques par catégorie
  Future<List<Map<String, dynamic>>> getCategoryStats({
    required String establishmentId,
    required String period,
  }) async {
    try {
      final DateTime now = DateTime.now();
      DateTime startDate;

      switch (period) {
        case 'semaine':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'mois':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'année':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = DateTime(now.year, now.month - 1, now.day);
      }

      final orders =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('establishmentId', isEqualTo: establishmentId)
              .where('status', isEqualTo: 'completed')
              .where('createdAt', isGreaterThanOrEqualTo: startDate)
              .get();

      Map<String, double> categoryStats = {};

      for (var doc in orders.docs) {
        final orderData = doc.data();
        final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);

        for (var item in items) {
          final category = item['category'] ?? 'Non spécifié';
          final amount = (item['price'] ?? 0.0) * (item['quantity'] ?? 0);

          categoryStats[category] = (categoryStats[category] ?? 0) + amount;
        }
      }

      return categoryStats.entries
          .map((entry) => {'name': entry.key, 'revenue': entry.value})
          .toList()
        ..sort(
          (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
        );
    } catch (e) {
      throw Exception(
        'Erreur lors du calcul des stats par catégorie: ${e.toString()}',
      );
    }
  }
}
