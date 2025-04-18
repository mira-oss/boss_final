import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // ↔️ animation qui pulse

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // 🧹 libérer le controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ Image de fond
          SizedBox.expand(
            child: Image.asset(
              'assets/images/splash.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Overlay foncé léger
          Container(
            color: Colors.black.withOpacity(0.2),
          ),

          // ✅ Contenu centré
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "LET’S GO TO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    "BENIN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Du Agbe",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Bouton animé
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: _animation,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    backgroundColor: const Color(0xFF2196F3), // 💙 Bleu
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/onboarding1');
                  },
                  child: const Text(
                    'Commencer',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}