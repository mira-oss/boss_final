import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';
// Import des pages
import 'dashboard.dart';
import 'Modifier_Fiche.dart';
import 'suivie_commande.dart';
import 'statistiques.dart';
import 'gestion_visuel.dart';
import 'Avis_interactions.dart';
import 'profil.dart';
import 'Auth/Oneboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugProfileBuildsEnabled = true;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1565C0),
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final currentLocale = prefs.getString('locale') ?? 'fr';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDarkMode)),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..setLocale(currentLocale),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Partenaire',
      theme: ThemeData(
        primaryColor: const Color(0xFF1565C0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          primary: const Color(0xFF1565C0),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF1565C0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          primary: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(localeProvider.currentLocale),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ), // Redirection vers Onboarding
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.store, size: 100, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Partenaire',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 50),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  bool _colorful = false;
  late PageController _pageController;

  final String _partnerId = "partner_123";

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);

    _pages = [
      const DashboardPage(),
      ModifierFichePage(partenaireId: _partnerId),
      OrdersTrackingPage(),
      const StatisticsPage(),
      VisualsManagementPage(partnerId: _partnerId),
      ReviewsPage(),
      const ProfileSettingsPage(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onButtonPressed(int index) {
    setState(() {
      selectedIndex = index;
    });
    _pageController.animateToPage(
      selectedIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuad,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: _pages,
      ),
      bottomNavigationBar:
          _colorful
              ? SlidingClippedNavBar.colorful(
                backgroundColor:
                    isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                onButtonPressed: onButtonPressed,
                iconSize: 30,
                selectedIndex: selectedIndex,
                barItems: <BarItem>[
                  BarItem(
                    icon: Icons.dashboard,
                    title: 'Tableau de bord',
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey,
                  ),
                  BarItem(
                    icon: Icons.store,
                    title: 'Établissement',
                    activeColor: Colors.green,
                    inactiveColor: Colors.grey,
                  ),
                  BarItem(
                    icon: Icons.bar_chart,
                    title: 'Statistiques',
                    activeColor: Colors.purple,
                    inactiveColor: Colors.grey,
                  ),
                  BarItem(
                    icon: Icons.image,
                    title: 'Visuels',
                    activeColor: Colors.red,
                    inactiveColor: Colors.grey,
                  ),
                ],
              )
              : SlidingClippedNavBar(
                backgroundColor:
                    isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                onButtonPressed: onButtonPressed,
                iconSize: 30,
                activeColor: const Color(0xFF1565C0),
                selectedIndex: selectedIndex,
                barItems: <BarItem>[
                  BarItem(icon: Icons.dashboard, title: 'Tableau de bord'),
                  BarItem(icon: Icons.store, title: 'Établissement'),
                  BarItem(icon: Icons.bar_chart, title: 'Statistiques'),
                  BarItem(icon: Icons.image, title: 'Visuels'),
                ],
              ),
    );
  }
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;

  ThemeProvider(this._isDarkMode);

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class LocaleProvider with ChangeNotifier {
  String _currentLocale = 'fr';

  String get currentLocale => _currentLocale;

  void setLocale(String locale) {
    _currentLocale = locale;
    notifyListeners();
  }
}
