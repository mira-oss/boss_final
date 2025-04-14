import 'package:du_agbe/firebase_options.dart';
import 'package:du_agbe/homePage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
      child: const MyApp(),
    ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Homepage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PageController _pageController;
  int selectedIndex = 0;
  final pages = [
    Homepage(),
   // AdminEventPage()
   Profil()
    ];
  bool _colorful = false;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);
  }

  void onButtonPressed(int index) {
    setState(() {
      selectedIndex = index;
    });
    _pageController.animateToPage(selectedIndex,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOutQuad);
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
            offset: Offset(0, -2),
      )],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          /*activeButtonColor: Theme.of(context).colorScheme.primaryContainer,
          curve: Curves.easeOutExpo,
          animationDuration: Duration(milliseconds: 500),*/
        ),
      ),
    );
  }
}

