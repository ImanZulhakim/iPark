import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/models/user.dart';
import 'package:iprsr/providers/countdown_provider.dart';
import 'package:iprsr/widgets/outdoor_parking_view.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RecommendationScreen extends StatefulWidget {
  final User user;
  final String lotID;
  final String lotName;
  final bool showRecommendationPopup;

  const RecommendationScreen({
    super.key,
    required this.user,
    required this.lotID,
    required this.lotName,
    this.showRecommendationPopup = false,
  });

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  late Future<Map<String, dynamic>> recommendationsFuture;
  late CountdownProvider _providerInstance;
  Timer? _refreshTimer;
  Timer? _availabilityTimer;
  String? _currentFloor;
  List<String> _floors = [];
  bool _isGateClosed = false;
  bool _isRecommendationPopupShown =
      false; // Flag to track if the pop-up has been shown
  bool _hasShownAlternativeLocationDialog = false;

  // StreamController for individual parking space updates
  final StreamController<List<Map<String, dynamic>>> _parkingSpaceController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Initialize Flutter Local Notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _providerInstance = Provider.of<CountdownProvider>(context, listen: false);
    recommendationsFuture = fetchRecommendationsAndSpaces();

    // Emit an empty list to avoid showing "occupied" initially
    _parkingSpaceController.add([]);

    recommendationsFuture.then((data) {
      if (data['parkingSpaces'] != null) {
        _parkingSpaceController
            .add(data['parkingSpaces']); // Emit fetched spaces
      }

      if (data['floors'] != null) {
        setState(() {
          _floors = List<String>.from(data['floors']);
          _currentFloor = _floors.isNotEmpty ? _floors.first : 'No Floors';
        });
      }

      // Show the pop-up only if the flag is true and it hasn't been shown before
      if (widget.showRecommendationPopup && !_isRecommendationPopupShown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showRecommendationPopup(data['recommendedSpace']);
        });
      }
    });

    _startRefreshTimer();
    _startAvailabilityTimer();
    _initializeLocalNotifications();
    checkAndRestoreSession();
  }

  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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

  void _startAvailabilityTimer() {
    // Cancel any existing timer
    _availabilityTimer?.cancel();

    // Perform the first refresh immediately
    fetchRecommendationsAndSpaces();

    // Set up the timer for subsequent refreshes every 5 seconds
    _availabilityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        fetchRecommendationsAndSpaces();
      }
    });
  }

  @override
  void dispose() {
    _providerInstance.removeListener(_onCountdownUpdate);
    _refreshTimer?.cancel();
    _availabilityTimer?.cancel();
    _parkingSpaceController.close();
    super.dispose();
  }

  void _onCountdownUpdate() async {
    if (!_providerInstance.isCountingDown) {
      final parkingSpaceID = _providerInstance.activeParkingSpaceID;
      if (parkingSpaceID != null) {
        await ApiService.unlockParkingSpace(parkingSpaceID);
      }

      setState(() {
        recommendationsFuture = fetchRecommendationsAndSpaces();
      });

      final locationType = await ApiService.getLocationType(widget.lotID);
      print('Location type received: $locationType');
    }
  }

  void _handleOpenGate() async {
    // Check if the app is in dark mode
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Show a confirmation dialog to the user
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          'Open Gate Early',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to open the gate early?',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
            ),
          ),
          // Confirm button
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    // If the user cancels, exit the function
    if (confirm != true) return;

    // Attempt to open the gate
    final success = await ApiService.safeControlGate('open');

    // Handle the result of the gate opening attempt
    if (success) {
      // Update the state to reflect the gate is open
      setState(() {
        _isGateClosed = false;
      });

      // Reset the countdown for premium parking
      _providerInstance.resetCountdown();

      // Cancel the premium parking expiration notification
      await flutterLocalNotificationsPlugin.cancel(1);

      // Cancel the premium parking expiration timer
      _premiumParkingExpirationTimer?.cancel();

      // Show a notification confirming the gate was opened early
      await flutterLocalNotificationsPlugin.show(
        2,
        'Gate Opened Early',
        'Your premium parking session has ended early as the gate was opened.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'premium_parking_channel',
            'Premium Parking Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );

      // Show a snackbar to confirm the gate was opened
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gate opened successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show a snackbar if the gate failed to open
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open gate. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRecommendationPopup(String recommendedSpaceID) {
    if (_isRecommendationPopupShown) return; // Do not show if already shown

    showDialog(
      context: context,
      builder: (context) {
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor:
              isDarkMode ? const Color.fromARGB(255, 74, 74, 74) : Colors.white,
          title: Text(
            "Recommended Parking Space",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            "Your recommended parking space is: $recommendedSpaceID",
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _isRecommendationPopupShown = true; // Mark as shown
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    final countdownProvider = Provider.of<CountdownProvider>(context);
    final bool hasActiveSession = countdownProvider.isCountingDown &&
        countdownProvider.activeUserID == widget.user.userID;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<CountdownProvider>(
          builder: (context, provider, child) {
            return FutureBuilder<Map<String, dynamic>>(
              future: recommendationsFuture,
              builder: (context, snapshot) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Parking Recommendations for ${widget.lotName}',
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
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 4,
                  color: Colors.white,
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
                            _buildLegendItem('Female', const Color(0xFFF48FB1),
                                Icons.female),
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
                            _buildLegendItem(
                                'Recommended', Colors.green, Icons.thumb_up),
                            _buildLegendItem(
                                'Occupied', Colors.red, Icons.block),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                    } else if (!snapshot.hasData ||
                        snapshot.data!['parkingSpaces'] == null) {
                      return const Center(
                          child: Text('No parking spaces available.'));
                    }

                    final locationType =
                        snapshot.data?['locationType'] ?? 'indoor';
                    final parkingSpaces = snapshot.data!['parkingSpaces']
                        as List<Map<String, dynamic>>;
                    final String recommendedSpace =
                        snapshot.data!['recommendedSpace'] as String;

                    if (locationType.toLowerCase() == 'outdoor') {
                      return OutdoorParkingView(
                        parkingSpaces: parkingSpaces,
                        recommendedSpace: recommendedSpace,
                        lotID:
                            snapshot.data!['currentLocation'] ?? widget.lotID,
                      );
                    }

                    final spacesByFloor = snapshot.data!['spacesByFloor']
                        as Map<String, List<Map<String, dynamic>>>;

                    final currentFloorSpaces = _currentFloor != null &&
                            spacesByFloor.containsKey(_currentFloor)
                        ? List<Map<String, dynamic>>.from(
                            spacesByFloor[_currentFloor] ?? [])
                        : <Map<String, dynamic>>[];

                    if (currentFloorSpaces.isEmpty) {
                      return const Center(
                          child: Text(
                              'No parking spaces available on this floor.'));
                    }

                    final List<List<Map<String, dynamic>>> wings = [];
                    for (var i = 0; i < currentFloorSpaces.length; i += 10) {
                      wings.add(currentFloorSpaces.sublist(
                        i,
                        i + 10 > currentFloorSpaces.length
                            ? currentFloorSpaces.length
                            : i + 10,
                      ));
                    }

                    return Column(
                      children: [
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
                        Expanded(
                          child: InteractiveViewer(
                            boundaryMargin:
                                const EdgeInsets.all(double.infinity),
                            minScale: 0.5,
                            maxScale: 3.0,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Center(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final double containerWidth =
                                          wings.length * 320.0;
                                      return Container(
                                        width: containerWidth,
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                                            const Positioned(
                                              top: 0,
                                              left: 0,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.arrow_downward,
                                                      color: Color.fromARGB(
                                                          255, 67, 230, 62)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'ENTRANCE',
                                                    style: TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 67, 230, 62),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'EXIT',
                                                    style: TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 209, 45, 45),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Icon(Icons.arrow_downward,
                                                      color: Color.fromARGB(
                                                          255, 209, 45, 45)),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 32.0, bottom: 32.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
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
                                                    stream:
                                                        _parkingSpaceController
                                                            .stream,
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
                    );
                  },
                ),
              ),
            ],
          ),
          if (hasActiveSession && _isGateClosed)
            Positioned(
              left: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _handleOpenGate,
                backgroundColor: Colors.orange,
                child: const Icon(Icons.lock_open, color: Colors.white),
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
                final locationType = snapshot.data!['locationType'] as String;

                if (locationType.toLowerCase() == 'indoor') {
                  // Handle indoor parking
                  _navigateToParkingLot(widget.lotID);
                } else {
                  // Handle outdoor parking
                  final parkingSpaces = snapshot.data!['parkingSpaces']
                      as List<Map<String, dynamic>>;
                  final recommendedSpaceId =
                      snapshot.data!['recommendedSpace'] as String;

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
                    }
                  }
                }
              }
            },
            backgroundColor:
                theme.floatingActionButtonTheme.backgroundColor ?? Colors.teal,
            child: const Icon(Icons.navigation, color: Colors.white),
          );
        },
      ),
    );
  }

  //For indoor navigation
  void _navigateToParkingLot(String lotID) async {
    final coordinates =
        await ApiService.getSpecificParkingLotCoordinates(lotID);
    if (coordinates != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${coordinates.latitude},${coordinates.longitude}';
      launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parking lot coordinates not available.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> fetchRecommendationsAndSpaces() async {
  if (!mounted) return {};

  try {
    // Fetch the parking spaces for the current lot
    final parkingSpaces = await ApiService.getParkingData(widget.lotID);
    print('Fetched Parking Spaces: $parkingSpaces');

    // Emit initial parking spaces immediately to avoid "occupied" default state
    _parkingSpaceController.add(parkingSpaces);

    // Fetch recommendations for the user and current lot
    final recommendations = await ApiService.getRecommendations(widget.user.userID, widget.lotID);
    print('Fetched Recommendations: $recommendations');

    // Fetch the location type (e.g., indoor/outdoor)
    final locationType = await ApiService.getLocationType(widget.lotID);
    print('Location Type: $locationType');

    // Emit updated parking spaces after fetching recommendations
    _parkingSpaceController.add(parkingSpaces);

    // Check if an alternative location is needed (e.g., original location is full)
    if (recommendations['alternativeLocation'] != null && !_hasShownAlternativeLocationDialog) {
      final altParkingSpaces = await ApiService.getParkingData(
          recommendations['alternativeLocation']);
      final altLocationType = await ApiService.getLocationType(
          recommendations['alternativeLocation']);

      recommendations['parkingSpaces'] = altParkingSpaces;
      recommendations['locationType'] = altLocationType;
      recommendations['currentLocation'] =
          recommendations['alternativeLocation'];

      // Emit updated parking spaces for the alternative location
      _parkingSpaceController.add(altParkingSpaces);

      // Show a snackbar message for the alternative location
      if (mounted && !_hasShownAlternativeLocationDialog) {
        _hasShownAlternativeLocationDialog = true; // Ensure it shows only once
        final snackBar = SnackBar(
          content: Text(
            "Original location full. Found parking at: ${recommendations['alternativeLocation']}",
            style: const TextStyle(
              color: Colors.black, // Black text
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 237, 181, 95), // Light orange background
          duration: const Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      // Keep the current parking spaces and location if no alternative is needed
      recommendations['parkingSpaces'] = parkingSpaces;
      recommendations['locationType'] = locationType;
      recommendations['currentLocation'] = widget.lotID;
    }

    // Organize parking spaces by floor
    Map<String, List<Map<String, dynamic>>> spacesByFloor = {};
    Set<String> floors = {};

    for (var space in recommendations['parkingSpaces']) {
      // Extract the floor name from the space's coordinates
      String? floorName =
          space['coordinates']?.toString().toLowerCase().split('|').first;
      if (floorName == null ||
          !(floorName.startsWith('floor') || floorName.startsWith('level'))) {
        floorName = 'Unknown';
      }
      if (!spacesByFloor.containsKey(floorName)) {
        spacesByFloor[floorName] = [];
        floors.add(floorName);
      }
      spacesByFloor[floorName]!.add(space);
    }

    // Sort floors in ascending order (numerically or alphabetically)
    List<String> sortedFloors = floors.toList()
      ..sort((a, b) {
        int aNum = int.tryParse(a.split(' ').last) ?? 0;
        int bNum = int.tryParse(b.split(' ').last) ?? 0;
        return aNum.compareTo(bNum);
      });

    // Update state with the sorted floors and the current floor
    if (mounted) {
      setState(() {
        _floors = sortedFloors;
        _currentFloor = _floors.isNotEmpty ? _floors.first : 'No Floors';
      });
    }

    // Return the complete recommendations data
    return {
      'parkingSpaces': recommendations['parkingSpaces'],
      'spacesByFloor': spacesByFloor,
      'floors': sortedFloors,
      'recommendedSpace': recommendations['parkingSpaceID'],
      'locationType': recommendations['locationType'],
      'currentLocation': recommendations['currentLocation'],
    };
  } catch (e) {
    // Handle errors by logging and returning an empty map
    print('Error fetching recommendations: $e');
    return {};
  }
}


  Timer? _premiumParkingExpirationTimer;

  void _handlePremiumParking(String parkingSpaceID) async {
    try {
      print('Starting premium parking process for space: $parkingSpaceID');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final bool isEsp8266Connected = await ApiService.isEsp8266Available();
      if (!isEsp8266Connected) {
        throw Exception(
            'Gate control system is not accessible. Please try again later.');
      }

      print('Calling API to create premium parking');

      bool success = await ApiService.createPremiumParking(
        parkingSpaceID,
        widget.user.userID,
      );

      print('API response success: $success');

      if (mounted) {
        Navigator.pop(context);
      }

      if (success) {
        print('Premium parking activated successfully');

        _providerInstance.startCountdown(5, parkingSpaceID, widget.user.userID);

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
          } else {
            setState(() {
              _isGateClosed = true;
            });
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium parking activated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        await flutterLocalNotificationsPlugin.show(
          0,
          'Premium Parking Activated',
          'Your premium parking spot $parkingSpaceID has been activated.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'premium_parking_channel',
              'Premium Parking Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );

        // Store the timer in a variable
        _premiumParkingExpirationTimer =
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
            } else {
              setState(() {
                _isGateClosed = false;
              });
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

          await flutterLocalNotificationsPlugin.show(
            1,
            'Premium Parking Expired',
            'Your premium parking spot $parkingSpaceID has expired.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'premium_parking_channel',
                'Premium Parking Notifications',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
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

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.black : Colors.black,
          ),
        ),
      ],
    );
  }

  void _handleParkingSpaceSelection(
      String parkingSpaceID, bool isPremium) async {
    if (isPremium) {
      // Fetch the current state of the parking space
      final parkingSpaces = await ApiService.getParkingData(widget.lotID);
      final selectedSpace = parkingSpaces.firstWhere(
        (space) => space['parkingSpaceID'] == parkingSpaceID,
        orElse: () => {'isAvailable': false},
      );

      // Check if the space is available
      final bool isAvailable = selectedSpace['isAvailable'] == true ||
          selectedSpace['isAvailable'] == 1 ||
          selectedSpace['isAvailable'] == '1';

      if (isAvailable) {
        // Show the premium payment dialog only if the space is available
        _showPaymentDialog(context, parkingSpaceID);
      } else {
        // Show a message if the space is occupied
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This premium parking space is currently occupied.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Handle regular parking
    }
  }

  void _showPaymentDialog(BuildContext context, String parkingSpaceID) {
    showDialog(
      context: context,
      builder: (context) {
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            "Premium Parking",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            "This is a premium parking spot. Proceed with payment?",
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handlePremiumParking(parkingSpaceID);
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
    final activeSession =
        await ApiService.checkPremiumParkingStatus(widget.user.userID);

    if (activeSession != null) {
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
      // Reset the flag when explicitly requesting recommendations
      _isRecommendationPopupShown = false;

      final recommendations = await fetchRecommendationsAndSpaces();

      if (mounted) {
        setState(() {
          recommendationsFuture = Future.value(recommendations);
        });

        // Show the pop-up if there's a recommended space
        if (recommendations['recommendedSpace'] != null) {
          _showRecommendationPopup(recommendations['recommendedSpace']);
        }
      }
    }
  }

  Future<void> checkAndRestoreSession() async {
    final activeSession =
        await ApiService.checkPremiumParkingStatus(widget.user.userID);

    if (activeSession != null && activeSession['remaining_time'] > 0) {
      _providerInstance.restoreCountdown(
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
  final Stream<List<Map<String, dynamic>>> stream;

  const ParkingWing({
    super.key,
    required this.title,
    required this.spaces,
    required this.recommendedSpace,
    required this.onShowPaymentDialog,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    final int halfLength = (spaces.length / 2).ceil();
    final leftColumnSpaces = spaces.sublist(0, halfLength);
    final rightColumnSpaces = spaces.sublist(halfLength).reversed.toList();

    return Column(
      children: [
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  leftColumnSpaces.length,
                  (index) => RotatedBox(
                    quarterTurns: 1,
                    child: ParkingSpace(
                      parkingSpaceID: leftColumnSpaces[index]['parkingSpaceID'],
                      stream: stream,
                      isRecommended: leftColumnSpaces[index]
                              ['parkingSpaceID'] ==
                          recommendedSpace,
                      onShowPaymentDialog: () =>
                          onShowPaymentDialog(leftColumnSpaces[index]),
                    ),
                  ),
                ),
              ),
              Container(
                width: 8,
                color: Colors.white,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  rightColumnSpaces.length,
                  (index) => RotatedBox(
                    quarterTurns: 1,
                    child: ParkingSpace(
                      parkingSpaceID: rightColumnSpaces[index]
                          ['parkingSpaceID'],
                      stream: stream,
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
  final String parkingSpaceID;
  final Stream<List<Map<String, dynamic>>> stream;
  final bool isRecommended;
  final VoidCallback onShowPaymentDialog;

  const ParkingSpace({
    super.key,
    required this.parkingSpaceID,
    required this.stream,
    required this.isRecommended,
    required this.onShowPaymentDialog,
  });

  @override
  Widget build(BuildContext context) {
    final countdownProvider = Provider.of<CountdownProvider>(context);
    final authProvider = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        // Show a loading indicator until the first data arrives
        if (!snapshot.hasData) {
          return Container(
            width: 60,
            height: 100,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.black12,
                width: 1,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black54,
              ),
            ),
          );
        }

        // Extract the list of parking spaces from the snapshot
        final List<Map<String, dynamic>> parkingSpaces = snapshot.data!;

        // Find the specific parking space using its ID
        final space = parkingSpaces.firstWhere(
          (s) => s['parkingSpaceID'] == parkingSpaceID,
          orElse: () => {
            'parkingSpaceID': parkingSpaceID,
            'isAvailable': false,
            'parkingType': 'Regular',
          },
        );

        // Extract properties from the parking space
        final bool isAvailable = space['isAvailable'] == true ||
            space['isAvailable'] == 1 ||
            space['isAvailable'] == '1';
        final String parkingType =
            space['parkingType']?.toString() ?? 'Regular';

        // Check if the parking space is in premium mode and counting down
        bool isPremiumAndCountingDown = countdownProvider.isCountingDown &&
            countdownProvider.activeParkingSpaceID == parkingSpaceID &&
            countdownProvider.activeUserID == authProvider.user?.userID;

        // Determine background color and icon for the parking space
        Color bgColor;
        IconData? icon;
        double iconSize = 24;

        if (isPremiumAndCountingDown) {
          bgColor = Colors.orangeAccent;
          icon = Icons.timer;
          iconSize = 28;
        } else if (!isAvailable) {
          bgColor = Colors.red;
          icon = Icons.block; // Block icon for occupied spaces
          iconSize = 28;
        } else if (isRecommended) {
          bgColor = Colors.greenAccent;
          icon = Icons.thumb_up;
        } else {
          // Handle different parking types
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

        // Build the parking space UI
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
              quarterTurns: 3,
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
                  else
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
      },
    );
  }
}
