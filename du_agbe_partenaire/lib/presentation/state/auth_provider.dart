// lib/presentation/state/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? _user;
  bool _isLoading = false;
  bool _isCheckingStatus = true;
  bool _isEmailVerified = false;

  AuthProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isEmailVerified = user?.emailVerified ?? false;
      notifyListeners();
    });
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isCheckingStatus => _isCheckingStatus;
  bool get isEmailVerified => _isEmailVerified;

  // Méthodes principales
  Future<void> checkAuthStatus() async {
    _isCheckingStatus = true;
    notifyListeners();

    try {
      _user = _auth.currentUser;
      _isEmailVerified = _user?.emailVerified ?? false;
    } catch (e) {
      print("Erreur de vérification auth: ${e.toString()}");
    } finally {
      _isCheckingStatus = false;
      notifyListeners();
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      _isEmailVerified = _user?.emailVerified ?? false;
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthError(e.code);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserCredential> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      _isEmailVerified = _user?.emailVerified ?? false;
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthError(e.code);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUserProfile({
    required String name,
    required String email,
    String? phone,
    String? photoURL,
    String role = 'partner',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_user != null) {
        // Mise à jour Firestore
        await _firestore.collection('users').doc(_user!.uid).set({
          'uid': _user!.uid,
          'name': name,
          'email': email,
          'phone': phone ?? '',
          'photoURL': photoURL ?? '',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Mise à jour Auth
        await _user!.updateDisplayName(name);
        if (photoURL != null) await _user!.updatePhotoURL(photoURL);
        await _user!.reload();
        _user = _auth.currentUser;
        _isEmailVerified = _user?.emailVerified ?? false;
      }
    } on FirebaseException catch (e) {
      throw _parseFirestoreError(e.code);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      _user = null;
      _isEmailVerified = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthode pour vérifier si l'email est vérifié
  Future<void> checkEmailVerification() async {
    if (_user == null) return;

    try {
      // Recharger l'utilisateur pour obtenir les informations les plus récentes
      await _user!.reload();
      _user = _auth.currentUser;
      _isEmailVerified = _user?.emailVerified ?? false;
      notifyListeners();
    } catch (e) {
      print("Erreur lors de la vérification de l'email: $e");
    }
  }

  // Méthode pour envoyer un email de vérification
  Future<void> sendEmailVerification() async {
    if (_user == null) return;

    try {
      await _user!.sendEmailVerification();
    } catch (e) {
      print("Erreur lors de l'envoi de l'email de vérification: $e");
      throw e;
    }
  }

  // Gestion d'erreurs
  String _parseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte associé à cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Mot de passe trop faible';
      case 'invalid-email':
        return 'Email invalide';
      default:
        return 'Erreur inconnue';
    }
  }

  String _parseFirestoreError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Accès refusé';
      case 'not-found':
        return 'Document introuvable';
      case 'aborted':
        return 'Opération annulée';
      default:
        return 'Erreur Firestore: $code';
    }
  }

  // Autres méthodes existantes...
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Erreur lors de l'envoi de l'email de réinitialisation: $e");
      throw e;
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (_user == null) return;

    try {
      if (displayName != null) {
        await _user!.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await _user!.updatePhotoURL(photoURL);
      }
      await _user!.reload();
      _user = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      print("Erreur lors de la mise à jour du profil: $e");
      throw e;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    if (_user == null) return;

    try {
      await _user!.updatePassword(newPassword);
    } catch (e) {
      print("Erreur lors de la mise à jour du mot de passe: $e");
      throw e;
    }
  }
}
