import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iprsr/models/user.dart';
import 'dart:async';

class ApiService {
  static const String _baseUrl = 'http://192.168.1.5/iprsr';
  static const String _flaskUrl = 'http://192.168.1.5:5000';
  static const String _telegramBotToken =
      "7779399475:AAF091xlVimNGdP46e831oPm32dZGY1HaRc";

  static const String _telegramApiUrl =
      "https://api.telegram.org/bot$_telegramBotToken";

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
  static Future<String> getRecommendations(
      String userID, String location) async {
    try {
      final response = await http.post(
        Uri.parse('$_flaskUrl/suggest-parking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userID': userID,
          'location': location, // Include the location in the request body
        }),
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

  // Method to send a message to a specific chat ID on Telegram
  static Future<void> sendTelegramMessage(String? chatId, String text) async {
    if (chatId == null) {
      print("Chat ID is null. Cannot send message.");
      return;
    }

    final url = '$_telegramApiUrl/sendMessage';
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
      print("Sending payment confirmation...");
      await notifyPaymentConfirmation(chatId, parkingSpaceID);
      await notifyFiveMinutesRemaining(chatId, parkingSpaceID);

      // Notify expiration after 10 minutes
      Timer(Duration(minutes: 5), () async {
        print("Sending expiration notification...");
        await notifyParkingExpired(chatId, parkingSpaceID);
      });
    } else {
      print("Chat ID not found for user $userId.");

      // Send welcome message to remind the user to start the bot
      final welcomeMessage =
          "Please send '/start' to our bot to receive notifications about your premium parking.";
      await sendTelegramMessage(chatId, welcomeMessage);
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
          return true;
        } else {
          print('Error unlocking parking space: ${data['message']}');
        }
      } else {
        print(
            'Failed to unlock parking space, Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error unlocking parking space: $e');
    }
    return false;
  }
}
