// lib/core/constants/app_constants.dart
class AppConstants {
  // Généralités
  static const String appName = 'App Partenaire';
  static const String appVersion = '1.0.0';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String establishmentsCollection = 'establishments';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';
static const String userEstablishmentsCollection = 'userEstablishments';

  // Statuts de commande
  static const String orderStatusPending = 'pending';
  static const String orderStatusAccepted = 'accepted';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';

  // Limites
  static const int maxGalleryPhotos = 20;
  static const int maxProductPhotos = 5;

  // Pagination
  static const int defaultPageSize = 10;
}
