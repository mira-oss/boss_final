import 'package:du_agbe_pro/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Auth/login.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Gestion simplifiée',
      description:
          'Gérez votre établissement plus facilement avec nos outils intuitifs.',
      imageUrl:
          'https://tse2.mm.bing.net/th?id=OIP.miikC3JHrLhxag8rhyBXqwHaHa&pid=Api&P=0&h=180',
      icon: Icons.restaurant_menu,
      color: Colors.blue.shade800,
    ),
    OnboardingItem(
      title: 'Suivi en temps réel',
      description:
          'Suivez votre activité en temps réel et prenez des décisions informées.',
      imageUrl:
          'https://tse1.mm.bing.net/th?id=OIP.jqJmRpMaDr8FnwDLsE9efAHaHa&pid=Api&P=0&h=180',
      icon: Icons.insights,
      color: Colors.green.shade700,
    ),
    OnboardingItem(
      title: 'Collaboration d\'équipe',
      description:
          'Facilitez la communication entre les membres de votre équipe.',
      imageUrl:
          'https://tse4.mm.bing.net/th?id=OIP._15F1G6pZ_m9EwGhi5oL_wHaFj&pid=Api&P=0&h=180',
      icon: Icons.people,
      color: Colors.orange.shade800,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Sauvegarde dans les préférences que l'onboarding est terminé
  void _markOnboardingComplete() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
  }

  // Méthode pour naviguer vers la page de connexion
  void _goToLogin() {
    _markOnboardingComplete();
    // Assure une transition de remplacement pour éviter de revenir à l'onboarding
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardPage()),
    );
  }

  // Méthode pour passer à la page suivante ou aller au login si c'est la dernière
  void _nextPage() {
    if (_currentPage < _onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                child: TextButton(
                  onPressed:
                      _goToLogin, // Appelle _goToLogin lorsque "Passer" est cliqué
                  child: const Text(
                    'Passer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingItems.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingItems[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicateurs de page
                  Row(
                    children: List.generate(
                      _onboardingItems.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 10,
                        width: _currentPage == index ? 30 : 10,
                        decoration: BoxDecoration(
                          color:
                              _currentPage == index
                                  ? _onboardingItems[_currentPage].color
                                  : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),

                  // Bouton de navigation - "Suivant" ou "Commencer"
                  ElevatedButton(
                    onPressed:
                        _nextPage, // Appelle _nextPage qui va au login à la fin
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _onboardingItems[_currentPage].color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentPage == _onboardingItems.length - 1
                          ? 'Commencer' // Sur la dernière page
                          : 'Suivant', // Sur les pages intermédiaires
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône de la page
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 60, color: item.color),
          ),
          const SizedBox(height: 40),

          // Image en ligne
          CachedNetworkImage(
            imageUrl: item.imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade200,
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 100,
                      color: item.color.withOpacity(0.5),
                    ),
                  ),
                ),
            errorWidget:
                (context, url, error) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade200,
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 100,
                      color: item.color.withOpacity(0.5),
                    ),
                  ),
                ),
            imageBuilder:
                (context, imageProvider) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          ),

          const SizedBox(height: 40),

          // Titre et description
          Text(
            item.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String imageUrl;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.icon,
    required this.color,
  });
}
