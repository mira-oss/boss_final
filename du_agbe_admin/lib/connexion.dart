import 'package:du_agbe_admin/inscription.dart';
import 'package:du_agbe_admin/screens/home.dart';
import 'package:du_agbe_admin/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionpageState();
}

class _ConnexionpageState extends State<ConnexionPage> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final passWord = TextEditingController();
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;
  // verification email
  String? validateEmail(String? value) {
    const pattern =
        r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'+/=?^_`{|}~-]+)|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])")@(?:(?:[a-z0-9](?:[a-z0-9-]'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final regex = RegExp(pattern);
    if (value!.isNotEmpty && !regex.hasMatch(value)) {
      return "Entrez un email valide";
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final largeurEcran = MediaQuery.of(context).size.width;

    final hauteurEcran = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: hauteurEcran * 0.02),
            Container(
              width: largeurEcran * 0.9,
              height: hauteurEcran * 0.360,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/er.png'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Text(
              'Content de vous revoir !',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: hauteurEcran * 0.005),
            Text(
              'Connectez-vous pour continuer votre aventure.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: hauteurEcran * 0.03),
            Form(
              key: formKey,
              child: Column(
                spacing: 20,
                children: [
                  TextFormField(
                    controller: email,
                    validator: validateEmail,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      labelText: 'Email',
                      hintText: 'ex : elisha@gmail.com',
                    ),
                  ),
                  TextFormField(
                    controller: passWord,
                    // pour verifier si le champ est bien rempli
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Mot de passe obligatoire";
                      } else if ((passWord.text).length < 6) {
                        return "Le mot de passe doit contenir plus de 6 caractères";
                      } else if (!RegExp(r'[a-zA-Z]').hasMatch(passWord.text)) {
                        return "Le mot de passe doit contenir des lettres";
                      } else if (!RegExp(r'\d').hasMatch(passWord.text)) {
                        return "Le mot de passe doit contenir des nombres";
                      } else if ((passWord.text).contains(' ')) {
                        return "Le mot de passe ne peut contenir d'espace";
                      }
                      return null;
                    },
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: "Mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed:
                            () => setState(() {
                              showPassword = !showPassword;
                            }),
                        icon: Icon(
                          showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: largeurEcran * 0.88,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blue,
                    ),
                    child: TextButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                setState(() {
                                  isLoading = true;
                                });
                                if (formKey.currentState!.validate()) {
                                  // Logique de connexion
                                  try {
                                    Auth().SigninWithEmailAndPassword(
                                      email.text,
                                      passWord.text,
                                    );
                                    setState(() {
                                      isLoading = false;
                                    });
                                  } on FirebaseAuthException catch (e) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    // message d'erreur
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("${e.message}"),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Color(0xffE9494F),
                                        showCloseIcon: true,
                                      ),
                                    );
                                  }
                                  // naviguer vers la page home
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const ConnexionPage(),
                                    ),
                                  );
                                }
                              },
                      child:
                          isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                                "Se connecter",
                                style: TextStyle(
                                  fontSize: largeurEcran * 0.04,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: hauteurEcran * 0.015),
            Row(
              children: [
                SizedBox(width: largeurEcran * 0.53),
                Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: hauteurEcran * 0.015),
            Text(
              'Ou se conneecter avec',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            SizedBox(height: hauteurEcran * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      await Auth().signInWithGoogle();

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    } catch (e) {
                      print("voici le probleme $e");
                    }
                  },
                  child: CircleAvatar(
                    backgroundImage: AssetImage('assets/images/google.jpg'),
                    radius: 30,
                  ),
                ),
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/fa.png'),
                  radius: 30,
                ),
              ],
            ),
            SizedBox(height: hauteurEcran * 0.015),

            Row(
              children: [
                SizedBox(width: largeurEcran * 0.2),
                Text('Pas de compte ?'),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InscriptionPage(),
                      ),
                    );
                  },
                  style: ButtonStyle(),
                  child: Text('S\'incrire', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
