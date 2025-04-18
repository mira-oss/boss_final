import 'package:flutter/material.dart';

class Onboarding1 extends StatefulWidget {
  const Onboarding1({super.key});

  @override
  State<Onboarding1> createState() => _Onboarding1State();
}

class _Onboarding1State extends State<Onboarding1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // ↔️ Zoom in / out en boucle

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // 🧹 Nettoyage
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ✅ Image principale + texte
            Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Image.asset(
                    'assets/images/amazone.jpeg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Trouver des lieux extraordinaires pour votre détente partout au Bénin",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ✅ Dots bleus
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 30,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Color(0xFF2196F3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ✅ Bouton "Skip"
            Positioned(
              bottom: 20,
              left: 24,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ),

            // ✅ Bouton "Suivant" animé
            Positioned(
              bottom: 20,
              right: 24,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/onboarding2');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2196F3),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}