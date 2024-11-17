import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialProvider with ChangeNotifier {
  bool _hasShownTutorial = false;
  bool _isManualTutorial = false;

  bool get hasShownTutorial => _hasShownTutorial;
  bool get isManualTutorial => _isManualTutorial;

  void setManualTutorial(bool value) {
    _isManualTutorial = value;
    notifyListeners();
  }

  Future<void> markTutorialAsShown() async {
    if (!_isManualTutorial) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasShownTutorial', true);
    }
    _hasShownTutorial = true;
    notifyListeners();
  }

  Future<void> checkTutorialStatus() async {
    if (!_isManualTutorial) {
      final prefs = await SharedPreferences.getInstance();
      _hasShownTutorial = prefs.getBool('hasShownTutorial') ?? false;
      notifyListeners();
    }
  }
} 