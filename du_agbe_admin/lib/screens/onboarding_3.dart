import 'package:flutter/material.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 📸 Image avec coin arrondi en bas
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Image.asset(
                'assets/images/chute deau.jpeg',
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height * 0.55,
                width: double.infinity,
              ),
            ),

            const SizedBox(height: 20),

            // 📝 Titre & Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
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
                      dot(isActive: false),
                      const SizedBox(width: 6),
                      dot(isActive: true),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 🔵 Bouton Commencer (bleu)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Modification ici: redirection vers la page de connexion
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3), // 🔵 Bleu
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Commencer',
                    style: TextStyle(fontSize: 16, color: Colors.white), // 🤍 Blanc
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 🔘 Widget pour les dots bleus
  Widget dot({required bool isActive}) {
    return Container(
      width: isActive ? 30 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2196F3) : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}