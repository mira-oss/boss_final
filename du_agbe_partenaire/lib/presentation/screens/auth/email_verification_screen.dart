// lib/presentation/screens/auth/email_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/presentation/state/auth_provider.dart';
import 'package:patenaire/presentation/common_widgets/custom_button.dart';
import 'package:patenaire/routes/app_router.dart';

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isEmailVerified = false;
  bool _canResendEmail = true;
  Timer? _timer;
  int _countDown = 60;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Vérifier l'état de vérification initial
    await authProvider.checkEmailVerification();
    setState(() {
      _isEmailVerified = authProvider.isEmailVerified;
    });

    // Si l'email n'est pas encore vérifié, démarrer la vérification périodique
    if (!_isEmailVerified) {
      _timer = Timer.periodic(Duration(seconds: 3), (_) async {
        await authProvider.checkEmailVerification();
        setState(() {
          _isEmailVerified = authProvider.isEmailVerified;
        });

        if (_isEmailVerified) {
          _timer?.cancel();
          Navigator.pushReplacementNamed(context, AppRouter.dashboard);
        }
      });
    }
  }

  void _resendVerificationEmail() {
    if (!_canResendEmail) return;

    setState(() {
      _canResendEmail = false;
      _countDown = 60;
    });

    // Démarrer le compte à rebours
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_countDown > 0) {
          _countDown--;
        } else {
          _canResendEmail = true;
          timer.cancel();
        }
      });
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider
        .sendEmailVerification()
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email de vérification envoyé'),
              backgroundColor: ColorConstants.successColor,
            ),
          );
        })
        .catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'envoi: ${e.toString()}'),
              backgroundColor: ColorConstants.errorColor,
            ),
          );
          setState(() => _canResendEmail = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final email = user?.email ?? 'votre email';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Vérification de l\'email',
          style: TextStyle(
            color: ColorConstants.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await authProvider.signOut();
              Navigator.pushReplacementNamed(context, AppRouter.login);
            },
            child: Text(
              'Déconnexion',
              style: TextStyle(color: ColorConstants.accentColor),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_read,
                size: 100,
                color: ColorConstants.primaryColor,
              ),
              SizedBox(height: 32),
              Text(
                'Vérifiez votre email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Nous avons envoyé un email de vérification à:',
                style: TextStyle(
                  fontSize: 16,
                  color: ColorConstants.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                email,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Veuillez cliquer sur le lien dans l\'email pour vérifier votre compte.',
                style: TextStyle(
                  fontSize: 16,
                  color: ColorConstants.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              CustomButton(
                text:
                    _canResendEmail
                        ? 'Renvoyer l\'email de vérification'
                        : 'Renvoyer dans $_countDown secondes',
                onPressed: () {
                  if (_canResendEmail) {
                    _resendVerificationEmail();
                  }
                },
                backgroundColor:
                    _canResendEmail ? ColorConstants.primaryColor : Colors.grey,
              ),
              SizedBox(height: 16),
              CustomButton(
                text: 'J\'ai vérifié mon email',
                onPressed: () => _checkEmailVerification(),
                isOutlined: true,
              ),
              SizedBox(height: 32),
              Text(
                'Vous n\'avez pas reçu d\'email? Vérifiez votre dossier spam ou réessayez.',
                style: TextStyle(
                  color: ColorConstants.secondaryTextColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
