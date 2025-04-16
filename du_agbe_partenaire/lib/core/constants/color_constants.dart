// lib/core/constants/color_constants.dart
import 'package:flutter/material.dart';

class ColorConstants {
  // Couleurs principales
  static const primaryColor = Color(0xFF3F51B5);
  static const primaryColorLight = Color(0xFF5C6BC0);
  static const primaryColorDark = Color(0xFF303F9F);
  static const accentColor = Color(0xFFFF5722);

  // Couleurs de fond
  static const scaffoldBackground = Color(0xFFF5F5F5);
  static const cardBackground = Colors.white;
  static const appBarBackground = Colors.white;

  // Couleurs de texte
  static const primaryTextColor = Color(0xFF212121);
  static const secondaryTextColor = Color(0xFF757575);
  static const appBarTextColor = Color(0xFF212121);
  static const appBarIconColor = Color(0xFF212121);

  // Couleurs d'état
  static const successColor = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFFC107);
  static const errorColor = Color(0xFFF44336);
  static const infoColor = Color(0xFF2196F3);

  // Autres 
  static const Color success = Color(0xFF28A745); // Vert (réussite)
  static const Color error = Color(0xFFDC3545);   // Rouge (erreur)

  // MaterialColor pour le theme
  static const MaterialColor primarySwatch =
      MaterialColor(0xFF3F51B5, <int, Color>{
        50: Color(0xFFE8EAF6),
        100: Color(0xFFC5CAE9),
        200: Color(0xFF9FA8DA),
        300: Color(0xFF7986CB),
        400: Color(0xFF5C6BC0),
        500: Color(0xFF3F51B5),
        600: Color(0xFF3949AB),
        700: Color(0xFF303F9F),
        800: Color(0xFF283593),
        900: Color(0xFF1A237E),
      });
}
