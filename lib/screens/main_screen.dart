import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/edit_vehicle_details_screen.dart';
import 'package:iprsr/screens/recommendation_screen.dart';
import 'package:iprsr/screens/parking_location_screen.dart';

class MainScreen extends StatefulWidget {
  final String selectedLocation;

  MainScreen({required this.selectedLocation});

  @override
  _MainScreenState createState() => _MainScreenState();
} 

class _MainScreenState extends State<MainScreen> {
  late String selectedLocation;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.selectedLocation; // Initialize with the value passed to MainScreen
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    // Retrieve the user ID directly from the user object
    final String? userId = user?.userID;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 211, 136, 161),
              Color.fromARGB(255, 240, 241, 241),
              Color.fromARGB(255, 131, 245, 245)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                            builder: (context) => ParkingLocationScreen(),
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
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 211, 136, 161),
                              Color.fromARGB(255, 131, 245, 245),
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
              const Text(
                'Tap for Recommendation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
                              ..shader = const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 198, 154, 169),
                                  Color.fromARGB(255, 103, 207, 207),
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
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 211, 136, 161),
              Color.fromARGB(255, 131, 245, 245),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FloatingActionButton(
          onPressed: () {
            print('Floating action button tapped');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Text(
            'P',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              fontFamily: 'Satisfy',
              color: Colors.white,
            ),
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
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, color: Colors.black54, size: 28),
                    Text(
                      'Preferences',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Provider.of<AuthService>(context, listen: false).logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, color: Colors.black54, size: 28),
                    Text(
                      'Log out',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
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
