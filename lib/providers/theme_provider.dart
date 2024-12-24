import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add SharedPreferences

class ThemeProvider extends ChangeNotifier {
  ThemeType _currentTheme = ThemeType.light;
  SharedPreferences? _prefs; // Global SharedPreferences instance

  ThemeType get currentTheme => _currentTheme;

  void setTheme(ThemeType theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  bool _useGradient = true;
  bool get useGradient => _useGradient;

  void toggleGradient() {
    _useGradient = !_useGradient;
    notifyListeners();
  }

  // Initialize SharedPreferences
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await restoreTheme(); // Restore theme when initializing
  }

  // Restore theme from SharedPreferences
  Future<void> restoreTheme() async {
    if (_prefs != null) {
      final savedTheme = _prefs!.getString('theme');
      if (savedTheme != null) {
        _currentTheme = savedTheme == 'light' ? ThemeType.light : ThemeType.dark;
        notifyListeners();
      }
    }
  }

  // Save theme to SharedPreferences
  Future<void> saveTheme() async {
    if (_prefs != null) {
      await _prefs!.setString('theme', _currentTheme.toString().split('.').last);
    }
  }
}

enum ThemeType { light, dark }