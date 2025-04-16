import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dio/dio.dart';

import 'config/firebase_options.dart';
import 'core/constants/color_constants.dart';
import 'routes/app_router.dart';

// Services & Repositories
import 'package:patenaire/data/services/firebase_service.dart';
import 'package:patenaire/data/services/storage_service.dart';
import 'package:patenaire/data/repositories/product_repository.dart';
import 'package:patenaire/data/repositories/order_repository.dart';

// Providers (State Management)
import 'presentation/state/auth_provider.dart';
import 'presentation/state/establishment_provider.dart';
import 'presentation/state/product_provider.dart';
import 'presentation/state/order_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugProfileBuildsEnabled = true;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue without Firebase or provide alternate initialization
  }

  // Initialize your services
  final firebaseService = FirebaseService();
  final storageService = StorageService();
  final dio = Dio();

  final productRepository = ProductRepository(firebaseService, storageService);
  final orderRepository = OrderRepository(
    firebaseService,
    dio: dio,
    baseUrl: 'https://your-api-url.com',
  );

  runApp(
    MyApp(
      productRepository: productRepository,
      orderRepository: orderRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ProductRepository productRepository;
  final OrderRepository orderRepository;

  const MyApp({
    Key? key,
    required this.productRepository,
    required this.orderRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        Provider<ProductRepository>.value(value: productRepository),
        Provider<OrderRepository>.value(value: orderRepository),

        // Auth Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Establishment dépend de Auth
        ChangeNotifierProxyProvider<AuthProvider, EstablishmentProvider>(
          create: (_) => EstablishmentProvider(),
          update:
              (_, authProvider, establishmentProvider) =>
                  establishmentProvider!..updateUserId(authProvider.user?.uid),
        ),

        // ProductProvider dépend de Establishment + ProductRepository
        ChangeNotifierProxyProvider2<
          EstablishmentProvider,
          ProductRepository,
          ProductProvider
        >(
          create: (_) => ProductProvider(productRepository),
          update:
              (_, establishmentProvider, productRepository, productProvider) =>
                  productProvider!..setEstablishmentId(
                    establishmentProvider.currentEstablishmentId,
                  ),
        ),

        // OrderProvider dépend de Establishment + OrderRepository
        ChangeNotifierProxyProvider2<
          EstablishmentProvider,
          OrderRepository,
          OrderProvider
        >(
          create: (_) => OrderProvider(orderRepository),
          update:
              (_, establishmentProvider, orderRepository, orderProvider) =>
                  orderProvider!..setEstablishmentId(
                    establishmentProvider.currentEstablishmentId,
                  ),
        ),
      ],
      child: MaterialApp(
        title: 'App Partenaire',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: ColorConstants.primarySwatch,
          scaffoldBackgroundColor: ColorConstants.scaffoldBackground,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: ColorConstants.appBarBackground,
            iconTheme: IconThemeData(color: ColorConstants.appBarIconColor),
            titleTextStyle: TextStyle(
              color: ColorConstants.appBarTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.initialRoute,
      ),
    );
  }
}
