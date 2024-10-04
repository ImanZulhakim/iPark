import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iprsr/models/user.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.0.106/iprsr';
  static const String _flaskUrl =
      'http://192.168.0.106:5000'; // Flask backend URL

  // Register user
  static Future<User?> register(
    String email,
    String password,
    String username,
    bool gender,
    bool hasDisability,
    String brand,
    String type,
    Map<String, bool> preferences,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': email,
          'password': password,
          'username': username,
          'gender':
              gender ? '1' : '0', // Convert boolean to '1'/'0' for backend
          'hasDisability': hasDisability ? '1' : '0',
          'brand': brand,
          'type': type,
          'preferences': jsonEncode(preferences),
        },
      );

      print('Register API response status: ${response.statusCode}');
      print('Register API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return User.fromJson(data['user']);
        } else {
          print('Error: ${data['message']}');
        }
      }
    } catch (e) {
      print('Error registering user: $e');
    }
    return null;
  }

  // User login
  static Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': email,
          'password': password,
        },
      );

      print('Login API response status: ${response.statusCode}');
      print('Login API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return User.fromJson(data['user']);
        } else {
          print('Login error: ${data['message']}');
        }
      }
    } catch (e) {
      print('Error logging in: $e');
    }
    return null;
  }

  // Fetch parking suggestions using Flask backend
  static Future<String> getRecommendations(String userID) async {
    try {
      final response = await http.post(
        Uri.parse('$_flaskUrl/suggest-parking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userID': userID}),
      );

      print('Parking Suggestions API response status: ${response.statusCode}');
      print('Parking Suggestions API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['parkingSpaceID'] ?? ''; // Return empty string if null
      } else {
        print('Error fetching parking suggestions: ${response.body}');
      }
    } catch (e) {
      print('Error fetching parking suggestions: $e');
    }
    return ''; // Return empty string in case of an exception
  }

  // Fetch user's vehicle details and parking preferences
  static Future<Map<String, dynamic>?> fetchVehicleDetailsAndParkingPreferences(
      String userID) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fetch_user_data.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'userID': userID}, // Assuming the backend requires userID
      );

      print(
          'Fetch Vehicle Details and Parking Preferences API response status: ${response.statusCode}');
      print(
          'Fetch Vehicle Details and Parking Preferences API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data;
        } else {
          print('Error: ${data['message']}');
        }
      }
    } catch (e) {
      print('Error fetching vehicle details and parking preferences: $e');
    }
    return null; // Return null if there's an error
  }

  // Update user's vehicle details and parking preferences
  static Future<bool> updateVehicleDetailsAndParkingPreferences({
    required String userID,
    required String vehicleBrand,
    required String vehicleType,
    required Map<String, bool> preferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update_user_data.php'),
        body: jsonEncode({
          'userID': userID,
          'brand': vehicleBrand,
          'type': vehicleType,
          'preferences': preferences,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );
  
      print('API response status: ${response.statusCode}');
      print('API response body: ${response.body}');
  
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return true;
        } else {
          print('Error: ${data['message']}');
          return false;
        }
      } else {
        print('Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
