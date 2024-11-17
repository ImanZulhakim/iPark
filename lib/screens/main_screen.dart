import 'package:flutter/material.dart';
import 'package:iprsr/providers/tutorial_provider.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/edit_vehicle_details_screen.dart';
import 'package:iprsr/screens/recommendation_screen.dart';
import 'package:iprsr/screens/parking_location_screen.dart';
import 'package:iprsr/providers/countdown_provider.dart';
import 'package:iprsr/screens/settings_screen.dart';
import 'package:iprsr/widgets/tutorial_overlay.dart';

class MainScreen extends StatefulWidget {
  final String selectedLocation;
  final bool showTutorial;

  const MainScreen({
    super.key, 
    required this.selectedLocation,
    this.showTutorial = false,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late String selectedLocation;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.selectedLocation;
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
      await tutorialProvider.checkTutorialStatus();
      
      // Show tutorial if either:
      // 1. It's a manual tutorial request (from settings)
      // 2. It's a first-time user (showTutorial true and hasn't shown before)
      if (mounted && (tutorialProvider.isManualTutorial || 
          (widget.showTutorial && !tutorialProvider.hasShownTutorial))) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TutorialOverlay(parentContext: context),
        );
        
        // Reset manual tutorial flag after showing
        if (tutorialProvider.isManualTutorial) {
          tutorialProvider.setManualTutorial(false);
        }
        
        await tutorialProvider.markTutorialAsShown();
      }
    });
  }

  void _showSuccessSnackBar() {
    final snackBar = SnackBar(
      content: const Text('Registration successful!'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _onRegistrationSuccess() {
    _showSuccessSnackBar();
    // Additional logic for successful registration
  }

  @override
  Widget build(BuildContext context) {
    final countdownProvider = Provider.of<CountdownProvider>(context);
    final remainingTime = countdownProvider.remainingTime;
    final user = Provider.of<AuthService>(context).user;
    final String? userId = user?.userID;

    // Determine if the countdown should be visible to the current user
    bool isCountdownVisible = countdownProvider.isCountingDown &&
        countdownProvider.activeUserID == userId; // Check if the user IDs match

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.black87),
                    const SizedBox(width: 8),
                    Text(
                      selectedLocation,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParkingLocationScreen(
                              selectedLocation: selectedLocation,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            selectedLocation = result;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? const LinearGradient(
                                  colors: [
                                    Colors.teal,
                                    Colors.tealAccent,
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF00B4D8), // Lighter blue
                                    Color(0xFF0077B6), // Darker blue
                                  ],
                                ),
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Tap for Recommendation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              // Display the countdown timer only for the user who paid for it
              if (isCountdownVisible)
                Text(
                  'Time Remaining: ${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  print('Parking button tapped');
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecommendationScreen(
                          user: user,
                          location: selectedLocation,
                        ),
                      ),
                    );
                  } else {
                    print('User is not logged in');
                  }
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: Text(
                          'P',
                          style: TextStyle(
                            fontSize: constraints.maxHeight * 0.7,
                            fontFamily: 'Satisfy',
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: Theme.of(context).brightness == Brightness.dark
                                    ? const [
                                        Colors.teal,
                                        Colors.tealAccent,
                                      ]
                                    : const [
                                        Color(0xFF00B4D8), // Turquoise blue
                                        Color(0xFF0077B6), // Darker blue
                                      ],
                                stops: const [
                                  0.2,
                                  0.8
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(Rect.fromLTWH(
                                0.0,
                                0.0,
                                constraints.maxWidth,
                                constraints.maxHeight,
                              )),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 80.0,
        height: 80.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(
                  colors: [
                    Colors.teal,
                    Colors.tealAccent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    const Color(0xFF00B4D8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to the main screen or perform the intended action
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen(selectedLocation: selectedLocation),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Text(
            'P',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              fontFamily: 'Satisfy',
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.white,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          bottomAppBarTheme: BottomAppBarTheme(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900] // Dark theme
                : const Color(0xFF0077B6), // Blue theme
          ),
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                GestureDetector(
                  onTap: () async {
                    if (userId != null) {
                      print('Fetching vehicle details for userID: $userId');
                      final fetchedData = await ApiService.fetchVehicleDetailsAndParkingPreferences(userId);
                      print('Fetched vehicle details: $fetchedData');

                      if (fetchedData != null) {
                        final fetchedBrand = fetchedData['data']['brand'];
                        final fetchedType = fetchedData['data']['type'];
                        final Map<String, bool> parkingPreferences = {
                          'isNearest': fetchedData['data']['isNearest'] == 1,
                          'isCovered': fetchedData['data']['isCovered'] == 1,
                          'requiresLargeSpace': fetchedData['data']['requiresLargeSpace'] == 1,
                          'requiresWellLitArea': fetchedData['data']['requiresWellLitArea'] == 1,
                          'requiresEVCharging': fetchedData['data']['requiresEVCharging'] == 1,
                          'requiresWheelchairAccess': fetchedData['data']['requiresWheelchairAccess'] == 1,
                          'requiresFamilyParkingArea': fetchedData['data']['requiresFamilyParkingArea'] == 1,
                          'premiumParking': fetchedData['data']['premiumParking'] == 1,
                        };

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditVehicleDetailsScreen(
                              userID: userId,
                              initialBrand: fetchedBrand,
                              initialType: fetchedType,
                              initialPreferences: parkingPreferences,
                            ),
                          ),
                        );

                        if (result != null) {
                          String updatedBrand = result['brand'];
                          String updatedType = result['type'];

                          await Provider.of<AuthService>(context, listen: false)
                              .updateUser(
                            userID: userId,
                            vehicleBrand: updatedBrand,
                            vehicleType: updatedType,
                            preferences: {},
                          );
                        }
                      } else {
                        print('Failed to fetch vehicle details or preferences from the server.');
                      }
                    } else {
                      print('User ID is null');
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/preferences.png',
                        width: 28,
                        height: 28,
                      ),
                      Text(
                        'Preferences',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Changed to white for dark theme
                            : Colors.white,
                        size: 28,
                      ),
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white // Changed to white for dark theme
                              : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
