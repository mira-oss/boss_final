import 'package:flutter/material.dart';

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ✅ Contenu principal
            Column(
              children: [
                // 📸 Image en haut
                Expanded(
                  flex: 6,
                  child: Image.asset(
                    'assets/images/pleine.jpeg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),

                // 📝 Texte et pagination
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Ajouter votre restaurant\npréféré au Bénin",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 🔘 Dots bleus
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            dot(isActive: false),
                            const SizedBox(width: 6),
                            dot(isActive: true),
                            const SizedBox(width: 6),
                            dot(isActive: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ⏩ Skip en bleu
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

            // ⏭ Bouton Suivant en bleu
            Positioned(
              bottom: 20,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/onboarding3');
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
          ],
        ),
      ),
    );
  }

  // ✅ Widget pour les dots bleus
  Widget dot({required bool isActive}) {
    return Container(
      width: isActive ? 30 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Color(0xFF2196F3) : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}