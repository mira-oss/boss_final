// lib/data/services/firebase_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/app_constants.dart';
import '../models/product_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getter pour accéder aux instances Firebase
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;
  FirebaseStorage get storage => _storage;

  // Collections Firestore
  CollectionReference get users =>
      _firestore.collection(AppConstants.usersCollection);
  CollectionReference get establishments =>
      _firestore.collection(AppConstants.establishmentsCollection);
  CollectionReference get orders =>
      _firestore.collection(AppConstants.ordersCollection);
  CollectionReference get products =>
      _firestore.collection(AppConstants.productsCollection);
  CollectionReference get reviews =>
      _firestore.collection(AppConstants.reviewsCollection);
  CollectionReference get userEstablishments =>
      _firestore.collection(AppConstants.userEstablishmentsCollection);

  // Sous-collections
  CollectionReference getProductsForEstablishment(String establishmentId) {
    return establishments.doc(establishmentId).collection('products');
  }

  CollectionReference getOrdersForEstablishment(String establishmentId) {
    return establishments.doc(establishmentId).collection('orders');
  }

  CollectionReference getReviewsForEstablishment(String establishmentId) {
    return establishments.doc(establishmentId).collection('reviews');
  }

  // Référence de stockage
  Reference getStorageRef(String path) {
    return _storage.ref().child(path);
  }

  // Référence de stockage pour les images d'un établissement
  Reference getEstablishmentStorageRef(String establishmentId) {
    return getStorageRef('establishments/$establishmentId');
  }

  // Référence de stockage pour les images d'un produit
  Reference getProductStorageRef(String establishmentId, String productId) {
    return getEstablishmentStorageRef(
      establishmentId,
    ).child('products/$productId');
  }

  // Récupérer un produit par son ID
  Future<Product> getProductById(String productId) async {
    final doc = await products.doc(productId).get();

    if (!doc.exists) {
      throw Exception('Produit non trouvé');
    }

    return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // Télécharger une image et obtenir son URL
  Future<String> uploadImage(File imageFile) async {
    final fileName = path.basename(imageFile.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storageRef = _storage.ref().child('products/$timestamp-$fileName');

    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;

    // Retourner l'URL de l'image téléchargée
    return await snapshot.ref.getDownloadURL();
  }

  // Ajouter un produit
  Future<String> addProduct(Product product) async {
    // Créer un nouveau document avec un ID généré automatiquement
    final docRef = products.doc();

    // Mettre à jour l'ID du produit avec l'ID généré
    final productWithId = product.copyWith(id: docRef.id);

    // Enregistrer les données du produit
    await docRef.set(productWithId.toMap());

    // Retourner l'ID du produit ajouté
    return docRef.id;
  }

  // Mettre à jour un produit existant
  Future<void> updateProduct(Product product) async {
    await products.doc(product.id).update(product.toMap());
  }
}
