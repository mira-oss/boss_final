import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  String _currentLocale = 'fr';

  String get currentLocale => _currentLocale;

  void setLocale(String locale) {
    _currentLocale = locale;
    _saveLocaleToPrefs();
    notifyListeners();
  }

  Future<void> _saveLocaleToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('locale', _currentLocale);
  }
}
