import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add SharedPreferences
import 'package:iprsr/models/user.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/providers/tutorial_provider.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  SharedPreferences? _prefs; // SharedPreferences instance

  // Getter to access the authenticated user
  User? get user => _user;

  // Check if the user is logged in
  bool get isLoggedIn => _user != null;

  // Initialize SharedPreferences
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await restoreLoginStatus(); // Restore login status when the app starts
  }

  // Restore login status from SharedPreferences
  Future<void> restoreLoginStatus() async {
  if (_prefs != null) {
    final userID = _prefs!.getString('userID');
    if (userID != null) {
      print('Restoring login status for userID: $userID'); // Debugging
      try {
        Map<String, dynamic>? fetchedData = await ApiService.fetchUserDetails(userID);
        if (fetchedData != null) {
          _user = User.fromJson(fetchedData);
          print('User details restored: ${_user!.username}'); // Debugging
          notifyListeners();
        } else {
          print('Failed to fetch user details for userID: $userID'); // Debugging
        }
      } catch (error) {
        print("Error restoring login status: $error"); // Debugging
      }
    } else {
      print('No userID found in SharedPreferences'); // Debugging
    }
  }
}

  // Login function to authenticate and set the user
  Future<void> login(String email, String password) async {
    try {
      User? loggedInUser = await ApiService.login(email, password);
      if (loggedInUser != null) {
        _user = loggedInUser;
        await saveLoginStatus(loggedInUser.userID); // Save login status
        notifyListeners();
      } else {
        throw Exception("Failed to log in. Please check your credentials.");
      }
    } catch (error) {
      print("Login error: $error");
      rethrow; // Allow the error to propagate
    }
  }

  // Save login status to SharedPreferences
  Future<void> saveLoginStatus(String userID) async {
    if (_prefs != null) {
      await _prefs!.setString('userID', userID);
    }
  }

  // Register function to create a new user and set the user
  Future<void> register(
    String email,
    String password,
    String phoneNo,
    String username,
    bool gender,
    bool hasDisability,
    String brand,
    String type,
    String category,
    Map<String, bool> preferences,
  ) async {
    try {
      User? registeredUser = await ApiService.register(
        email,
        password,
        phoneNo,
        username,
        gender,
        hasDisability,
        brand,
        type,
        category,
        preferences,
      );
      if (registeredUser != null) {
        _user = registeredUser;
        await saveLoginStatus(registeredUser.userID); // Save login status
        notifyListeners();
      } else {
        throw Exception("Registration failed. Please check your inputs.");
      }
    } catch (error) {
      print("Registration error: $error");
      rethrow;
    }
  }

  // Update user details like vehicle and parking preferences
  Future<void> updateUser({
    required String userID,
    required String vehicleBrand,
    required String vehicleType,
    required Map<String, bool> preferences,
  }) async {
    if (_user != null) {
      try {
        // Create an updated user instance
        User updatedUser = _user!.copyWith(
          brand: vehicleBrand,
          type: vehicleType,
          preferences: preferences,
        );

        // Send the updated user details to the API
        bool success =
            await ApiService.updateVehicleDetailsAndParkingPreferences(
          userID: updatedUser.userID,
          vehicleBrand: updatedUser.brand,
          vehicleType: updatedUser.type,
          vehicleCategory: updatedUser.category,
          preferences: updatedUser.preferences,
        );
        if (success) {
          _user = updatedUser;
          notifyListeners();
        } else {
          throw Exception("Failed to update user details.");
        }
      } catch (error) {
        print("Update error: $error");
        rethrow;
      }
    } else {
      throw Exception("No user logged in.");
    }
  }

  // Fetch user details from the backend (vehicle and preferences)
  Future<void> fetchUserDetails() async {
    if (_user != null) {
      try {
        Map<String, dynamic>? fetchedData =
            await ApiService.fetchVehicleDetailsAndParkingPreferences(
                _user!.userID);
        if (fetchedData != null) {
          _user = _user!.copyWith(
            brand: fetchedData['vehicleDetails']['brand'],
            type: fetchedData['vehicleDetails']['type'],
            preferences:
                Map<String, bool>.from(fetchedData['parkingPreferences']),
          );
          notifyListeners();
        } else {
          throw Exception("Failed to fetch user details.");
        }
      } catch (error) {
        print("Fetch error: $error");
        rethrow;
      }
    } else {
      throw Exception("No user logged in.");
    }
  }

  // Add a method to get the user ID
  String? getUserId() {
    return _user?.userID; // Return the userID if the user is logged in
  }

  // Logout function to clear the user and notify listeners
  void logout() async {
    final tutorialProvider = TutorialProvider();
    await tutorialProvider.checkTutorialStatus(); // Reset tutorial state
    _user = null;
    await clearLoginStatus(); // Clear login status
    notifyListeners();
  }

  // Clear login status from SharedPreferences
  Future<void> clearLoginStatus() async {
    if (_prefs != null) {
      await _prefs!.remove('userID');
    }
  }
}