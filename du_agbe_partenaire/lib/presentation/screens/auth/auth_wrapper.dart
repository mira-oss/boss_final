import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/presentation/state/auth_provider.dart';
import 'package:patenaire/presentation/screens/auth/login_screen.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';
import 'package:patenaire/routes/app_router.dart';

/// AuthWrapper est un widget qui vérifie l'état de l'authentification
/// et redirige l'utilisateur vers l'écran approprié
class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Vérifier l'état de l'authentification au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Pendant la vérification de l'état d'authentification
    if (authProvider.isCheckingStatus) {
      return Scaffold(body: Center(child: LoadingIndicator()));
    }

    // Si l'utilisateur est authentifié, naviguer vers le Dashboard
    if (authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      });
      return Scaffold(body: Center(child: LoadingIndicator()));
    }

    // Si l'utilisateur n'est pas authentifié, afficher l'écran de connexion
    return LoginScreen();
  }
}
