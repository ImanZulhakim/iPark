import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iprsr/models/user.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.0.100/iprsr';

  static Future<User?> register(String email, String password, String username, String gender, String hasDisability, String brand, String type, Map<String, bool> preferences) async {
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

    // Log the raw response for debugging
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return User.fromJson(data['user']);
      }
    }
    return null;
  }

  static Future<User?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login.php'),
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return User.fromJson(data['user']);
      }
    }
    return null;
  }

  static Future<List<dynamic>> getRecommendations(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/recommendations.php?user_id=$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['recommendations'];
      }
    }
    return [];
  }
}
