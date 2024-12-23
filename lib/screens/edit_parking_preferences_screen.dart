import 'package:flutter/material.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/widgets/custom_bottom_navigation_bar.dart';

class EditParkingPreferencesScreen extends StatefulWidget {
  final Map<String, bool> initialPreferences;
  final String userID;
  final String vehicleBrand;
  final String vehicleType;
  final String vehicleCategory;

  const EditParkingPreferencesScreen({
    super.key,
    required this.userID,
    required this.initialPreferences,
    required this.vehicleBrand,
    required this.vehicleType,
    required this.vehicleCategory,
  });

  @override
  _ParkingPreferencesEditScreenState createState() =>
      _ParkingPreferencesEditScreenState();
}

class _ParkingPreferencesEditScreenState
    extends State<EditParkingPreferencesScreen> {
  late Map<String, bool> preferences;

  final Map<String, String> preferenceLabels = {
    'isNearest': 'Nearest to Destination',
    'isCovered': 'Covered Parking',
    'requiresWheelchairAccess': 'Wheelchair Access',
    'requiresLargeSpace': 'Large Space',
    'requiresWellLitArea': 'Well-Lit Area',
    'requiresEVCharging': 'EV Charging',
    'requiresFamilyParkingArea': 'Family Parking Area',
    'premiumParking': 'Premium Parking',
  };

  @override
  void initState() {
    super.initState();
    preferences = Map<String, bool>.from(widget.initialPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Navigator.of(context).popUntil((route) => route.isFirst);
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Container(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Update your preferences',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // White text in dark mode
                          : Colors.black, // Black text in light mode
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850] // Dark grey in dark mode
                        : Colors.white, // White in light mode
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: preferences.keys.map((String key) {
                          return CheckboxListTile(
                            activeColor: Theme.of(context).primaryColor,
                            title: Text(
                              preferenceLabels[key] ?? key,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white // White text in dark mode
                                    : Colors.black, // Black text in light mode
                              ),
                            ),
                            value: preferences[key],
                            onChanged: (bool? value) {
                              setState(() {
                                preferences[key] = value!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, preferences);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, 
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text('BACK', 
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              )
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final success = await ApiService
                              .updateVehicleDetailsAndParkingPreferences(
                            userID: widget.userID,
                            vehicleBrand: widget.vehicleBrand,
                            vehicleType: widget.vehicleType,
                            vehicleCategory: widget.vehicleCategory,
                            preferences: preferences,
                          );

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Preferences updated successfully!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update preferences.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('UPDATE',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                             SizedBox(width: 4),
                             Icon(Icons.check, size: 20, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(userId: widget.userID),
    );
  }
}
