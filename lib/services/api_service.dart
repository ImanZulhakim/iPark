import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iprsr/models/user.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 

class ApiService {
  static const ip = '172.20.10.3'; // ip wifi
  static const String _baseUrl = 'http://$ip/iprsr';
  static const String _flaskUrl = 'http://$ip:5000';
  static const String esp8266IpAddress = "http:/172.20.10.9/"; //esp punya ip
  static const int ESP8266_PORT = 80; // Default HTTP port
  static const Duration CONNECTION_TIMEOUT = Duration(seconds: 2);

  // Initialize Flutter Local Notifications
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize local notifications
  static Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show a local notification
static Future<void> showLocalNotification({
  required String title,
  required String body,
}) async {
  print('Attempting to show notification: $title - $body'); // Debug log

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'premium_parking_channel', // Channel ID
    'Premium Parking Notifications', // Channel Name
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  try {
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
    );
    print('Notification shown successfully'); // Debug log
  } catch (e) {
    print('Error showing notification: $e'); // Debug log
  }
}

  // Register user
  static Future<User?> register(
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
      final response = await http.post(
        Uri.parse('$_baseUrl/register.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': email,
          'password': password,
          'phoneNo': phoneNo,
          'username': username,
          'gender': gender ? '1' : '0',
          'hasDisability': hasDisability ? '1' : '0',
          'brand': brand,
          'type': type,
          'category': category,
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

  // Fetch user details by user ID
  static Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fetch_user_details.php?userID=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Fetch User Details API response status: ${response.statusCode}');
      print('Fetch User Details API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['user'];
        } else {
          print('Fetch User Details error: ${data['message']}');
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
    return null;
  }

  // Fetch parking suggestions using Flask backend
  static Future<Map<String, dynamic>> getRecommendations(
      String userID, String lotID) async {
    try {
      final response = await http.post(
        Uri.parse('$_flaskUrl/recommend-parking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userID': userID,
          'lotID': lotID,
        }),
      );

      print('Parking Suggestions API response status: ${response.statusCode}');
      print('Parking Suggestions API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'parkingSpaceID': data['parkingSpaceID'] ?? '',
          'message': data['message'] ?? '',
          'alternativeLocation': data['alternativeLocation'],
        };
      } else {
        print('Error fetching parking suggestions: ${response.body}');
      }
    } catch (e) {
      print('Error fetching parking suggestions: $e');
    }
    return {
      'parkingSpaceID': '',
      'message': 'Failed to get recommendations',
      'alternativeLocation': null
    };
  }

  // Fetch user's vehicle details and parking preferences
  static Future<Map<String, dynamic>?> fetchVehicleDetailsAndParkingPreferences(
      String userID) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fetch_user_data.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'userID': userID},
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
    return null;
  }

  // Update user's vehicle details and parking preferences
  static Future<bool> updateVehicleDetailsAndParkingPreferences({
    required String userID,
    required String vehicleBrand,
    required String vehicleType,
    required String vehicleCategory,
    required Map<String, bool> preferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update_user_data.php'),
        body: jsonEncode({
          'userID': userID,
          'brand': vehicleBrand,
          'type': vehicleType,
          'category': vehicleCategory,
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

  // Fetch parking spaces data for a specific location
  static Future<List<Map<String, dynamic>>> getParkingData(lotID) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fetch_parking_spaces.php?lotID=$lotID'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('Parking data fetched successfully: ${data['data']}');
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Failed to load parking data');
    } catch (e) {
      print('Error fetching parking data: $e');
      throw Exception('Failed to load parking data');
    }
  }

  // Check if ESP8266 is available
static Future<bool> isEsp8266Available() async {
  try {
    final response = await http.get(
      Uri.parse("http://192.168.1.27/"), // Use the root endpoint
      headers: {'Accept': '*/*'},
    ).timeout(const Duration(seconds: 5)); // Increased timeout

    print("ESP8266 response status: ${response.statusCode}");
    print("ESP8266 response body: ${response.body}");

    return response.statusCode == 200;
  } catch (e) {
    print("ESP8266 not available: $e");
    return false;
  }
}

  // Function to send HTTP request to ESP8266 to control the gate
  static Future<void> controlGate(String action) async {
    final bool isConnected = await verifyEsp8266Connection();
    if (!isConnected) {
      throw Exception(
          'ESP8266 is not accessible. Please check the device connection.');
    }

    final String endpoint = action == "close" ? "close_gate" : "open_gate";
    final String url = "$esp8266IpAddress$endpoint";

    print("Attempting to control gate - URL: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Gate control request timed out');
        },
      );

      print("Gate control response status: ${response.statusCode}");
      print("Gate control response body: ${response.body}");

      if (response.statusCode == 200) {
        print("Gate ${action == 'close' ? 'closed' : 'opened'} successfully.");
      } else {
        if (response.body.contains("<!DOCTYPE HTML")) {
          throw Exception(
              "ESP8266 endpoint not found. Please verify the URL: $url");
        } else {
          throw Exception(
              "Failed to $action gate: Status ${response.statusCode} - ${response.body}");
        }
      }
    } catch (e) {
      print("Error controlling gate: $e");
      rethrow;
    }
  }

  // Add a method to handle gate control with proper error handling
  static Future<bool> safeControlGate(String action) async {
    try {
      await controlGate(action);
      return true;
    } catch (e) {
      print('Safe gate control failed: $e');
      return false;
    }
  }

  // Lock a parking space for a specified duration (in minutes) and notify the user
  static Future<bool> lockParkingSpace(String parkingSpaceID, String userID,
      {required int duration}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update_parking_space.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parkingSpaceID': parkingSpaceID,
          'userID': userID,
          'isAvailable': 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('Parking space $parkingSpaceID locked for $duration minutes.');

          Future.delayed(Duration(minutes: duration), () async {
            await unlockParkingSpace(parkingSpaceID);
          });

          return true;
        } else {
          print('Error locking parking space: ${data['message']}');
        }
      } else {
        print(
            'Failed to lock parking space, Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error locking parking space: $e');
    }
    return false;
  }

  // Unlock a parking space
  static Future<bool> unlockParkingSpace(String parkingSpaceID) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update_parking_space.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parkingSpaceID': parkingSpaceID,
          'isAvailable': 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('Parking space $parkingSpaceID unlocked successfully.');

          final verifyResponse = await http.get(
            Uri.parse('$_baseUrl/check_parking_space.php?id=$parkingSpaceID'),
          );

          if (verifyResponse.statusCode == 200) {
            final verifyData = jsonDecode(verifyResponse.body);
            if (verifyData['isAvailable'] != 1) {
              await http.post(
                Uri.parse('$_baseUrl/update_parking_space.php'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'parkingSpaceID': parkingSpaceID,
                  'isAvailable': 1,
                }),
              );
            }
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error unlocking parking space: $e');
      return false;
    }
  }

  // Create premium parking session
  static Future<bool> createPremiumParking(
    String parkingSpaceID,
    String userID,
  ) async {
    try {
      print('Creating premium parking with:');
      print('Parking Space ID: $parkingSpaceID');
      print('User ID: $userID');

      final response = await http.post(
        Uri.parse('$_baseUrl/create_premium_parking.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parkingSpaceID': parkingSpaceID,
          'userID': userID,
        }),
      );

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error in createPremiumParking: $e');
      return false;
    }
  }

  // Check premium parking status
  static Future<Map<String, dynamic>?> checkPremiumParkingStatus(
      String parkingSpaceID) async {
    try {
      print('Checking premium parking status for space: $parkingSpaceID');

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/check_premium_parking.php?spaceId=$parkingSpaceID'),
      );

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error checking premium parking status: $e');
      return null;
    }
  }

  // Start the parking notification process
  static Future<void> startParkingNotification(
      String userId, String parkingSpaceID) async {
    // Notify the user about payment confirmation
    await showLocalNotification(
      title: 'Premium Parking Activated',
      body: 'Your premium parking spot $parkingSpaceID has been activated.',
    );

    // Schedule expiration notification
    Timer(const Duration(seconds: 30), () async {
      await showLocalNotification(
        title: 'Premium Parking Expired',
        body: 'Your premium parking spot $parkingSpaceID has expired.',
      );

      // Unlock the parking space
      await unlockParkingSpace(parkingSpaceID);
      // Update premium parking status if needed
      await updatePremiumParkingStatus(parkingSpaceID, false);
    });
  }

  // Update premium parking status
  static Future<bool> updatePremiumParkingStatus(
      String parkingSpaceID, bool isActive) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update_premium_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parkingSpaceID': parkingSpaceID,
          'isActive': isActive ? 1 : 0,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating premium status: $e');
      return false;
    }
  }

  // Verify ESP8266 connection
  static Future<bool> verifyEsp8266Connection() async {
    try {
      final uri = Uri.parse(esp8266IpAddress);
      final socket = await Socket.connect(uri.host, ESP8266_PORT,
          timeout: CONNECTION_TIMEOUT);
      socket.destroy();
      print("ESP8266 is reachable at $esp8266IpAddress");
      return true;
    } catch (e) {
      print("ESP8266 connection failed: $e");
      return false;
    }
  }

  // Get location type
  static Future<String> getLocationType(String lotID) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get_location_type.php?lotID=$lotID'),
      );

      print('Location type API response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final type = data['data']['locationType'].toString().toLowerCase();
        print('Parsed location type: $type');
        return type;
      }
      return 'indoor';
    } catch (e) {
      print('Error getting location type: $e');
      return 'indoor';
    }
  }

  // Fetch parking location data (state -> district -> parking lot)
  static Future<Map<String, dynamic>> getParkingLocation() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fetch_parking_location.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('Parking data fetched successfully: ${data['data']}');
          return data;
        }
      }
      throw Exception('Failed to load parking data');
    } catch (e) {
      print('Error fetching parking data: $e');
      throw Exception('Failed to load parking data');
    }
  }

  // Fetch the last_used_lotID for a specific user
  static Future<String?> getLastUsedLotID(String userID) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get_last_used_lotID.php?userID=$userID'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print(
              'Last used lotID fetched successfully: ${data['data']['last_used_lotID']}');
          return data['data']['last_used_lotID'];
        }
      }
      throw Exception('Failed to fetch last_used_lotID');
    } catch (e) {
      print('Error fetching last_used_lotID: $e');
      return null;
    }
  }

  // Update the last_used_lotID for a specific user
  static Future<void> updateLastUsedLotID(String userID, String lotID) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update_last_used_lotID.php'),
        body: {
          'userID': userID,
          'last_used_lotID': lotID,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print(
              'Last used lotID updated successfully for user $userID to $lotID');
        } else {
          throw Exception('Failed to update last_used_lotID');
        }
      } else {
        throw Exception('Failed to update last_used_lotID');
      }
    } catch (e) {
      print('Error updating last_used_lotID: $e');
      throw Exception('Failed to update last_used_lotID');
    }
  }

  // Fetch the lot name based on the lotID
  static Future<String?> getLotName(String lotID) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get_lot_name.php?lotID=$lotID'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('Lot name fetched successfully: ${data['data']['lot_name']}');
          return data['data']['lot_name'];
        }
      }
      throw Exception('Failed to fetch lot name');
    } catch (e) {
      print('Error fetching lot name: $e');
      return null;
    }
  }

  // Get parking lot coordinates
  static Future<Map<String, LatLng>> getParkingLotCoordinates() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fetch_parking_lot_coordinates.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Map<String, LatLng> coordinates = {};

          data['data'].forEach((lotName, lotData) {
            // Parse coordinates
            if (lotData['coordinates'] != null) {
              List<String> coords = lotData['coordinates'].split(',');
              coordinates[lotName] = LatLng(
                double.parse(coords[0].trim()),
                double.parse(coords[1].trim()),
              );
            }
          });

          return coordinates;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching parking lot coordinates: $e');
      return {};
    }
  }

// Get parking lot coordinates for a specific lotID
static Future<LatLng?> getSpecificParkingLotCoordinates(String lotID) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/fetch_specific_parking_lot_coordinates.php?lotID=$lotID'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['coordinates'] != null) {
        List<String> coords = data['coordinates'].split(',');
        return LatLng(
          double.parse(coords[0].trim()),
          double.parse(coords[1].trim()),
        );
      }
    }
    return null;
  } catch (e) {
    print('Error fetching parking lot coordinates: $e');
    return null;
  }
}

  // Get parking lot boundary
  static Future<List<LatLng>> getParkingLotBoundary(String lotID) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fetch_parking_lot_boundaries.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' &&
            data['data'] != null &&
            data['data'].containsKey(lotID)) {
          List<dynamic> boundaryPoints = data['data'][lotID]['coordinates'];
          return boundaryPoints
              .map((point) => LatLng(
                    point['lat'].toDouble(),
                    point['lng'].toDouble(),
                  ))
              .toList();
        } else {
          print('No boundary data found for lotID: $lotID');
          return [];
        }
      } else {
        print('Failed to fetch boundary points. HTTP ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching parking lot boundary: $e');
      return [];
    }
  }
}
