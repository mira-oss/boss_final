import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'paiement.dart'; // Assurez-vous que ce chemin est correct

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Firebase
  await Firebase.initializeApp();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Application de Paiement',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PaymentScreen(),
    ),
  );
}