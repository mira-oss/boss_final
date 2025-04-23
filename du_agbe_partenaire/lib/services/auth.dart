import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChange => _firebaseAuth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // D'abord, vérifier si l'utilisateur existe et doit changer son mot de passe
      final userQuery =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Aucun utilisateur trouvé avec cet email',
        );
      }

      final userDoc = userQuery.docs.first;
      final mustChangePassword = userDoc.get('a_changer_mdp') == false;

      if (mustChangePassword) {
        // Si le mot de passe doit être changé, on ne tente même pas la connexion
        return null;
      }

      // Si tout est ok, procéder à la connexion normale
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print("Erreur de connexion: $e");
      rethrow;
    } catch (e) {
      print("Erreur inattendue: $e");
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Une erreur inattendue est survenue',
      );
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await user.updatePassword(newPassword);
      await _firestore.collection('users').doc(user.uid).update({
        'a_changer_mdp': true,
      });
    } catch (e) {
      print("Erreur lors du changement de mot de passe: $e");
      rethrow;
    }
  }

  Future<void> createUserWithEmailAndPassword(
    String nom,
    String prenom,
    String email,
    String password, {
    String role = 'partenaire',
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'role': role,
        'a_changer_mdp': false,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print("Erreur lors de la création: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<void> sendEmailVerificationLink() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } catch (e) {
      print("Erreur lors de l'envoi du lien de vérification: $e");
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    (String, String) parseDisplayName(String? displayName) {
      if (displayName == null || displayName.trim().isEmpty) {
        return ('', '');
      }

      final nameParts = displayName.trim().split(' ');

      if (nameParts.isEmpty) return ('', '');
      if (nameParts.length == 1) return (nameParts[0], '');

      return (nameParts.first, nameParts.skip(1).join(' '));
    }

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-signin-cancelled',
          message: 'La connexion Google a été annulée',
        );
      }

      final (firstName, lastName) = parseDisplayName(googleUser.displayName);
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (result.additionalUserInfo?.isNewUser == true) {
        await _addGoogleUser(
          result.user!.uid,
          firstName,
          lastName,
          googleUser.email ?? '',
          googleUser.photoUrl ?? '',
        );
      }

      return;
    } catch (e) {
      print('Erreur de connexion Google: $e');
      rethrow;
    }
  }

  Future<void> _addGoogleUser(
    String userID,
    String firstName,
    String lastName,
    String email,
    String avatar, {
    String role = 'proprietaire',
  }) async {
    try {
      await _firestore.collection('users').doc(userID).set({
        'nom': firstName.isNotEmpty ? firstName : 'Non spécifié',
        'prenom': lastName.isNotEmpty ? lastName : 'Non spécifié',
        'email': email.isNotEmpty ? email : 'Non disponible',
        'photo': avatar.isNotEmpty ? avatar : '',
        'role': role,
        'solde': 0.0,
        'a_changer_mdp':
            false, // Les utilisateurs Google doivent aussi changer leur mot de passe
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'utilisateur Google: $e');
      rethrow;
    }
  }
}
