import 'package:flutter/material.dart';
import 'package:iprsr/services/api_service.dart';

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

  // Map preference keys to user-friendly names
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
      appBar: AppBar(
        title: const Text('Edit Parking Preferences'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Update your preferences',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                    // Pass the updated preferences back when navigating back
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
                    print("Sending data to API:");
                    print("UserID: ${widget.userID}");
                    print("Vehicle Brand: ${widget.vehicleBrand}");
                    print("Vehicle Type: ${widget.vehicleType}");
                    print("Preferences: $preferences");

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
                      // Navigate to the main screen after success
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
    );
  }
}
