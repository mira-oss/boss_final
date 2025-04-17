import 'package:du_agbe/map.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  await Firebase.initializeApp();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Application de Paiement',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Stepdumaps(),
    ),
  );
}