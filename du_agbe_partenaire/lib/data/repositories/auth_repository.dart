// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthRepository {
  final FirebaseService _firebaseService;

  AuthRepository(this._firebaseService);

  // Obtenir l'utilisateur actuellement connecté
  User? get currentUser => _firebaseService.auth.currentUser;

  // Stream pour surveiller les changements d'état d'authentification
  Stream<User?> get authStateChanges =>
      _firebaseService.auth.authStateChanges();

  // Connexion avec email et mot de passe
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _firebaseService.auth.signOut();
  }

  // Récupération de mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseService.auth.sendPasswordResetEmail(email: email);
  }

  // Récupérer les données utilisateur depuis Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      final docSnapshot = await _firebaseService.users.doc(userId).get();
      if (docSnapshot.exists) {
        return UserModel.fromJson(docSnapshot.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour la date de dernière connexion
  Future<void> updateLastLoginTime(String userId) async {
    await _firebaseService.users.doc(userId).update({
      'lastLoginAt': DateTime.now(),
    });
  }
}
