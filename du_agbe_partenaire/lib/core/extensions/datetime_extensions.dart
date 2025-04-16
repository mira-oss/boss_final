class ApiConstants {
  // Collections Firebase
  static const String usersCollection = 'users';
  static const String establishmentsCollection = 'establishments';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';
  static const String notificationsCollection = 'notifications';
  static const String statsCollection = 'statistics';
  static const String promotionsCollection = 'promotions';

  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String establishmentImagesPath = 'establishment_images';
  static const String productImagesPath = 'product_images';
  static const String galleryImagesPath = 'gallery_images';

  // Firebase Functions
  static const String createOrderFunction = 'createOrder';
  static const String updateOrderStatusFunction = 'updateOrderStatus';
  static const String generateStatsFunction = 'generateStats';
  static const String sendNotificationFunction = 'sendNotification';

  // Limites et pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Statuts des commandes
  static const String orderStatusPending = 'pending';
  static const String orderStatusAccepted = 'accepted';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';

  // Endpoints pour les APIs externes (si nécessaire)
  static const String mapsApiBaseUrl = 'https://maps.googleapis.com/maps/api';
  static const String geocodingEndpoint = '/geocode/json';
  static const String directionsEndpoint = '/directions/json';

  // Headers d'authentification
  static const String authHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';

  // Paramètres de requête communs
  static const String pageParam = 'page';
  static const String limitParam = 'limit';
  static const String sortByParam = 'sortBy';
  static const String orderByParam = 'orderBy';
  static const String filterParam = 'filter';
  static const String searchParam = 'search';
  static const String fromDateParam = 'fromDate';
  static const String toDateParam = 'toDate';
}
