import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/core/utils/form_validators.dart';
import 'package:patenaire/presentation/state/auth_provider.dart';
import 'package:patenaire/presentation/common_widgets/custom_button.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';
import 'package:patenaire/routes/app_router.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  @override
  _PasswordRecoveryScreenState createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        await authProvider.sendPasswordResetEmail(_emailController.text.trim());
        setState(() {
          _emailSent = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstants.primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Récupération de mot de passe',
          style: TextStyle(
            color: ColorConstants.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child:
            authProvider.isLoading
                ? LoadingIndicator()
                : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child:
                        _emailSent
                            ? _buildSuccessContent()
                            : _buildFormContent(),
                  ),
                ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 20),
        Icon(Icons.lock_reset, size: 80, color: ColorConstants.primaryColor),
        SizedBox(height: 24),
        Text(
          'Mot de passe oublié?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ColorConstants.primaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Entrez votre adresse e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
          style: TextStyle(
            fontSize: 16,
            color: ColorConstants.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 40),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: FormValidators.validateEmail,
              ),
              SizedBox(height: 24),
              CustomButton(
                text: 'Envoyer le lien de réinitialisation',
                onPressed: _submitForm,
                icon: Icons.send,
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Retour à la page de connexion',
                  style: TextStyle(
                    color: ColorConstants.accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 40),
        Icon(
          Icons.check_circle_outline,
          size: 100,
          color: ColorConstants.successColor,
        ),
        SizedBox(height: 30),
        Text(
          'Email envoyé!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ColorConstants.primaryTextColor,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Nous avons envoyé un lien de réinitialisation à:',
          style: TextStyle(
            fontSize: 16,
            color: ColorConstants.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          _emailController.text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: ColorConstants.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30),
        Text(
          'Veuillez vérifier votre boîte de réception et suivre les instructions pour réinitialiser votre mot de passe.',
          style: TextStyle(
            fontSize: 16,
            color: ColorConstants.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 50),
        CustomButton(
          text: 'Retourner à la connexion',
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRouter.login);
          },
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            'Essayer avec une autre adresse email',
            style: TextStyle(color: ColorConstants.accentColor),
          ),
        ),
      ],
    );
  }
}
