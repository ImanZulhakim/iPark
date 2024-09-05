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

  // Accept the initial values for brand and type from the previous screen
  final String? initialBrand;
  final String? initialType;


  VehicleDetailsScreen({
    required this.userNameController,
    required this.emailController,
    required this.passwordController,
    required this.gender,
    required this.hasDisability,
    this.initialBrand,
    this.initialType,
  }) {
    // Set the initial values for brand and type if provided
    _brand.value = initialBrand;
    _type.value = initialType;
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Pass the selected vehicle brand and type back to RegistrationScreen
                    Navigator.pop(context, {
                      'brand': _brand.value,
                      'type': _type.value,
                    });
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
                  onPressed: () {
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
