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
  final String lotID;
  final String lot_name;

  const RecommendationScreen({
    super.key,
    required this.user,
    required this.lotID,
    required this.lot_name, 
  });

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  late Future<Map<String, dynamic>> recommendationsFuture;
  Timer? telegramPollingTimer;
  late final CountdownProvider _providerInstance;
  Timer? _refreshTimer;
  // final bool _isDialogShown = false; // Add this flag to track the dialog state

  // Add a state variable to track the current floor
  String? _currentFloor;
  List<String> _floors = [];

  // Fetch recommendations and spaces from the API
  @override
  void initState() {
    super.initState();
    // Store navigator reference when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    _startRefreshTimer();
    recommendationsFuture = fetchRecommendationsAndSpaces();
    recommendationsFuture.then((data) {
      if (data['floors'] != null) {
        setState(() {
          _floors = List<String>.from(data['floors']);
          _currentFloor = _floors.isNotEmpty ? _floors.first : 'No Floors';
        });
      } else {
        setState(() {
          _floors = [];
          _currentFloor = 'No Floors';
        });
      }
    });

    // Only check for active session on first load
    if (!Provider.of<CountdownProvider>(context, listen: false)
        .isCountingDown) {
      checkAndRestoreSession();
    }
  }

  void _navigateFloor(String direction) {
    if (_floors.isEmpty || _currentFloor == null) return;

    final currentIndex = _floors.indexOf(_currentFloor!);
    if (currentIndex == -1) return;

    setState(() {
      if (direction == 'up' && currentIndex < _floors.length - 1) {
        _currentFloor = _floors[currentIndex + 1];
      } else if (direction == 'down' && currentIndex > 0) {
        _currentFloor = _floors[currentIndex - 1];
      }
    });
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
        final locationType = await ApiService.getLocationType(widget.lotID);
        print('Location type received: $locationType');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<CountdownProvider>(
          builder: (context, provider, child) {
            return FutureBuilder<Map<String, dynamic>>(
              future: recommendationsFuture,
              builder: (context, snapshot) {
                String displayLocation = widget.lot_name;
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
              // openGoogleMaps(widget.lotID);
            },
            backgroundColor:
                theme.floatingActionButtonTheme.backgroundColor ?? Colors.teal,
            child: const Icon(Icons.navigation, color: Colors.white),
          );
        },
      ),
      body: Column(
        children: [
          Container(
            alignment: Alignment.topLeft,
            child: Card(
              margin: const EdgeInsets.all(8),
              elevation: 4,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem(
                            'Regular', Colors.grey, Icons.local_parking),
                        _buildLegendItem('Special', const Color(0xFF90CAF9),
                            Icons.accessible),
                        _buildLegendItem(
                            'Female', const Color(0xFFF48FB1), Icons.female),
                        _buildLegendItem('Family', const Color(0xFFCE93D8),
                            Icons.family_restroom),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem('EV Car', const Color(0xFFA5D6A7),
                            Icons.electric_car),
                        _buildLegendItem(
                            'Premium', const Color(0xFFFFD54F), Icons.star),
                        _buildLegendItem('Occupied', Colors.red, Icons.block),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: recommendationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Expanded(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              } else if (!snapshot.hasData ||
                  snapshot.data!['parkingSpaces'] == null) {
                return const Expanded(
                  child: Center(child: Text('No parking spaces available.')),
                );
              }

              final locationType = snapshot.data?['locationType'] ?? 'indoor';
              final parkingSpaces =
                  snapshot.data!['parkingSpaces'] as List<Map<String, dynamic>>;
              final String recommendedSpace =
                  snapshot.data!['recommendedSpace'] as String;

              // Handle outdoor parking lot
              if (locationType.toLowerCase() == 'outdoor') {
                return Expanded(
                  child: OutdoorParkingView(
                    parkingSpaces: parkingSpaces,
                    recommendedSpace: recommendedSpace,
                    lotID: widget.lotID,
                  ),
                );
              }

              // Handle indoor parking lot
              final spacesByFloor = snapshot.data!['spacesByFloor']
                  as Map<String, List<Map<String, dynamic>>>;

              // Ensure currentFloorSpaces is typed as List<Map<String, dynamic>>
              final currentFloorSpaces = _currentFloor != null &&
                      spacesByFloor.containsKey(_currentFloor)
                  ? List<Map<String, dynamic>>.from(
                      spacesByFloor[_currentFloor] ?? [])
                  : <Map<String, dynamic>>[];

              if (currentFloorSpaces.isEmpty) {
                return const Expanded(
                  child: Center(
                    child: Text('No parking spaces available on this floor.'),
                  ),
                );
              }

              // Group current floor spaces into wings (10 spaces per wing)
              final List<List<Map<String, dynamic>>> wings = [];
              for (var i = 0; i < currentFloorSpaces.length; i += 10) {
                wings.add(currentFloorSpaces.sublist(
                  i,
                  i + 10 > currentFloorSpaces.length
                      ? currentFloorSpaces.length
                      : i + 10,
                ));
              }

              return Expanded(
                child: Column(
                  children: [
                    // Floor navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 30),
                          onPressed: _currentFloor != null &&
                                  _floors.indexOf(_currentFloor!) <
                                      _floors.length - 1
                              ? () => _navigateFloor('up')
                              : null,
                        ),
                        Text(
                          _currentFloor?.toUpperCase() ?? 'No Floors',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 30),
                          onPressed: _currentFloor != null &&
                                  _floors.indexOf(_currentFloor!) > 0
                              ? () => _navigateFloor('down')
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Display parking spaces for current floor
                    Expanded(
                      child: InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Center(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Calculate the width of the container based on the number of wings
                                  final double containerWidth =
                                      wings.length * 320.0; // Adjust as needed
                                  return Container(
                                    width: containerWidth,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[
                                          800], // Unified background for both wings
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Entrance (top-left)
                                        const Positioned(
                                          top: 0,
                                          left: 0,
                                          child: Row(
                                            children: [
                                              Icon(Icons.arrow_downward,
                                                  color: Color.fromARGB(255, 67, 230, 62)),
                                              SizedBox(width: 4),
                                              Text(
                                                'ENTRANCE',
                                                style: TextStyle(
                                                  color: Color.fromARGB(255, 67, 230, 62),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Exit (bottom-right)
                                        const Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Row(
                                            children: [
                                              Text(
                                                'EXIT',
                                                style:  TextStyle(
                                                  color: Color.fromARGB(255, 209, 45, 45),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                               SizedBox(width: 4),
                                               Icon(Icons.arrow_downward,
                                                  color: Color.fromARGB(255, 209, 45, 45)),
                                            ],
                                          ),
                                        ),
                                        // Parking Wings Layout
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 32.0, bottom: 32.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: List.generate(
                                                wings.length, (index) {
                                              return ParkingWing(
                                                title:
                                                    'Wing ${String.fromCharCode(65 + index)}',
                                                spaces: wings[index],
                                                recommendedSpace:
                                                    recommendedSpace,
                                                onShowPaymentDialog: (space) =>
                                                    _handleParkingSpaceSelection(
                                                  space['parkingSpaceID'],
                                                  space['parkingType'] ==
                                                      'Premium',
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchRecommendationsAndSpaces() async {
    if (!mounted) return {};

    try {
      final parkingSpaces = await ApiService.getParkingData(widget.lotID);
      final recommendations =
          await ApiService.getRecommendations(widget.user.userID, widget.lotID);
      final locationType = await ApiService.getLocationType(widget.lotID);

      print('Parking Spaces: $parkingSpaces'); // Debug print
      print('Recommendations: $recommendations'); // Debug print
      print('Location Type: $locationType'); // Debug print

      // Organize parking spaces by floor
      Map<String, List<Map<String, dynamic>>> spacesByFloor = {};
      Set<String> floors = {};

      // Extract unique floors and organize spaces
      for (var space in parkingSpaces) {
        String? floorName =
            space['coordinates']?.toString().toLowerCase().split('|').first;
        if (floorName == null ||
            !(floorName.startsWith('floor') || floorName.startsWith('level'))) {
          floorName = 'Unknown'; // Fallback to a default floor name
        }
        if (!spacesByFloor.containsKey(floorName)) {
          spacesByFloor[floorName] = [];
          floors.add(floorName);
        }
        spacesByFloor[floorName]!.add(space);
      }

      print('Floors: $floors'); // Debug print

      // Sort floors naturally
      List<String> sortedFloors = floors.toList()
        ..sort((a, b) {
          int aNum = int.tryParse(a.split(' ').last) ?? 0;
          int bNum = int.tryParse(b.split(' ').last) ?? 0;
          return aNum.compareTo(bNum);
        });

      print('Sorted Floors: $sortedFloors'); // Debug print

      return {
        'parkingSpaces': parkingSpaces,
        'spacesByFloor': spacesByFloor,
        'floors': sortedFloors,
        'recommendedSpace': recommendations['parkingSpaceID'],
        'locationType': locationType,
      };
    } catch (e) {
      print('Error fetching recommendations: $e');
      return {};
    }
  }

  // void openGoogleMaps(String locationName) async {
  //   final Map<String, String> locationLinks = {};

  //   final url = locationLinks[locationName];
  //   if (url != null) {
  //     final Uri uri = Uri.parse(url);
  //     try {
  //       if (await canLaunchUrl(uri)) {
  //         await launchUrl(uri, mode: LaunchMode.externalApplication);
  //       } else {
  //         print('Could not launch $url');
  //       }
  //     } catch (e) {
  //       print("Error launching URL: $e");
  //     }
  //   } else {
  //     print('No URL found for location: $locationName');
  //   }
  // }

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

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black26),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
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

class ParkingWing extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> spaces;
  final String recommendedSpace;
  final Function(Map<String, dynamic>) onShowPaymentDialog;

  const ParkingWing({
    super.key,
    required this.title,
    required this.spaces,
    required this.recommendedSpace,
    required this.onShowPaymentDialog,
  });

  @override
  Widget build(BuildContext context) {
    // Split the spaces into two columns
    final int halfLength = (spaces.length / 2).ceil();
    final leftColumnSpaces =
        spaces.sublist(0, halfLength); // Left column of spaces
    final rightColumnSpaces =
        spaces.sublist(halfLength); // Right column of spaces

    return Column(
      children: [
        // Wing Title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        // Parking Spaces
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left Column (Rotated Parking Spaces)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  leftColumnSpaces.length,
                  (index) => RotatedBox(
                    quarterTurns: 1, // Rotate 90 degrees clockwise
                    child: ParkingSpace(
                      space: leftColumnSpaces[index],
                      isRecommended: leftColumnSpaces[index]
                              ['parkingSpaceID'] ==
                          recommendedSpace,
                      onShowPaymentDialog: () =>
                          onShowPaymentDialog(leftColumnSpaces[index]),
                    ),
                  ),
                ),
              ),
              // Vertical Divider (White Line)
              Container(
                width: 8,
                color: Colors.white,
              ),
              // Right Column (Rotated Parking Spaces)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  rightColumnSpaces.length,
                  (index) => RotatedBox(
                    quarterTurns: 1, // Rotate 90 degrees clockwise
                    child: ParkingSpace(
                      space: rightColumnSpaces[index],
                      isRecommended: rightColumnSpaces[index]
                              ['parkingSpaceID'] ==
                          recommendedSpace,
                      onShowPaymentDialog: () =>
                          onShowPaymentDialog(rightColumnSpaces[index]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    final bool isAvailable = space['isAvailable'] == true ||
        space['isAvailable'] == 1 ||
        space['isAvailable'] == '1';
    final String parkingType = space['parkingType']?.toString() ?? 'Regular';
    final String parkingSpaceID = space['parkingSpaceID'];

    bool isPremiumAndCountingDown = countdownProvider.isCountingDown &&
        countdownProvider.activeParkingSpaceID == parkingSpaceID &&
        countdownProvider.activeUserID == authProvider.user?.userID;

    Color bgColor;
    IconData? icon;
    double iconSize = 24;

    if (isPremiumAndCountingDown) {
      bgColor = Colors.orangeAccent;
      icon = Icons.timer;
      iconSize = 28;
    } else if (!isAvailable) {
      bgColor = const Color.fromARGB(255, 255, 117, 117);
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
        child: RotatedBox(
          quarterTurns: 3, // Rotates 90 degrees counterclockwise
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
      ),
    );
  }
}
