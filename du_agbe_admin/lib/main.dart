import 'package:du_agbe_admin/creatEvent.dart';
import 'package:du_agbe_admin/inscription.dart';
import 'package:du_agbe_admin/screens/ajout-lieu.dart';
import 'package:du_agbe_admin/screens/home.dart';
import 'package:du_agbe_admin/screens/lieux.dart';
import 'package:du_agbe_admin/screens/onboarding_1.dart';
import 'package:du_agbe_admin/screens/onboarding_2.dart';
import 'package:du_agbe_admin/screens/onboarding_3.dart';
import 'package:du_agbe_admin/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:du_agbe_admin/connexion.dart';
import 'package:du_agbe_admin/listEvent.dart';
import 'package:du_agbe_admin/profil.dart';
import 'package:du_agbe_admin/themeNotifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:du_agbe/theme_notifier.dart'; // Importez le ThemeNotifier
import 'package:provider/provider.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lieux & Events',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding1': (context) => const Onboarding1(),
        '/onboarding2': (context) => const Onboarding2(),
        '/onboarding3': (context) => const Onboarding3(),
        '/login': (context) => const ConnexionPage(),
        '/home': (context) => const HomePage(),
        '/lieux': (context) => const Lieux(),
        '/ajout-lieu':(context) => AjoutLieu(),
        '/register': (context) => const InscriptionPage(),
        '/creatEvent': (context) => const CreateEventScreen(),
      },
    );
  }
}

@override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeNotifier.themeMode,
      home: FutureBuilder(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            // Utilisateur déjà connecté
            return  const HomePage();
          }
          // Utilisateur non connecté
          return  ConnexionPage();
        },
      ),
    );
  }

  class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PageController _pageController;
  int selectedIndex = 0;
  final pages =  [
    EventListScreen(),
    Profil(),
  ];
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);
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
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: _buildCustomNavBar(),
    );
  }

  Widget _buildCustomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SlidingClippedNavBar.colorful(
          backgroundColor: Theme.of(context).colorScheme.surface,
          onButtonPressed: onButtonPressed,
          iconSize: 26,
          selectedIndex: selectedIndex,
          barItems: [
            BarItem(
              icon: Icons.home_rounded,
              title: 'Accueil',
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Colors.grey.shade400,
            ),
            BarItem(
              icon: Icons.person_rounded,
              title: 'Profil',
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}