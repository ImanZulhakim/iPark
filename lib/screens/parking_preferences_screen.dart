import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/main_screen.dart';

class ParkingPreferencesScreen extends StatefulWidget {
  final TextEditingController userNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController phoneController;
  final TextEditingController brandController;
  final TextEditingController typeController;
  final bool gender;
  final bool hasDisability;

  const ParkingPreferencesScreen({super.key, 
    required this.userNameController,
    required this.emailController,
    required this.passwordController,
    required this.phoneController,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 168, 220),
              Color.fromARGB(255, 240, 241, 241),
              Color.fromARGB(255, 131, 245, 245),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please choose your preferences',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: preferences.keys.map((String key) {
                          return CheckboxListTile(
                            activeColor:
                                const Color.fromARGB(255, 245, 107, 153),
                            title: Text(
                              preferenceLabels[key] ?? key,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
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
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back, color: Colors.black),
                            SizedBox(width: 5),
                            Text('PREV', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                      // Inside ParkingPreferencesScreen's registration flow
                      ElevatedButton(
                        onPressed: () async {
                          final authService =
                              Provider.of<AuthService>(context, listen: false);

                          // Use AuthService to register with user input and preferences
                          await authService.register(
                            widget.emailController.text,
                            widget.passwordController.text,
                            widget.phoneController.text,
                            widget.userNameController.text,
                            widget.gender,
                            widget.hasDisability,
                            widget.brandController.text,
                            widget.typeController.text,
                            preferences,
                          );

                          if (authService.user != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Registration successful!'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Set a default location or navigate the user to select a location
                            const selectedLocation =
                                'SoC'; // Or navigate to ParkingLocationScreen first

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainScreen(
                                    selectedLocation: selectedLocation),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Registration failed'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                        child: Row(
                          children: [
                            Text('REGISTER'),
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
          ),
        ),
      ),
    );
  }
}
