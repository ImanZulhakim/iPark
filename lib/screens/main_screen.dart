import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/providers/tutorial_provider.dart';
import 'package:iprsr/providers/location_provider.dart'; // Import LocationProvider
import 'package:iprsr/providers/countdown_provider.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/edit_vehicle_details_screen.dart';
import 'package:iprsr/screens/recommendation_screen.dart';
import 'package:iprsr/screens/parking_location_screen.dart';
import 'package:iprsr/screens/settings_screen.dart';
import 'package:iprsr/widgets/tutorial_overlay.dart';
import 'package:iprsr/screens/parking_map_screen.dart';

class MainScreen extends StatefulWidget {
  final bool showTutorial;

  const MainScreen({
    super.key,
    this.showTutorial = false,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();

    // Handle tutorial logic
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
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
    final locationProvider = Provider.of<LocationProvider>(context);
    final countdownProvider = Provider.of<CountdownProvider>(context);
    final remainingTime = countdownProvider.remainingTime;
    final user = Provider.of<AuthService>(context).user;
    final String? userId = user?.userID;

    bool isCountdownVisible = countdownProvider.isCountingDown &&
        countdownProvider.activeUserID == userId;

    // Get the selected location from the LocationProvider
    final selectedLotID = locationProvider.selectedLocation?['lotID'] ?? 'DefaultLotID';
    final selectedLotName = locationProvider.selectedLocation?['lotName'] ?? 'DefaultLotName';

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
                      selectedLotName,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    AnimatedButton(
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
                            locationProvider.selectLocation({
                              'lotID': result['lotID'],
                              'lot_name': result['lot_name'],
                            });
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
                        lotName: selectedLotName,
                        showRecommendationPopup: true,
                      ),
                    ),
                  );
                }),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Define the text style
                    final textStyle = TextStyle(
                      fontSize: 140,
                      fontFamily: 'Satisfy',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color.fromARGB(255, 7, 230, 174)
                          : const Color(0xFF0077B6),
                    );

                    // Create a TextSpan for the text
                    final textSpan = TextSpan(
                      text: 'P',
                      style: textStyle,
                    );

                    // Use TextPainter to calculate the text size
                    final textPainter = TextPainter(
                      text: textSpan,
                      textDirection: TextDirection.ltr,
                    )..layout(minWidth: 0, maxWidth: constraints.maxWidth);

                    // Calculate the size of the text
                    final textWidth = textPainter.width;
                    final textHeight = textPainter.height;

                    return Container(
                      width: textWidth + 120, // Add padding
                      height: textHeight + 40, // Add padding
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
                          style: textStyle,
                        ),
                      ),
                    );
                  },
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
              AnimatedButton(
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
              AnimatedButton(
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

class AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const AnimatedButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _controller.reverse,
      child: ScaleTransition(
        scale: _animation,
        child: widget.child,
      ),
    );
  }
}