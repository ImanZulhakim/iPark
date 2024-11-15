import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/settings_screen.dart';
import 'package:iprsr/screens/edit_vehicle_details_screen.dart';
import 'package:iprsr/services/api_service.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final String? userId;
  final VoidCallback? onFloatingActionButtonPressed;

  const CustomBottomNavigationBar({
    super.key, 
    required this.userId,
    this.onFloatingActionButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900] // Dark theme
          : const Color(0xFF0077B6), // Blue theme
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
                  final fetchedData = await ApiService.fetchVehicleDetailsAndParkingPreferences(userId!);
                  
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
                          userID: userId!,
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
                        userID: userId!,
                        vehicleBrand: updatedBrand,
                        vehicleType: updatedType,
                        preferences: {},
                      );
                    }
                  }
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
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      color: Colors.white,
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
                  const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 28,
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
