
import 'package:du_agbe_admin/connexion.dart';
import 'package:du_agbe_admin/main.dart';
import 'package:du_agbe_admin/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final formKey = GlobalKey<FormState>();
  final nom = TextEditingController();
  final prenom = TextEditingController();
  final email = TextEditingController();
  final passWord = TextEditingController();
  final confirmPassword = TextEditingController();
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  String? validateEmail(String? value) {
    const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'+/=?^_`{|}~-]+)|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])")@(?:(?:[a-z0-9](?:[a-z0-9-]'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final regex = RegExp(pattern);
    if (value!.isNotEmpty && !regex.hasMatch(value)) {
      return "Entrez un email valide";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final largeurEcran = MediaQuery.of(context).size.width;
    final hauteurEcran = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: hauteurEcran*0.02),
            Container(
              width: largeurEcran * 0.9,
              height: hauteurEcran * 0.4,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/joie.png'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(height: hauteurEcran * 0.005),
            Text(
              'Bienvenue sur Du Agbé',
              style: TextStyle(
                fontSize: 23, 
                fontWeight: FontWeight.bold, 
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: hauteurEcran * 0.005),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nom,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Votre nom est obligatoire";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                      labelText: 'Nom',
                      prefixIcon: const Icon(Icons.person_3_outlined),
                      hintText: 'Ex : ELISHA',
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: prenom,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Votre prénom est obligatoire";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person_3_outlined),
                      labelText: 'Prénom',
                      hintText: 'Ex : Richard Donatien',
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: email,
                   // validator: validateEmail,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.email_outlined),
                      labelText: 'Email',
                      hintText: 'ex : elisha@gmail.com',
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: passWord,
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
                        borderRadius: BorderRadius.circular(12)),
                      hintText: "Mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() {
                          showPassword = !showPassword;
                        }),
                        icon: Icon(showPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: confirmPassword,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Confirmer votre mot de passe";
                      } else if (passWord.text != confirmPassword.text) {
                        return "Les mots de passe ne correspondent pas";
                      }
                      return null;
                    },
                    obscureText: !showConfirmPassword,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                      hintText: "Confirmez le mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() {
                          showConfirmPassword = !showConfirmPassword;
                        }),
                        icon: Icon(showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: largeurEcran * 0.88,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blue,
                    ),
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setState(() {
                                  isLoading = true;
                                });
                                try {
                                  await Auth().createUserWithEmailAndPassword(
                                    nom.text,
                                    prenom.text,
                                    email.text,
                                    passWord.text,
                                  );
                                  
                                  // Redirection vers MyHomePage après inscription réussie
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MyHomePage(),
                                    ),
                                  );
                                } on FirebaseAuthException catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("${e.message}"),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Color(0xffE9494F),
                                      showCloseIcon: true,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "S'inscrire",
                              style: TextStyle(
                                fontSize: largeurEcran * 0.04,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Vous êtes utilisateur?"),
                      TextButton(
                        child: Text("Se connecter"),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConnexionPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
