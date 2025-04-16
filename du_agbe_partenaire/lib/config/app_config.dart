class AppConfig {
  static const String appName = "App Partenaire";
  static const String appVersion = "1.0.0";

  // Mode d'environnement (dev, staging, prod)
  static const String environment = "dev";

  // Configuration des timeouts
  static const int connectionTimeout = 30000; // 30 secondes
  static const int receiveTimeout = 30000; // 30 secondes

  // Limites
  static const int maxImageUploadSize = 5 * 1024 * 1024; // 5MB
  static const int maxProductsPerPage = 20;
  static const int maxOrdersPerPage = 15;

  // Configuration de cache
  static const bool enableOfflineCache = true;
  static const int cacheDuration = 24 * 60 * 60 * 1000; // 24 heures

  // URL de base pour les termes et conditions, politique de confidentialité, etc.
  static const String termsUrl = "https://votreappli.com/terms";
  static const String privacyPolicyUrl = "https://votreappli.com/privacy";
  static const String supportUrl = "https://votreappli.com/support";

  // Gestion des notifications
  static const bool enablePushNotifications = true;
  static const String notificationChannelId = "partner_notifications";
  static const String notificationChannelName = "Notifications Partenaire";
  static const String notificationChannelDesc =
      "Notifications pour les partenaires";
}
