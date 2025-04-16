// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/core/utils/form_validators.dart';
import 'package:patenaire/presentation/state/auth_provider.dart';
import 'package:patenaire/presentation/common_widgets/custom_button.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';
import 'package:patenaire/routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: ${e.toString()}'),
            backgroundColor: Colors.red,
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
      body: SafeArea(
        child:
            authProvider.isLoading
                ? LoadingIndicator()
                : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 60),
                        // Logo and app name
                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 80,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40),
                        // Login form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email field
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
                              SizedBox(height: 16),
                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  prefixIcon: Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: FormValidators.validatePassword,
                              ),
                              SizedBox(height: 16),
                              // Remember me & Forgot password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor:
                                            ColorConstants.primaryColor,
                                      ),
                                      Text('Se souvenir de moi'),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRouter.passwordRecovery,
                                      );
                                    },
                                    child: Text(
                                      'Mot de passe oublié?',
                                      style: TextStyle(
                                        color: ColorConstants.accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              // Login button
                              CustomButton(
                                text: 'Se connecter',
                                onPressed: _submitForm,
                              ),
                              SizedBox(height: 48),
                              // Contact support
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    // Implémentation pour contacter le support
                                  },
                                  child: Text(
                                    'Besoin d\'aide? Contactez le support',
                                    style: TextStyle(
                                      color: ColorConstants.primaryColorDark,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
