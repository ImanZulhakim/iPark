import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/models/user.dart';
import 'package:iprsr/providers/countdown_provider.dart';
import 'package:iprsr/widgets/outdoor_parking_view.dart';

class RecommendationScreen extends StatefulWidget {
  final User user;
  final String location;

  const RecommendationScreen({
    super.key,
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
  late NavigatorState _navigator;
  Timer? _refreshTimer;

  // Fetch recommendations and spaces from the API
  @override
  void initState() {
    super.initState();
    // Store navigator reference when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigator = Navigator.of(context);
    });
    _startRefreshTimer();
    recommendationsFuture = fetchRecommendationsAndSpaces();

    // Only check for active session on first load
    if (!Provider.of<CountdownProvider>(context, listen: false)
        .isCountingDown) {
      checkAndRestoreSession();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        fetchRecommendationsAndSpaces();
      }
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
    _refreshTimer?.cancel();
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
      setState(() async {
        recommendationsFuture = fetchRecommendationsAndSpaces();
        final locationType = await ApiService.getLocationType(widget.location);
        print('Location type received: $locationType');
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
        title: Consumer<CountdownProvider>(
          builder: (context, provider, child) {
            return FutureBuilder<Map<String, dynamic>>(
              future: recommendationsFuture,
              builder: (context, snapshot) {
                String displayLocation = widget.location;
                if (snapshot.hasData &&
                    snapshot.data!['currentLocation'] != null) {
                  displayLocation = snapshot.data!['currentLocation'];
                }
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Parking Recommendations for $displayLocation',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.appBarTheme.foregroundColor ?? Colors.white,
                    ),
                  ),
                );
              },
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: isDarkTheme
            ? Colors.grey[800]
            : theme.appBarTheme.backgroundColor ?? Colors.teal,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]
                : const Color(
                    0xFFADE8F4), // Slightly darker blue for light theme
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Icons.accessible, "Special",
                        Colors.blueAccent, textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(
                        Icons.female, "Female", Colors.pinkAccent, textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.family_restroom, "Family",
                        Colors.purpleAccent, textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.electric_car, "EV Car",
                        Colors.tealAccent, textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.star, "Premium",
                        const Color(0xFFFFD54F), textColor),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Icons.local_parking, "Regular",
                        const Color.fromRGBO(158, 158, 158, 1), textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(Icons.thumb_up, "Recommended",
                        Colors.greenAccent, textColor),
                    const SizedBox(width: 8),
                    _buildLegendItem(
                        Icons.block, "Occupied", Colors.redAccent, textColor),
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
                }

                final parkingSpaces = snapshot.data!['parkingSpaces']
                    as List<Map<String, dynamic>>;
                final String recommendedSpace =
                    snapshot.data!['recommendedSpace'] as String;
                final String locationType =
                    snapshot.data!['locationType'] ?? 'indoor';

                if (locationType.toLowerCase() != 'outdoor') {
                  // Existing indoor visualization
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
                                      : () {},
                                ),
                            ],
                          ),
                      ],
                    ),
                  );
                } else {
                  print('Showing outdoor view for ${widget.location}');
                  // Outdoor visualization using Google Maps
                  return OutdoorParkingView(
                    parkingSpaces: parkingSpaces,
                    recommendedSpace: recommendedSpace,
                    location: widget.location,
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
        future: recommendationsFuture,
        builder: (context, snapshot) {
          return FloatingActionButton(
            onPressed: () {
              if (snapshot.hasData) {
                final parkingSpaces = snapshot.data!['parkingSpaces']
                    as List<Map<String, dynamic>>;
                final recommendedSpaceId =
                    snapshot.data!['recommendedSpace'] as String;

                // Find recommended space coordinates
                final recommendedSpace = parkingSpaces.firstWhere(
                  (space) => space['parkingSpaceID'] == recommendedSpaceId,
                  orElse: () => {'coordinates': null},
                );

                if (recommendedSpace['coordinates'] != null) {
                  List<String> coords =
                      recommendedSpace['coordinates'].split(',');
                  if (coords.length == 2) {
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=${coords[0]},${coords[1]}';
                    launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                    return;
                  }
                }
              }
              // Fallback to location navigation if no coordinates found
              openGoogleMaps(widget.location);
            },
            backgroundColor:
                theme.floatingActionButtonTheme.backgroundColor ?? Colors.teal,
            child: const Icon(Icons.navigation, color: Colors.white),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> fetchRecommendationsAndSpaces() async {
    if (!mounted) return {};

    try {
      final parkingSpaces = await ApiService.getParkingSpaces(widget.location);
      final recommendations = await ApiService.getRecommendations(
          widget.user.userID, widget.location);
      final locationType = await ApiService.getLocationType(widget.location);

      String currentLocation = widget.location;
      List<Map<String, dynamic>>? currentParkingSpaces = parkingSpaces;

      if (recommendations['alternativeLocation'] != null) {
        currentParkingSpaces = await ApiService.getParkingSpaces(
            recommendations['alternativeLocation']);
        currentLocation = recommendations['alternativeLocation'];
      }

      if (mounted) {
        BuildContext? dialogContext;

        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Parking Recommendation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recommendations['alternativeLocation'] != null)
                    Text(
                      'Original location full.\nAlternative parking found at: ${recommendations['alternativeLocation']}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    recommendations['parkingSpaceID'].isEmpty
                        ? 'No suitable parking space found.'
                        : 'Recommended space: ${recommendations['parkingSpaceID']}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              actions: [
                if (recommendations['alternativeLocation'] != null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      openGoogleMaps(recommendations['alternativeLocation']);
                    },
                    child: const Text('Get Directions'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }

      return {
        'parkingSpaces': currentParkingSpaces,
        'recommendedSpace': recommendations['parkingSpaceID'],
        'currentLocation': currentLocation,
        'locationType': locationType,
      };
    } catch (e) {
      print('Error fetching recommendations: $e');
      return {};
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
      print('Starting premium parking process for space: $parkingSpaceID');

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

      // First verify ESP8266 connection
      final bool isEsp8266Connected = await ApiService.isEsp8266Available();
      if (!isEsp8266Connected) {
        throw Exception(
            'Gate control system is not accessible. Please try again later.');
      }

      print('Calling API to create premium parking');

      // Create premium parking session
      bool success = await ApiService.createPremiumParking(
        parkingSpaceID,
        widget.user.userID,
      );

      print('API response success: $success');

      // Remove loading indicator
      if (mounted) {
        Navigator.pop(context);
      }

      if (success) {
        print('Premium parking activated successfully');

        // Start the countdown
        Provider.of<CountdownProvider>(context, listen: false)
            .startCountdown(5, parkingSpaceID, widget.user.userID);

        // Try to close the gate safely
        try {
          final gateSuccess = await ApiService.safeControlGate('close');
          if (!gateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Warning: Gate control system not responding. Please contact staff if needed.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } catch (gateError) {
          print('Gate control error: $gateError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gate control error: ${gateError.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }

        // Show success message for parking activation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium parking activated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Handle Telegram notifications
        final chatId = await ApiService.getUserChatId(widget.user.userID);
        if (chatId == null) {
          await openTelegramOrFallback();
          startTelegramPolling(widget.user.userID, parkingSpaceID);
        } else {
          ApiService.startParkingNotification(
              widget.user.userID, parkingSpaceID);
        }

        // Schedule cleanup after 30 seconds
        Timer(const Duration(seconds: 30), () async {
          try {
            final openSuccess = await ApiService.safeControlGate('open');
            if (!openSuccess && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Warning: Unable to open gate automatically. Please contact staff.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          } catch (gateError) {
            print('Gate opening error: $gateError');
          }

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
        print('Failed to activate premium parking - API returned false');

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
      print('Error in _handlePremiumParking: $e');

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
    final webUri = Uri.parse('https://t.me/iprsr_bot');

    try {
      // First try to launch Telegram app with deep links
      final List<Uri> telegramUris = [
        Uri.parse('telegram://resolve?domain=iprsr_bot'),
        Uri.parse('org.telegram.messenger://resolve?domain=iprsr_bot'),
        Uri.parse('tg://resolve?domain=iprsr_bot'),
      ];

      bool appLaunched = false;

      // Try each deep link
      for (Uri uri in telegramUris) {
        if (await canLaunchUrl(uri)) {
          try {
            appLaunched = await launchUrl(
              uri,
              mode: LaunchMode.externalNonBrowserApplication,
            );
            if (appLaunched) break;
          } catch (e) {
            print('Deep link launch failed: $e');
          }
        }
      }

      // If app launch failed, immediately try web version
      if (!appLaunched) {
        print('App launch failed, trying web version...');
        if (await canLaunchUrl(webUri)) {
          final launched = await launchUrl(
            webUri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
          if (!launched) {
            throw 'Could not launch web version';
          }
        } else {
          throw 'Could not launch web version';
        }
      }
    } catch (e) {
      print('Error launching Telegram: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Error opening Telegram. Please visit https://t.me/iprsr_bot directly'),
            duration: Duration(seconds: 5),
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

  Widget _buildLegendItem(
      IconData icon, String label, Color color, Color textColor) {
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
                _handlePremiumParking(
                    parkingSpaceID); // Process premium parking
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
    final activeSession =
        await ApiService.checkPremiumParkingStatus(widget.user.userID);

    if (activeSession != null) {
      // User has active premium parking
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Active Premium Parking'),
            content: Text(
                'You currently have an active premium parking session at ${activeSession['parking_space_id']}. '
                'Please wait for your current session to end before requesting new recommendations.'),
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
      // No active session, fetch recommendations once
      final recommendations = await fetchRecommendationsAndSpaces();

      if (mounted) {
        setState(() {
          recommendationsFuture = Future.value(recommendations);
        });
      }
    }
  }

  Future<void> checkAndRestoreSession() async {
    final countdownProvider =
        Provider.of<CountdownProvider>(context, listen: false);
    final activeSession =
        await ApiService.checkPremiumParkingStatus(widget.user.userID);

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

  const ParkingSpace({
    super.key,
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
