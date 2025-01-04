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
  final TextEditingController categoryController;
  final bool gender; // true for female, false for male
  final bool hasDisability;

  const ParkingPreferencesScreen({
    super.key,
    required this.userNameController,
    required this.emailController,
    required this.passwordController,
    required this.phoneController,
    required this.brandController,
    required this.typeController,
    required this.categoryController,
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
    _initializePreferences();
  }

  void _initializePreferences() {
    // Auto-tick preferences based on conditions
    if (widget.hasDisability) {
      preferences['isNearest'] = true;
      preferences['requiresWheelchairAccess'] = true;
      preferences['requiresLargeSpace'] = true;
    }
    if (widget.gender) {
      // Female
      preferences['isNearest'] = true;
      preferences['requiresWellLitArea'] = true;
    }
    if (widget.brandController.text == 'Tesla') {
      preferences['requiresEVCharging'] = true;
    }

    if (widget.typeController.text == 'Truck') {
      preferences['requiresLargeSpace'] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: isDarkMode
                        ? const Color.fromARGB(255, 29, 29, 29) // Dark theme color
                        :  Colors.white, // Light theme color
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: preferences.keys.map((String key) {
                          return CheckboxListTile(
                            activeColor: Theme.of(context).colorScheme.primary,
                            title: Text(
                              preferenceLabels[key] ?? key,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white),
                            SizedBox(width: 5),
                            Text('BACK', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final authService =
                              Provider.of<AuthService>(context, listen: false);

                          await authService.register(
                            widget.emailController.text,
                            widget.passwordController.text,
                            widget.phoneController.text,
                            widget.userNameController.text,
                            widget.gender,
                            widget.hasDisability,
                            widget.brandController.text,
                            widget.typeController.text,
                            widget.categoryController.text,
                            preferences,
                          );

                          if (authService.user != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Registration successful!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Row(
                          children: [
                            Text('REGISTER',
                                style: TextStyle(color: Colors.white)),
                            SizedBox(width: 5),
                            Icon(Icons.check, color: Colors.white),
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