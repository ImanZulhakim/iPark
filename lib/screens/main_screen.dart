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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tap for Recommendation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                print('Parking button tapped');
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecommendationScreen(user: user), // Use the user object
                    ),
                  );
                } else {
                  print('User is not logged in');
                }
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.pinkAccent, Colors.cyanAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'P',
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Floating action button tapped');
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.person, color: Colors.pinkAccent),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                if (userId != null) {
                  // Fetch the latest vehicle details and parking preferences from the API
                  print('Fetching vehicle details for userID: $userId'); // Debug log
                  final fetchedData = await ApiService.fetchVehicleDetailsAndParkingPreferences(userId);
                  print('Fetched vehicle details: $fetchedData');

                  if (fetchedData != null) {
                    final fetchedBrand = fetchedData['data']['brand'];
                    final fetchedType = fetchedData['data']['type'];
                    final fetchedN = fetchedData['data']['isNearest'];
                    print('Should be 1: $fetchedN');
                    final Map<String, bool> parkingPreferences = {
                      'isNearest': fetchedData['data']['isNearest'] == 1 ? true : false,
                      'isCovered': fetchedData['data']['isCovered'] == 1 ? true : false,
                      'requiresLargeSpace': fetchedData['data']['requiresLargeSpace'] == 1 ? true : false,
                      'requiresWellLitArea': fetchedData['data']['requiresWellLitArea'] == 1 ? true : false,
                      'requiresEVCharging': fetchedData['data']['requiresEVCharging'] == 1 ? true : false,
                      'requiresWheelchairAccess': fetchedData['data']['requiresWheelchairAccess'] == 1 ? true : false,
                      'requiresFamilyParkingArea': fetchedData['data']['requiresFamilyParkingArea'] == 1 ? true : false,
                      'premiumParking': fetchedData['data']['premiumParking'] == 1 ? true : false,
                    };


                      print('Parking preferences: $parkingPreferences');

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditVehicleDetailsScreen(
                          userID: userId, // Use the userId from the user object
                          initialBrand: fetchedBrand,
                          initialType: fetchedType,
                          initialPreferences: parkingPreferences, // Pass the preferences
                        ),
                      ),
                    );

                    if (result != null) {
                      String updatedBrand = result['brand'];
                      String updatedType = result['type'];

                      await Provider.of<AuthService>(context, listen: false).updateUser(
                        brand: updatedBrand,
                        type: updatedType,
                      );
                    }
                  } else {
                    print('Failed to fetch vehicle details or preferences from the server.');
                  }
                } else {
                  print('User ID is null');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
