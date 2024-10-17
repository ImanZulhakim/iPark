import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/edit_vehicle_details_screen.dart';
import 'package:iprsr/screens/recommendation_screen.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    // Retrieve the user ID directly from the user object
    final String? userId = user?.userID;

    if (userId == null) {
      print('Error: User ID is null'); // Log if userID is null
    } else {
      print('User ID in main: $userId'); // Log the userID for debugging
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 245, 107, 153),
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
            children: [
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
                        builder: (context) => RecommendationScreen(user: user),
                      ),
                    );
                  } else {
                    print('User is not logged in');
                  }
                },
                child: Container(
                  width: 200, // Adjust width if necessary
                  height: 200, // Adjust height if necessary
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
                            fontSize: constraints.maxHeight *
                                0.7, // Dynamically adjust the font size
                            fontFamily: 'Satisfy',
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 198, 154, 169),
                                  Color.fromARGB(255, 103, 207, 207)
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(Rect.fromLTWH(0.0, 0.0,
                                  constraints.maxWidth, constraints.maxHeight)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
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
              Color.fromARGB(255, 245, 107, 153),
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
          elevation: 0, // Remove elevation to avoid shadow over gradient
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
                    final fetchedData = await ApiService
                        .fetchVehicleDetailsAndParkingPreferences(userId);
                    print('Fetched vehicle details: $fetchedData');

                    if (fetchedData != null) {
                      final fetchedBrand = fetchedData['data']['brand'];
                      final fetchedType = fetchedData['data']['type'];
                      final Map<String, bool> parkingPreferences = {
                        'isNearest': fetchedData['data']['isNearest'] == 1
                            ? true
                            : false,
                        'isCovered': fetchedData['data']['isCovered'] == 1
                            ? true
                            : false,
                        'requiresLargeSpace':
                            fetchedData['data']['requiresLargeSpace'] == 1
                                ? true
                                : false,
                        'requiresWellLitArea':
                            fetchedData['data']['requiresWellLitArea'] == 1
                                ? true
                                : false,
                        'requiresEVCharging':
                            fetchedData['data']['requiresEVCharging'] == 1
                                ? true
                                : false,
                        'requiresWheelchairAccess':
                            fetchedData['data']['requiresWheelchairAccess'] == 1
                                ? true
                                : false,
                        'requiresFamilyParkingArea': fetchedData['data']
                                    ['requiresFamilyParkingArea'] ==
                                1
                            ? true
                            : false,
                        'premiumParking':
                            fetchedData['data']['premiumParking'] == 1
                                ? true
                                : false,
                      };

                      print('Parking preferences: $parkingPreferences');

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditVehicleDetailsScreen(
                            userID:
                                userId, // Use the userId from the user object
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
                          userID: userId, // Pass the userID
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
