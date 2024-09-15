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
    'Nearest': false,
    'Covered': false,
    'Wheelchair access': false,
    'Large space': false,
    'Well Lit Area': false,
    'Has EV Charger': false,
    'Family Parking Area': false,
    'Premium Parking': false,
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
                    title: Text(key),
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
                    // Handle registration and navigate to main screen or login
                    final authService =
                        Provider.of<AuthService>(context, listen: false);
                    await authService.register(
                      widget.emailController.text,
                      widget.passwordController.text,
                      widget.userNameController.text,
                      widget.gender == '0' ? true : false,
                      widget.hasDisability == '0' ? true : false,
                      widget.brandController.text,
                      widget.typeController.text,
                      preferences,
                    );

                    if (authService.user != null) {
                      // Show a success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registration successful!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Navigate to the main screen immediately after showing the SnackBar
                      Navigator.pushReplacementNamed(context, '/main');
                    } else {
                      // Show an error message if registration failed
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
