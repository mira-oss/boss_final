// lib/presentation/state/establishment_provider.dart
import 'package:flutter/foundation.dart';
import 'package:patenaire/data/models/establishment_model.dart';
import 'package:patenaire/data/services/firebase_service.dart';

class EstablishmentProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  String? _userId;
  Establishment? _establishment;
  Establishment? _currentEstablishment;
  bool _isLoading = false;
  String? _error;

  // Getters
  Establishment? get establishment => _establishment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentEstablishmentId => _establishment?.id;
  Establishment? get currentEstablishment => _currentEstablishment;

  // Méthode pour définir l'établissement courant manuellement
  void setCurrentEstablishment(Establishment establishment) {
    _currentEstablishment = establishment;
    notifyListeners();
  }

  // Méthode pour mettre à jour l'userId
  void updateUserId(String? userId) {
    _userId = userId;
    if (userId != null) {
      fetchEstablishmentDetails();
    }
  }

  bool hasNewReviews() {
    return false; // À personnaliser selon votre logique
  }

  Future<void> fetchEstablishmentDetails() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_userId == null) {
        throw Exception("Utilisateur non connecté");
      }

      final documentSnapshot =
          await _firebaseService.firestore
              .collection('establishments')
              .where('ownerId', isEqualTo: _userId)
              .limit(1)
              .get();

      if (documentSnapshot.docs.isEmpty) {
        throw Exception("Établissement non trouvé");
      }

      final data = documentSnapshot.docs.first.data();
      data['id'] = documentSnapshot.docs.first.id;

      _establishment = Establishment.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEstablishmentStatus(bool isOpen) async {
    if (_establishment == null) return;

    try {
      _establishment = _establishment!.copyWith(isOpen: isOpen);
      notifyListeners();

      await _firebaseService.firestore
          .collection('establishments')
          .doc(_establishment!.id)
          .update({'isOpen': isOpen});
    } catch (e) {
      _establishment = _establishment!.copyWith(isOpen: !isOpen);
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateEstablishmentDetails({
    String? name,
    String? address,
    String? description,
    Map<String, dynamic>? openingHours,
    String? category,
    String? phone,
    String? email,
  }) async {
    if (_establishment == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedData = {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (description != null) 'description': description,
        if (openingHours != null) 'openingHours': openingHours,
        if (category != null) 'category': category,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      };

      await _firebaseService.firestore
          .collection('establishments')
          .doc(_establishment!.id)
          .update(updatedData);

      _establishment = _establishment!.copyWith(
        name: name ?? _establishment!.name,
        address: address ?? _establishment!.address,
        description: description ?? _establishment!.description,
        openingHours: openingHours ?? _establishment!.openingHours,
        category: category ?? _establishment!.category,
        phone: phone ?? _establishment!.phone,
        email: email ?? _establishment!.email,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPhoto(String photoUrl) async {
    if (_establishment == null) return;

    try {
      final updatedPhotoUrls = List<String>.from(_establishment!.photoUrls)
        ..add(photoUrl);

      await _firebaseService.firestore
          .collection('establishments')
          .doc(_establishment!.id)
          .update({'photoUrls': updatedPhotoUrls});

      _establishment = _establishment!.copyWith(photoUrls: updatedPhotoUrls);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removePhoto(String photoUrl) async {
    if (_establishment == null) return;

    try {
      final updatedPhotoUrls = List<String>.from(_establishment!.photoUrls)
        ..remove(photoUrl);

      await _firebaseService.firestore
          .collection('establishments')
          .doc(_establishment!.id)
          .update({'photoUrls': updatedPhotoUrls});

      _establishment = _establishment!.copyWith(photoUrls: updatedPhotoUrls);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Ajout : Obtenir les détails de l'établissement
  Future<Establishment> getEstablishmentDetails() async {
    if (_establishment == null) {
      await fetchEstablishmentDetails();
    }

    if (_establishment == null) {
      throw Exception("Impossible de récupérer les détails de l'établissement");
    }

    return _establishment!;
  }

  // Ajout : Mettre à jour les informations de contact
  Future<void> updateContactInfo({
    String? phone,
    String? email,
    String? website,
    String? address,
    String? city,
    String? postalCode,
    String? additionalInfo,
  }) async {
    if (_establishment == null) {
      throw Exception("Aucun établissement à mettre à jour");
    }

    _isLoading = true;
    notifyListeners();

    try {
      final updatedData = {
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (website != null) 'website': website,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (postalCode != null) 'postalCode': postalCode,
        if (additionalInfo != null) 'additionalInfo': additionalInfo,
      };

      await _firebaseService.firestore
          .collection('establishments')
          .doc(_establishment!.id)
          .update(updatedData);

      _establishment = _establishment!.copyWith(
        phone: phone ?? _establishment!.phone,
        email: email ?? _establishment!.email,
        website: website ?? _establishment!.website,
        address: address ?? _establishment!.address,
        city: city ?? _establishment!.city,
        postalCode: postalCode ?? _establishment!.postalCode,
        additionalInfo: additionalInfo ?? _establishment!.additionalInfo,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔥 Ajout : Mettre à jour tout l'établissement
  Future<void> updateEstablishment(Establishment establishment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_userId == null) {
        throw Exception("Utilisateur non connecté");
      }

      final documentRef = _firebaseService.firestore
          .collection('establishments')
          .doc(establishment.id);

      await documentRef.update(establishment.toJson());

      _establishment = establishment;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
