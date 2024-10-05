import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';

class ParkingPreferencesScreen extends StatefulWidget {
  final TextEditingController userNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController brandController;
  final TextEditingController typeController;
  final String gender;
  final String hasDisability;

  ParkingPreferencesScreen({
    required this.userNameController,
    required this.emailController,
    required this.passwordController,
    required this.brandController,
    required this.typeController,
    required this.gender,
    required this.hasDisability,
  });

  @override
  _ParkingPreferencesScreenState createState() =>
      _ParkingPreferencesScreenState();
}

class _ParkingPreferencesScreenState extends State<ParkingPreferencesScreen> {
  final Map<String, bool> preferences = {
    'isNearest': false,
    'isCovered': false,
    'requiresWheelchairAccess': false,
    'requiresLargeSpace': false,
    'requiresWellLitArea': false,
    'requiresEVCharging': false,
    'requiresFamilyParkingArea': false,
    'premiumParking': false,
  };

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parking Preferences'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Please choose your preferences',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
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
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 5),
                      Text('PREV'),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final authService =
                        Provider.of<AuthService>(context, listen: false);

                    // Use AuthService to register with user input and preferences
                    await authService.register(
                      widget.emailController.text,
                      widget.passwordController.text,
                      widget.userNameController.text,
                      widget.gender == '0',
                      widget.hasDisability == '0',
                      widget.brandController.text,
                      widget.typeController.text,
                      preferences,
                    );

                    if (authService.user != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registration successful!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pushReplacementNamed(context, '/main');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registration failed'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Text('REGISTER'),
                      SizedBox(width: 5),
                      Icon(Icons.check),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
