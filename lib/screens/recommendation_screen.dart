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
    
    // Only check for active session on first load
    if (!Provider.of<CountdownProvider>(context, listen: false).isCountingDown) {
      checkAndRestoreSession();
    }
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
  void _onCountdownUpdate() async {
    final countdownProvider =
        Provider.of<CountdownProvider>(context, listen: false);
    if (!countdownProvider.isCountingDown) {
      // Unlock the parking space when countdown ends
      final parkingSpaceID = countdownProvider.activeParkingSpaceID;
      if (parkingSpaceID != null) {
        await ApiService.unlockParkingSpace(parkingSpaceID);
      }
      
      // Refresh recommendationsFuture
      setState(() {
        recommendationsFuture = fetchRecommendationsAndSpaces();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    final textColor = isDarkTheme ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Parking Recommendations for ${widget.location}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.appBarTheme.foregroundColor ?? Colors.white,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: isDarkTheme ? Colors.grey[800] : theme.appBarTheme.backgroundColor ?? Colors.teal,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[700] 
                : const Color(0xFFADE8F4), // Slightly darker blue for light theme
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Icons.accessible, "Special", Colors.blueAccent, textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.female, "Female", Colors.pinkAccent, textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.family_restroom, "Family", Colors.purpleAccent, textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.electric_car, "EV Car", Colors.tealAccent, textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.star, "Premium", const Color(0xFFFFD54F), textColor),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Icons.local_parking, "Regular", const Color.fromRGBO(158, 158, 158, 1), textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.thumb_up, "Recommended", Colors.greenAccent, textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.block, "Occupied", Colors.redAccent, textColor),
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
                                          _handleParkingSpaceSelection(
                                              parkingSpaces[i + j]
                                                  ['parkingSpaceID'],
                                              parkingSpaces[i + j]
                                                  ['parkingType'] ==
                                              'Premium');
                                        }
                                      : () {
                                          // Do nothing for non-premium parking spaces
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
        backgroundColor: theme.floatingActionButtonTheme.backgroundColor ?? Colors.teal,
        child: const Icon(Icons.navigation, color: Colors.white),
      ),
    );
  }

  Future<Map<String, dynamic>> fetchRecommendationsAndSpaces() async {
    try {
      final parkingSpaces = await ApiService.getParkingSpaces(widget.location);
      final recommendedSpace = await ApiService.getRecommendations(
          widget.user.userID, widget.location);
      
      if (mounted) {
        // Store dialog context reference
        BuildContext? dialogContext;
        
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            dialogContext = context;
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Recommended Parking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: Text(
                recommendedSpace.isEmpty
                  ? 'No suitable parking space found based on your preferences.'
                  : 'Your recommended parking space is: $recommendedSpace',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            );
          },
        );

        // Dismiss dialog after delay if still mounted
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && dialogContext != null && Navigator.canPop(dialogContext!)) {
            Navigator.pop(dialogContext!);
          }
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

  void _handlePremiumParking(String parkingSpaceID) async {
    try {
      print('Starting premium parking process for space: $parkingSpaceID'); // Debug log
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      print('Calling API to create premium parking'); // Debug log
      
      // Create premium parking session
      bool success = await ApiService.createPremiumParking(
        parkingSpaceID,
        widget.user.userID,
      );

      print('API response success: $success'); // Debug log

      // Remove loading indicator
      if (mounted) {
        Navigator.pop(context);
      }

      if (success) {
        print('Premium parking activated successfully'); // Debug log
        
        // Start the countdown
        Provider.of<CountdownProvider>(context, listen: false)
            .startCountdown(5, parkingSpaceID, widget.user.userID);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium parking activated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Close the gate
        await ApiService.controlGate("close");

        // Handle Telegram notifications
        final chatId = await ApiService.getUserChatId(widget.user.userID);
        if (chatId == null) {
          await openTelegramOrFallback();
          startTelegramPolling(widget.user.userID, parkingSpaceID);
        } else {
          ApiService.startParkingNotification(widget.user.userID, parkingSpaceID);
        }

        // Schedule cleanup after 5 minutes
        Timer(const Duration(minutes: 5), () async {
          await ApiService.controlGate("open");
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Premium parking session ended'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      } else {
        print('Failed to activate premium parking - API returned false'); // Debug log
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to activate premium parking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _handlePremiumParking: $e'); // Debug log
      
      // Remove loading indicator if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Function to open Telegram or fallback to web link
  Future<void> openTelegramOrFallback() async {
    // Try multiple Telegram deep link formats
    final List<Uri> telegramUris = [
      Uri.parse('telegram://resolve?domain=iprsr_bot'),
      Uri.parse('org.telegram.messenger://resolve?domain=iprsr_bot'),
      Uri.parse('tg://resolve?domain=iprsr_bot'),
    ];
    
    try {
      bool launched = false;
      // Try each URI until one works
      for (Uri uri in telegramUris) {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          if (launched) break;
        }
      }
      
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Telegram app. Please check if it is installed.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching Telegram: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening Telegram. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
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

  Widget _buildLegendItem(IconData icon, String label, Color color, Color textColor) {
    return Row(
      children: [
        Stack(
          children: [
            // Black outline
            Icon(
              icon,
              color: Colors.black,
              size: 18, // Slightly larger for outline
            ),
            // Colored icon
            Icon(
              icon,
              color: color,
              size: 16,
            ),
          ],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: 12),
        ),
      ],
    );
  }

  void _handleParkingSpaceSelection(String parkingSpaceID, bool isPremium) {
    if (isPremium) {
      // Show payment dialog for premium parking
      _showPaymentDialog(context, parkingSpaceID);
    } else {
      // Handle regular parking
      // ... your existing regular parking logic ...
    }
  }

  void _showPaymentDialog(BuildContext context, String parkingSpaceID) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "Premium Parking",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "This is a premium parking spot. Proceed with payment?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _handlePremiumParking(parkingSpaceID); // Process premium parking
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Pay"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRecommendationButton() async {
    // First check if user has active premium parking
    final activeSession = await ApiService.checkPremiumParkingStatus(widget.user.userID);
    
    if (activeSession != null) {
      // User has active premium parking
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Active Premium Parking'),
            content: Text(
              'You currently have an active premium parking session at ${activeSession['parking_space_id']}. '
              'Please wait for your current session to end before requesting new recommendations.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      // No active session, proceed with normal recommendation logic
      setState(() {
        recommendationsFuture = fetchRecommendationsAndSpaces();
      });
    }
  }

  Future<void> checkAndRestoreSession() async {
    final countdownProvider = Provider.of<CountdownProvider>(context, listen: false);
    final activeSession = await ApiService.checkPremiumParkingStatus(widget.user.userID);
    
    if (activeSession != null && activeSession['remaining_time'] > 0) {
      // Only restore if there's actual time remaining
      countdownProvider.restoreCountdown(
        activeSession['remaining_time'], 
        activeSession['parking_space_id'],
        widget.user.userID,
      );
    }
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
