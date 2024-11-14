import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/models/user.dart';
import 'package:iprsr/providers/countdown_provider.dart';

class RecommendationScreen extends StatefulWidget {
  final User user;
  final String location;

  const RecommendationScreen({super.key, 
    required this.user,
    required this.location,
  });

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  late Future<Map<String, dynamic>> recommendationsFuture;
  Timer? telegramPollingTimer;
  late final CountdownProvider _providerInstance;

  // Fetch recommendations and spaces from the API
  @override
  void initState() {
    super.initState();
    recommendationsFuture = fetchRecommendationsAndSpaces();

    // Listen to changes in the CountdownProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CountdownProvider>(context, listen: false)
          .addListener(_onCountdownUpdate);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerInstance = Provider.of<CountdownProvider>(context, listen: false);
  }

  @override
  void dispose() {
    telegramPollingTimer?.cancel();
    _providerInstance.removeListener(_onCountdownUpdate);
    super.dispose();
  }

  // Callback function to handle countdown updates
  void _onCountdownUpdate() {
    final countdownProvider =
        Provider.of<CountdownProvider>(context, listen: false);
    if (!countdownProvider.isCountingDown) {
      // Refresh recommendationsFuture when the countdown ends
      setState(() {
        recommendationsFuture = fetchRecommendationsAndSpaces();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Parking Recommendations for ${widget.location}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                        Icons.accessible, "Special", Colors.blueAccent),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.female, "Female", Colors.pinkAccent),
                    const SizedBox(width: 8),
                    _buildLegendItem(
                        Icons.family_restroom, "Family", Colors.purpleAccent),
                    const SizedBox(width: 8),
                    _buildLegendItem(
                        Icons.electric_car, "EV Car", Colors.tealAccent),
                    const SizedBox(width: 8),
                    _buildLegendItem(
                        Icons.star, "Premium", const Color(0xFFFFD54F)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Icons.local_parking, "Regular",
                        const Color.fromRGBO(158, 158, 158, 1)),
                    const SizedBox(width: 8),
                    _buildLegendItem(
                        Icons.thumb_up, "Recommended", Colors.greenAccent),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.block, "Occupied", Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 20, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.green),
                    Text('Entrance', style: TextStyle(color: Colors.green)),
                  ],
                ),
                Column(
                  children: [
                    Text('Exit', style: TextStyle(color: Colors.red)),
                    Icon(Icons.arrow_upward, color: Colors.red),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: recommendationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(
                      child: Text('No parking spaces available.'));
                } else {
                  final parkingSpaces = snapshot.data!['parkingSpaces']
                      as List<Map<String, dynamic>>;
                  final String recommendedSpace =
                      snapshot.data!['recommendedSpace'] as String;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        for (int i = 0; i < parkingSpaces.length; i += 4)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int j = 0;
                                  j < 4 && i + j < parkingSpaces.length;
                                  j++)
                                ParkingSpace(
                                  space: parkingSpaces[i + j],
                                  isRecommended: parkingSpaces[i + j]
                                          ['parkingSpaceID'] ==
                                      recommendedSpace,
                                  onShowPaymentDialog: parkingSpaces[i + j]
                                              ['parkingType'] ==
                                          'Premium'
                                      ? () {
                                          _showPaymentDialog(
                                              context,
                                              parkingSpaces[i + j]
                                                  ['parkingSpaceID']);
                                        }
                                      : () {
                                          // Show message for non-premium parking spaces
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Payment is only available for Premium parking spots.'),
                                            backgroundColor: Colors.red,
                                          ));
                                        },
                                ),
                            ],
                          ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openGoogleMaps(widget.location);
        },
        
        backgroundColor: Colors.teal,
        child: const Icon(Icons.navigation, color: Colors.white),
      ),
    );
  }

  Future<Map<String, dynamic>> fetchRecommendationsAndSpaces() async {
    try {
      final parkingSpaces = await ApiService.getParkingSpaces(widget.location);
      final recommendedSpace = await ApiService.getRecommendations(
          widget.user.userID, widget.location);
      
      // Show dialog if no suitable parking space is found
      if (recommendedSpace.isEmpty) {
        // Use Future.delayed to avoid BuildContext sync issues
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('No Suitable Parking'),
                content: const Text('No suitable parking space found based on your preferences.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        });
      }
      
      return {
        'parkingSpaces': parkingSpaces,
        'recommendedSpace': recommendedSpace,
      };
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  void openGoogleMaps(String locationName) async {
    final Map<String, String> locationLinks = {
      'SoC': 'https://maps.app.goo.gl/fp4eZGT4dvbbiTzj7',
      'C-mart Changlun': 'https://maps.app.goo.gl/h7v6aZmaSJdRRMoQA',
      'Aman Central': 'https://maps.app.goo.gl/AH3AXEUqXGrWbME67',
      'V Mall': 'https://maps.app.goo.gl/d5CZPygW47Ftthwd8',
    };

    final url = locationLinks[locationName];
    if (url != null) {
      final Uri uri = Uri.parse(url);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          print('Could not launch $url');
        }
      } catch (e) {
        print("Error launching URL: $e");
      }
    } else {
      print('No URL found for location: $locationName');
    }
  }

// Show the payment dialog
  void _showPaymentDialog(BuildContext context, String parkingSpaceID) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Premium Parking"),
        content: Text(
            "This is a premium parking spot for $parkingSpaceID. Proceed with payment?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Lock the parking space
              bool success = await ApiService.lockParkingSpace(
                  parkingSpaceID, widget.user.userID,
                  duration: 5);

              if (success) {
                // Display success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Parking spot $parkingSpaceID locked for 5 minutes.'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Start the countdown
                _providerInstance.startCountdown(5, parkingSpaceID, widget.user.userID);

                // Refresh recommendations to update UI
                setState(() {
                  recommendationsFuture = fetchRecommendationsAndSpaces();
                });

                // Close the gate by triggering the servo to close
                await ApiService.controlGate("close");
                print("Gate closed for parking space $parkingSpaceID.");

                // Check if the chat ID is already saved for this user
                final chatId =
                    await ApiService.getUserChatId(widget.user.userID);
                if (chatId == null) {
                  // Redirect user to Telegram to start chatting with the bot
                  await openTelegramOrFallback();

                  // Start polling to check for chat ID after opening Telegram
                  startTelegramPolling(widget.user.userID, parkingSpaceID);
                } else {
                  // Start sending notifications since the chat ID is available
                  ApiService.startParkingNotification(
                      widget.user.userID, parkingSpaceID);
                }

                // Schedule the gate to open after the countdown duration ends (5 minutes)
                Timer(const Duration(minutes: 5), () async {
                  await ApiService.controlGate("open");
                  print("Gate opened after countdown for parking space $parkingSpaceID.");
                });
              } else {
                // Display failure message if unable to lock the parking space
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to lock the parking spot."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Pay"),
          ),
        ],
      );
    },
  );
}


// Function to open Telegram or fallback to web link
  Future<void> openTelegramOrFallback() async {
    final Uri botUrl = Uri.parse('https://t.me/iprsr_bot?start');
    final Uri fallbackUrl = Uri.parse('https://web.telegram.org/');

    if (await canLaunchUrl(botUrl)) {
      await launchUrl(botUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(fallbackUrl)) {
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    } else {
      print("Could not open Telegram.");
    }
  }

// Start polling to check for the chat ID
  void startTelegramPolling(String userID, String parkingSpaceID) {
    Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
      final newChatId = await ApiService.getChatIdFromTelegram(userID);
      if (newChatId != null) {
        await ApiService.saveChatId(userID, newChatId);
        print("Chat ID saved successfully.");
        ApiService.startParkingNotification(
            userID, parkingSpaceID); // Start notifications
        timer.cancel(); // Stop polling once the chat ID is saved
      } else {
        print("Polling: Chat ID not yet available.");
      }
    });
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black87, fontSize: 12),
        ),
      ],
    );
  }
}

class ParkingSpace extends StatelessWidget {
  final Map<String, dynamic> space;
  final bool isRecommended;
  final VoidCallback onShowPaymentDialog;

  const ParkingSpace({super.key, 
    required this.space,
    required this.isRecommended,
    required this.onShowPaymentDialog,
  });

  @override
  Widget build(BuildContext context) {
    final countdownProvider = Provider.of<CountdownProvider>(context);
    final authProvider = Provider.of<AuthService>(context, listen: false);
    final bool isAvailable = space['isAvailable'].toString() == '1';
    final String parkingType = space['parkingType']?.toString() ?? 'Regular';
    final String parkingSpaceID = space['parkingSpaceID'];

    // Determine if this is the premium parking space with an active countdown for this user
    bool isPremiumAndCountingDown = countdownProvider.isCountingDown &&
        countdownProvider.activeParkingSpaceID == parkingSpaceID &&
        countdownProvider.activeUserID ==
            authProvider.user?.userID; // Check userID

    Color bgColor;
    IconData? icon;
    double iconSize = 24;

    if (isPremiumAndCountingDown) {
      bgColor = Colors.orangeAccent; // Color for premium with countdown
      icon = Icons.timer;
      iconSize = 28;
    } else if (!isAvailable) {
      bgColor = const Color.fromARGB(255, 255, 117, 117); // Occupied for others
      icon = Icons.block;
      iconSize = 28;
    } else if (isRecommended) {
      bgColor = Colors.greenAccent;
      icon = Icons.thumb_up;
    } else {
      switch (parkingType) {
        case 'Special':
          bgColor = const Color(0xFF90CAF9);
          icon = Icons.accessible;
          break;
        case 'Female':
          bgColor = const Color(0xFFF48FB1);
          icon = Icons.female;
          break;
        case 'Family':
          bgColor = const Color(0xFFCE93D8);
          icon = Icons.family_restroom;
          break;
        case 'EV Car':
          bgColor = const Color(0xFFA5D6A7);
          icon = Icons.electric_car;
          break;
        case 'Premium':
          bgColor = const Color(0xFFFFD54F);
          icon = Icons.star;
          break;
        default:
          bgColor = Colors.grey[500]!;
          icon = Icons.local_parking;
      }
    }

    return GestureDetector(
      onTap: onShowPaymentDialog,
      child: Container(
        width: 60,
        height: 100,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isRecommended ? Colors.green : Colors.black12,
            width: isRecommended ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
            if (isPremiumAndCountingDown)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${countdownProvider.remainingTime.inMinutes}:${(countdownProvider.remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else if (isAvailable || isRecommended)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  parkingSpaceID,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
