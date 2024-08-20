import 'package:flutter/material.dart';
import 'parking_preferences_screen.dart';

class VehicleDetailsScreen extends StatelessWidget {
  final TextEditingController userNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String gender;
  final String hasDisability;

  final ValueNotifier<String?> _brand = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _type = ValueNotifier<String?>(null);

  VehicleDetailsScreen({
    required this.userNameController,
    required this.emailController,
    required this.passwordController,
    required this.gender,
    required this.hasDisability,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: _brand,
              builder: (context, value, child) {
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Vehicle Brand',
                    border: OutlineInputBorder(),
                  ),
                  value: value,
                  items: ['Toyota', 'Honda', 'Ford', 'BMW', 'Tesla']
                      .map((label) => DropdownMenuItem(
                            child: Text(label),
                            value: label,
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    _brand.value = newValue;
                  },
                );
              },
            ),
            SizedBox(height: 10),
            ValueListenableBuilder<String?>(
              valueListenable: _type,
              builder: (context, value, child) {
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type',
                    border: OutlineInputBorder(),
                  ),
                  value: value,
                  items: ['Sedan', 'SUV', 'Truck', 'Coupe', 'Convertible']
                      .map((label) => DropdownMenuItem(
                            child: Text(label),
                            value: label,
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    _type.value = newValue;
                  },
                );
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the Parking Preferences screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParkingPreferencesScreen(
                        userNameController: userNameController,
                        emailController: emailController,
                        passwordController: passwordController,
                        brandController: TextEditingController(text: _brand.value),
                        typeController: TextEditingController(text: _type.value),
                        gender: gender,
                        hasDisability: hasDisability,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('NEXT'),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
