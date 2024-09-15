import 'package:flutter/material.dart';
import 'package:iprsr/models/user.dart';
import 'package:iprsr/services/api_service.dart';

class AuthService extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  Future<void> login(String email, String password) async {
    _user = await ApiService.login(email, password);
    notifyListeners();
  }

  Future<void> register(String email, String password, String username, bool gender, bool hasDisability, String brand, String type, Map<String, bool> preferences) async {
    _user = await ApiService.register(email, password, username, gender, hasDisability, brand, type, preferences);
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
