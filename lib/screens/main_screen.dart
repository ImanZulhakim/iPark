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
import 'package:iprsr/screens/parking_map_screen.dart';

class MainScreen extends StatefulWidget {
  final Map<String, String> selectedLocation;
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
  late String selectedLotID;
  late String selectedLotName;

  @override
  void initState() {
    super.initState();
    selectedLotID = widget.selectedLocation['lotID'] ?? 'Unknown Lot ID';
    selectedLotName = widget.selectedLocation['lot_name'] ?? 'Unknown Lot Name';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final tutorialProvider =
          Provider.of<TutorialProvider>(context, listen: false);
      await tutorialProvider.checkTutorialStatus();

      if (mounted &&
          (tutorialProvider.isManualTutorial ||
              (widget.showTutorial && !tutorialProvider.hasShownTutorial))) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TutorialOverlay(parentContext: context),
        );

        if (tutorialProvider.isManualTutorial) {
          tutorialProvider.setManualTutorial(false);
        }

        await tutorialProvider.markTutorialAsShown();
      }
    });
  }

  void _showSnackBar(String message,
      {Color backgroundColor = Colors.green, Duration? duration}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration ?? Duration(seconds: (message.length / 20).ceil()),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _ensureLoggedIn(VoidCallback onLoggedIn) {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      onLoggedIn();
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Not Logged In"),
          content: const Text("You must be logged in to proceed."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final countdownProvider = Provider.of<CountdownProvider>(context);
    final remainingTime = countdownProvider.remainingTime;
    final user = Provider.of<AuthService>(context).user;
    final String? userId = user?.userID;

    bool isCountdownVisible = countdownProvider.isCountingDown &&
        countdownProvider.activeUserID == userId;

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      selectedLotName,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParkingLocationScreen(
                              lotID: selectedLotID,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            selectedLotID = result['lotID'];
                            selectedLotName = result['lot_name'];
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const LinearGradient(
                                      colors: [
                                        Colors.teal,
                                        Colors.tealAccent,
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF00B4D8),
                                        Color(0xFF0077B6),
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
                onTap: () => _ensureLoggedIn(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecommendationScreen(
                        user: user!,
                        lotID: selectedLotID,
                        lot_name: selectedLotName,
                      ),
                    ),
                  );
                }),
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
                  child: Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        fontSize: 140,
                        fontFamily: 'Satisfy',
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.tealAccent
                            : Color(0xFF0077B6),
                      ),
                    ),
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
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColorDark,
            ],
          ),
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ParkingMapScreen(
                  lotID: selectedLotID,
                ),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.map_outlined,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  if (userId != null) {
                    print('Fetching vehicle details for userID: $userId');
                    final fetchedData = await ApiService
                        .fetchVehicleDetailsAndParkingPreferences(userId);
                    print('Fetched vehicle details: $fetchedData');

                    if (fetchedData != null) {
                      final fetchedBrand = fetchedData['data']['brand'];
                      final fetchedType = fetchedData['data']['type'];
                      final fetchedCategory = fetchedData['data']['category'];
                      final Map<String, bool> parkingPreferences = {
                        'isNearest': fetchedData['data']['isNearest'] == 1,
                        'isCovered': fetchedData['data']['isCovered'] == 1,
                        'requiresLargeSpace':
                            fetchedData['data']['requiresLargeSpace'] == 1,
                        'requiresWellLitArea':
                            fetchedData['data']['requiresWellLitArea'] == 1,
                        'requiresEVCharging':
                            fetchedData['data']['requiresEVCharging'] == 1,
                        'requiresWheelchairAccess': fetchedData['data']
                                ['requiresWheelchairAccess'] ==
                            1,
                        'requiresFamilyParkingArea': fetchedData['data']
                                ['requiresFamilyParkingArea'] ==
                            1,
                        'premiumParking':
                            fetchedData['data']['premiumParking'] == 1,
                      };

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditVehicleDetailsScreen(
                            userID: userId,
                            initialBrand: fetchedBrand,
                            initialType: fetchedType,
                            initialCategory: fetchedCategory,
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
                      print(
                          'Failed to fetch vehicle details or preferences from the server.');
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
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     Icon(Icons.settings, color: Colors.white, size: 28),
                     Text(
                      'Settings',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
