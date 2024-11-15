import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeType _currentTheme = ThemeType.light;
  
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
}

enum ThemeType { light, dark } 