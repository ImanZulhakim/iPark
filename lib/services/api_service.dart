import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iprsr/models/user.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.0.105/iprsr';
  static const String _flaskUrl = 'http://192.168.0.105:5000'; // Flask backend URL

  // Register user
  static Future<User?> register(
    String email,
    String password,
    String username,
    bool gender,
    bool hasDisability,
    String brand,
    String type,
    Map<String, bool> preferences
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register.php'),
        body: {
          'email': email,
          'password': password,
          'username': username,
          'gender': gender,
          'hasDisability': hasDisability,
          'brand': brand,
          'type': type,
          'preferences': jsonEncode(preferences),
        },
      );

      // Log raw response for debugging
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

  // // Fetch recommendations (keeping it as it is)
  // static Future<List<dynamic>> getRecommendations(String userId) async {
  //   try {
  //     final response = await http.get(Uri.parse('$_baseUrl/recommendations.php?user_id=$userId'));

  //     print('Recommendations API response status: ${response.statusCode}');
  //     print('Recommendations API response body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data['status'] == 'success') {
  //         return data['recommendations'];
  //       } else {
  //         print('Error fetching recommendations: ${data['message']}');
  //       }
  //     }
  //   } catch (e) {
  //     print('Error fetching recommendations: $e');
  //   }
  //   return [];
  // }

  // Fetch parking suggestions using Flask backend
  static Future<List<dynamic>> getRecommendations(String userID) async {
  try {
    final response = await http.post(
      Uri.parse('$_flaskUrl/suggest-parking'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userID': userID,  // Pass the userID instead of preferences
      }),
    );

    print('Parking Suggestions API response status: ${response.statusCode}');
    print('Parking Suggestions API response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['recommendations'];  // Return the list of parking suggestions
    } else {
      print('Error fetching parking suggestions: ${response.body}');
    }
  } catch (e) {
    print('Error fetching parking suggestions: $e');
  }
  return [];
}

}
