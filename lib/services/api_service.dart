import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iprsr/models/user.dart';
import 'dart:async';
import 'dart:io';

class ApiService {
  static const ip = '192.168.0.106'; // ip wifi
  static const String _baseUrl = 'http://$ip/iprsr';
  static const String _flaskUrl = 'http://$ip:5000';
  static const String esp8266IpAddress = "http://192.168.0.105/"; //esp punya ip
  static const String _telegramBotToken =
      "7779399475:AAF091xlVimNGdP46e831oPm32dZGY1HaRc";

  static const String _telegramApiUrl =
      "https://api.telegram.org/bot$_telegramBotToken";

  static const int ESP8266_PORT = 80;  // Default HTTP port
  static const Duration CONNECTION_TIMEOUT = Duration(seconds: 2);

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
  static Future<Map<String, dynamic>> getRecommendations(
      String userID, String location) async {
    try {
      final response = await http.post(
        Uri.parse('$_flaskUrl/suggest-parking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userID': userID,
          'location': location,
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

// Fetch parking spaces data for a specific location
  static Future<List<Map<String, dynamic>>?> getParkingSpaces(
      String location) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fetch_parking_data.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'location': location}), // Send the location as part of the request
      );

      print('Parking Spaces API response status: ${response.statusCode}');
      print('Parking Spaces API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // Safely return the list of parking spaces
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('API responded with an error: ${data['message']}');
        }
      } else {
        print('Failed to fetch parking spaces: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching parking spaces: $e');
    }
    return null; // Return null in case of an error
  }

// Check if ESP8266 is available
static Future<bool> isEsp8266Available() async {
  try {
    final response = await http.get(
      Uri.parse(esp8266IpAddress),
      headers: {'Accept': '*/*'},
    ).timeout(const Duration(seconds: 2));
    
    return response.statusCode == 200;
  } catch (e) {
    print("ESP8266 not available: $e");
    return false;
  }
}

// Function to send HTTP request to ESP8266 to control the gate
  static Future<void> controlGate(String action) async {
    // First verify ESP8266 connection
    final bool isConnected = await verifyEsp8266Connection();
    if (!isConnected) {
      throw Exception('ESP8266 is not accessible. Please check the device connection.');
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
          throw Exception("ESP8266 endpoint not found. Please verify the URL: $url");
        } else {
          throw Exception(
            "Failed to ${action} gate: Status ${response.statusCode} - ${response.body}"
          );
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
      // You might want to show a user-friendly error message here
      return false;
    }
  }

  // Method to send a message to a specific chat ID on Telegram
  static Future<void> sendTelegramMessage(String? chatId, String text) async {
    if (chatId == null) {
      print("Chat ID is null. Cannot send message.");
      return;
    }

    const url = '$_telegramApiUrl/sendMessage';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        print("Message sent successfully.");
      } else {
        print("Failed to send message: ${response.body}");
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Save chat ID in the backend
  static Future<void> saveChatId(String userID, String chatID) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/save_chat_id.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'userID': userID,
          'chatID': chatID,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print("Chat ID saved successfully.");
        } else {
          print("Error saving chat ID: ${data['message']}");
        }
      } else {
        print("Failed to save chat ID. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error saving chat ID: $e");
    }
  }

// Fetch chat ID based on userID
  static Future<String?> getUserChatId(String userID) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/get_chat_id.php'), // Ensure this script exists
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'userID': userID},
      );

      print('Fetch Chat ID API response status: ${response.statusCode}');
      print('Fetch Chat ID API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['chatID'].toString(); // Convert chatID to String
        } else {
          print('Error: ${data['message']}');
        }
      }
    } catch (e) {
      print('Error fetching chat ID: $e');
    }
    return null;
  }

// Method to get updates from Telegram API
  static Future<String?> getChatIdFromTelegram(String userId) async {
    try {
      // Fetch updates from the Telegram API
      final response = await http.get(Uri.parse('$_telegramApiUrl/getUpdates'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updates = data['result'];

        // Loop through each update to find a matching userID or chat ID
        for (var update in updates) {
          if (update.containsKey('message')) {
            final message = update['message'];
            final chatId = message['chat']['id'].toString();
            final text = message['text'];

            // Check if the message text contains the userId or is a /start command
            if (text == '/start' || text == userId) {
              print("Found chat ID: $chatId for user ID: $userId");
              return chatId; // Return chat ID if found
            }
          }
        }
      } else {
        print("Failed to fetch updates from Telegram: ${response.body}");
      }
    } catch (e) {
      print("Error fetching updates from Telegram: $e");
    }
    return null; // Return null if no chat ID is found
  }

  // Send Telegram message based on userID
  static Future<void> sendTelegramMessageToUser(
      String userID, String message) async {
    final chatId = await getUserChatId(userID);
    if (chatId != null) {
      await sendTelegramMessage(chatId, message);
    } else {
      print("Chat ID not found for user $userID");
    }
  }

  // 1. Notify user of payment confirmation for their parking spot
  static Future<void> notifyPaymentConfirmation(
      String chatId, String parkingSpaceID) async {
    final message =
        "Your payment for premium parking spot $parkingSpaceID has been confirmed!";
    await sendTelegramMessage(chatId, message);
  }

  // 2. Notify user of 5-minute remaining reminder
  static Future<void> notifyFiveMinutesRemaining(
      String chatId, String parkingSpaceID) async {
    final message =
        "You have 5 minutes remaining for your premium parking spot $parkingSpaceID.";
    await sendTelegramMessage(chatId, message);
  }

  // 3. Notify user of parking expiration
  static Future<void> notifyParkingExpired(
      String chatId, String parkingSpaceID) async {
    final message =
        "Your premium parking spot $parkingSpaceID has expired. Please vacate the spot or renew if needed.";
    await sendTelegramMessage(chatId, message);
  }

  // Start the parking notification process
  static Future<void> startParkingNotification(
      String userId, String parkingSpaceID) async {
    final chatId = await getUserChatId(userId);

    if (chatId != null) {
      print("Chat ID found: $chatId");

      // Notify the user about payment confirmation
      await notifyPaymentConfirmation(chatId, parkingSpaceID);

      // Changed from 5 minutes to 10 seconds for debugging
      Timer(const Duration(seconds: 30), () async {
        print("Sending expiration notification...");
        await notifyParkingExpired(chatId, parkingSpaceID);
        // Unlock the parking space
        await unlockParkingSpace(parkingSpaceID);
        // Update premium parking status if needed
        await updatePremiumParkingStatus(parkingSpaceID, false);
      });
    } else {
      print("Chat ID not found for user $userId.");

      // Send welcome message to remind the user to start the bot
      const welcomeMessage =
          "Please send '/start' to our bot to receive notifications about your premium parking.";
      await sendTelegramMessage(chatId, welcomeMessage);
    }
  }

  // Add this new method to update premium parking status
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

  // Lock a parking space for a specified duration (in minutes) and notify the user
  static Future<bool> lockParkingSpace(String parkingSpaceID, String userID,
      {required int duration}) async {
    try {
      // Request to lock the parking space
      final response = await http.post(
        Uri.parse('$_baseUrl/update_parking_space.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parkingSpaceID': parkingSpaceID,
          'userID': userID, // Include the userID here
          'isAvailable': 0, // Lock the parking space
        }),
      );

      // Handle the server response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('Parking space $parkingSpaceID locked for $duration minutes.');

          // Schedule to unlock the space after the specified duration
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
          'isAvailable': 1, // Unlock the parking space
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('Parking space $parkingSpaceID unlocked successfully.');

          // Double-check the space was actually unlocked
          final verifyResponse = await http.get(
            Uri.parse('$_baseUrl/check_parking_space.php?id=$parkingSpaceID'),
          );

          if (verifyResponse.statusCode == 200) {
            final verifyData = jsonDecode(verifyResponse.body);
            if (verifyData['isAvailable'] != 1) {
              // If space is still locked, try unlocking one more time
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

  // Helper method to format remaining time
  static String formatRemainingTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Add a method to check user's active sessions
  static Future<Map<String, dynamic>?> checkUserActivePremiumParking(
      String userID) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/check_user_premium_parking.php?userId=$userID'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error checking user premium parking: $e');
      return null;
    }
  }

  // Start premium parking
  static Future<Map<String, dynamic>?> startPremiumParking(
      String parkingSpaceID, String userID) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/start_premium_parking.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parkingSpaceID': parkingSpaceID,
          'userID': userID,
          // Change this to 30 seconds
          'duration': 30, // Duration in seconds
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Start notification process
          startParkingNotification(userID, parkingSpaceID);
          return {
            'remaining_time': 30, // Change this to 30 seconds as well
            'parking_space_id': parkingSpaceID
          };
        }
      }
      return null;
    } catch (e) {
      print('Error starting premium parking: $e');
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

          // Map for converting display names to database keys
          const locationMapping = {
            'SoC': 'SOC',
            'V Mall': 'VMALL',
            'Dewan MAS': 'DMAS',
            'DTSO': 'DTSO',
          };

          data['data'].forEach((location, lotData) {
            // Convert the database location key to display name
            String displayName = locationMapping.entries
                .firstWhere((entry) => entry.value == location,
                    orElse: () => MapEntry(location, location))
                .key;

            List<String> coords = lotData['coordinates'].split(',');
            coordinates[displayName] = LatLng(
              double.parse(coords[0].trim()),
              double.parse(coords[1].trim()),
            );
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

  // Get parking lot boundary
  static Future<List<LatLng>> getParkingLotBoundary(String locationCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fetch_parking_lot_boundaries.php'),
      );

      if (response.statusCode == 200) {
        print('Boundary response: ${response.body}'); // Debug log
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && 
            data['data'].containsKey(locationCode)) {
          List<dynamic> boundaryPoints = data['data'][locationCode]['coordinates'];
          print('Found boundary points: $boundaryPoints'); // Debug log
          return boundaryPoints.map((point) => LatLng(
            point['lat'].toDouble(),
            point['lng'].toDouble(),
          )).toList();
        } else {
          print('No data found for location code: $locationCode');
          print('Available locations: ${data['data'].keys.toList()}');
        }
      }
      return [];
    } catch (e) {
      print('Error fetching parking lot boundary: $e');
      return [];
    }
  }

  // Map for converting display names to database location codes
  static const locationMapping = {
    'SoC': 'SOC_01',
    'V Mall': 'VMALL_01',
    'Dewan MAS': 'DMAS_01',
    'DTSO': 'DTSO_01',
  };

  // Add this method to verify ESP8266 connection
  static Future<bool> verifyEsp8266Connection() async {
    try {
      // Parse the IP address from the ESP8266 URL
      final uri = Uri.parse(esp8266IpAddress);
      final socket = await Socket.connect(
        uri.host, 
        ESP8266_PORT,
        timeout: CONNECTION_TIMEOUT
      );
      socket.destroy();
      return true;
    } catch (e) {
      print('ESP8266 connection failed: $e');
      return false;
    }
  }
}

// Example usage in your UI
Future<void> checkPremiumStatus(String parkingSpaceID) async {
  final status = await ApiService.checkPremiumParkingStatus(parkingSpaceID);

  if (status != null) {
    // Space has active premium parking
    final remainingSeconds = status['remaining_seconds'] as int;
    final formattedTime = ApiService.formatRemainingTime(remainingSeconds);

    print('Premium parking active');
    print('User: ${status['username']}');
    print('Time remaining: $formattedTime');
  } else {
    // Space is not in premium parking mode
    print('No active premium parking');
  }
}
