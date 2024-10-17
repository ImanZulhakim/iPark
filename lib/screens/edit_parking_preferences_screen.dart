import 'package:flutter/material.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/widgets/custom_bottom_navigation_bar.dart';

class EditParkingPreferencesScreen extends StatefulWidget {
  final Map<String, bool> initialPreferences;
  final String userID;
  final String vehicleBrand;
  final String vehicleType;

  const EditParkingPreferencesScreen({
    required this.userID,
    required this.initialPreferences,
    required this.vehicleBrand,
    required this.vehicleType,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 245, 107, 153),
              Color.fromARGB(255, 240, 241, 241),
              Color.fromARGB(255, 131, 245, 245),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topCenter, // Align to the top center
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 50.0), // Adjust top spacing as needed
                child: Text(
                  'Update your preferences',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: preferences.keys.map((String key) {
                  return CheckboxListTile(
                    title: Text(preferenceLabels[key] ?? key),
                    value: preferences[key],
                    onChanged: (bool? value) {
                      setState(() {
                        preferences[key] = value!;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, preferences);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 5),
                      Text('BACK'),
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
                      preferences: preferences,
                    );

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Preferences updated successfully!'),
                          backgroundColor: Colors.green,
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
                  child: const Row(
                    children: [
                      Text('UPDATE'),
                      SizedBox(width: 5),
                      Icon(Icons.check),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(userId: widget.userID),
    );
  }
}
