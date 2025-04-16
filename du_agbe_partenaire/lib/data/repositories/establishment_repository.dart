// lib/data/repositories/establishment_repository.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/establishment_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

class EstablishmentRepository {
  final FirebaseService _firebaseService;
  final StorageService _storageService;

  EstablishmentRepository(this._firebaseService, this._storageService);

  // Obtenir un établissement par son ID
  Future<Establishment> getEstablishmentById(String establishmentId) async {
    final docSnapshot =
        await _firebaseService.establishments.doc(establishmentId).get();
    if (docSnapshot.exists) {
      return Establishment.fromJson(docSnapshot.data() as Map<String, dynamic>);
    } else {
      throw Exception('Établissement non trouvé');
    }
  }

  // Obtenir tous les établissements d'un utilisateur
  Stream<List<Establishment>> getEstablishmentsForUser(String userId) {
    return _firebaseService.userEstablishments
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final establishmentIds =
              snapshot.docs
                  .map((doc) => doc['establishmentId'] as String)
                  .toList();

          if (establishmentIds.isEmpty) {
            return [];
          }

          final establishmentDocs = await Future.wait(
            establishmentIds.map(
              (id) => _firebaseService.establishments.doc(id).get(),
            ),
          );

          return establishmentDocs
              .where((doc) => doc.exists)
              .map(
                (doc) =>
                    Establishment.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  // Mettre à jour les informations d'un établissement
  Future<void> updateEstablishment(Establishment establishment) async {
    await _firebaseService.establishments
        .doc(establishment.id)
        .update(establishment.toJson());
  }

  // Mettre à jour le statut d'ouverture d'un établissement
  Future<void> updateEstablishmentOpenStatus(
    String establishmentId,
    bool isOpen,
  ) async {
    await _firebaseService.establishments.doc(establishmentId).update({
      'isOpen': isOpen,
    });
  }

  // Ajouter une photo à l'établissement
  Future<void> addEstablishmentPhoto(
    String establishmentId,
    File imageFile,
  ) async {
    // Upload de l'image
    final imageUrl = await _storageService.uploadEstablishmentImage(
      establishmentId,
      imageFile,
    );

    // Ajouter l'URL de l'image à la liste des photos
    await _firebaseService.establishments.doc(establishmentId).update({
      'photoUrls': FieldValue.arrayUnion([imageUrl]),
    });
  }

  // Supprimer une photo de l'établissement
  Future<void> deleteEstablishmentPhoto(
    String establishmentId,
    String imageUrl,
  ) async {
    // Supprimer l'image du stockage
    await _storageService.deleteEstablishmentImage(imageUrl);

    // Supprimer l'URL de l'image de la liste des photos
    await _firebaseService.establishments.doc(establishmentId).update({
      'photoUrls': FieldValue.arrayRemove([imageUrl]),
    });
  }

  // Mettre à jour les horaires d'ouverture
  Future<void> updateOpeningHours(
    String establishmentId,
    Map<String, dynamic> openingHours,
  ) async {
    await _firebaseService.establishments.doc(establishmentId).update({
      'openingHours': openingHours,
    });
  }

  // Mettre à jour les coordonnées de contact
  Future<void> updateContactInfo(
    String establishmentId,
    String phone,
    String email,
  ) async {
    await _firebaseService.establishments.doc(establishmentId).update({
      'phone': phone,
      'email': email,
    });
  }

  // Mettre à jour la catégorie de l'établissement
  Future<void> updateCategory(String establishmentId, String category) async {
    await _firebaseService.establishments.doc(establishmentId).update({
      'category': category,
    });
  }
}
