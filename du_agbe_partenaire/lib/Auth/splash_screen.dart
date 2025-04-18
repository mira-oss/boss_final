import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Configuration des animations
    _animationController = AnimationController(
      duration: const Duration(
        seconds: 3,
      ), // Réduit à 3 secondes pour une meilleure UX
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Démarrer l'animation
    _animationController.forward();

    // Naviguer vers la page d'onboarding après l'animation
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageUrl =
        'https://tse4.mm.bing.net/th?id=OIP.eCK0hSa_yle7GPGkMDvexwAAAA&pid=Api&P=0&h=180'; // Remplacez par l'URL de votre logo

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animation du logo avec image en ligne
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: SizedBox(
                          width: size.width * 0.6, // Taille augmentée
                          height: size.width * 0.6,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.white.withOpacity(0.1),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Icon(
                                  Icons.error_outline,
                                  size: 50,
                                  color: Colors.white,
                                ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Texte de l'application avec animation de fade
              AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          'RestauManager',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Gérez votre restaurant en toute simplicité',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
