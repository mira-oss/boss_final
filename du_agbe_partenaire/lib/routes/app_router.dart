// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:patenaire/presentation/screens/auth/login_screen.dart';
import 'package:patenaire/presentation/screens/auth/password_recovery_screen.dart';
import 'package:patenaire/presentation/screens/auth/auth_wrapper.dart';
import 'package:patenaire/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:patenaire/presentation/screens/establishment/establishment_details_screen.dart';
import 'package:patenaire/presentation/screens/products/products_list_screen.dart';
import 'package:patenaire/presentation/screens/products/product_form_screen.dart';
import 'package:patenaire/presentation/screens/gallery/gallery_screen.dart';
import 'package:patenaire/presentation/screens/orders/orders_screen.dart';
import 'package:patenaire/presentation/screens/orders/order_details_screen.dart';
import 'package:patenaire/presentation/screens/statistics/statistics_screen.dart';
import 'package:patenaire/presentation/screens/reviews/reviews_list_screen.dart';
// Résoudre le problème d'import ambigü en utilisant un préfixe
import 'package:patenaire/presentation/screens/establishment/contact_info_screen.dart'
    as contact;
import 'package:patenaire/presentation/screens/establishment/opening_hours_screen.dart';

class AppRouter {
  static const String initialRoute = '/auth';

  // Routes nommées
  static const String auth = '/auth';
  static const String login = '/login';
  static const String passwordRecovery = '/password-recovery';
  static const String dashboard = '/dashboard';
  static const String establishmentDetails = '/establishment-details';
  static const String productsList = '/products-list';
  static const String productForm = '/product-form';
  static const String gallery = '/gallery';
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';
  static const String statistics = '/statistics';
  static const String reviews = '/reviews';
  static const String contactInfo = '/contact-info';
  static const String openingHours = '/opening-hours';
  static const String categorySelection = '/category-selection';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case auth:
        return MaterialPageRoute(builder: (_) => AuthWrapper());
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case passwordRecovery:
        return MaterialPageRoute(builder: (_) => PasswordRecoveryScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      case establishmentDetails:
        return MaterialPageRoute(builder: (_) => EstablishmentDetailsScreen());
      case productsList:
        return MaterialPageRoute(builder: (_) => ProductsListScreen());
      case productForm:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProductFormScreen(productId: args?['productId']),
        );
      case gallery:
        // Passer l'ID d'établissement en tant qu'argument
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (_) => GalleryScreen(establishmentId: args['establishmentId']),
        );
      case orders:
        return MaterialPageRoute(builder: (_) => OrdersScreen());
      case orderDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: args['orderId']),
        );
      case statistics:
        return MaterialPageRoute(builder: (_) => StatisticsScreen());
      case contactInfo:
        // Utiliser le préfixe pour spécifier la bonne classe
        return MaterialPageRoute(builder: (_) => contact.ContactInfoScreen());
      case openingHours:
        return MaterialPageRoute(builder: (_) => OpeningHoursScreen());
      case categorySelection:
        // Créer un widget temporaire pour cette route
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                appBar: AppBar(title: Text('Sélection de catégorie')),
                body: Center(
                  child: Text('Écran de sélection de catégorie à implémenter'),
                ),
              ),
        );
      case reviews:
        return MaterialPageRoute(builder: (_) => ReviewsListScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(child: Text('Route inconnue: ${settings.name}')),
              ),
        );
    }
  }
}
