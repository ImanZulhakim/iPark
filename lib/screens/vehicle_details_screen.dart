import 'package:flutter/material.dart';
import 'parking_preferences_screen.dart';

class VehicleDetailsScreen extends StatelessWidget {
  final TextEditingController userNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool gender;
  final bool hasDisability;

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 240, 241, 241),
              Color.fromARGB(255, 255, 168, 220),
              Color.fromARGB(255, 240, 241, 241),
              Color.fromARGB(255, 131, 245, 245),
              Color.fromARGB(255, 240, 241, 241),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Lets start from your car',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<String?>(
                  valueListenable: _brand,
                  builder: (context, value, child) {
                    return DropdownButtonFormField<String>(
                      decoration:  InputDecoration(
                        labelText: 'Vehicle Brand',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        filled: true,
                        fillColor: Colors.white,
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
                const SizedBox(height: 10),
                ValueListenableBuilder<String?>(
                  valueListenable: _type,
                  builder: (context, value, child) {
                    return DropdownButtonFormField<String>(
                      decoration:  InputDecoration(
                        labelText: 'Vehicle Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        filled: true, // To enable background color
                        fillColor: Colors.white, // White background color
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'brand': _brand.value,
                          'type': _type.value,
                        });
                      },
                      child: const Row(
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
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
                      child: const Row(
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
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}