import 'package:flutter/material.dart';
import 'parking_preferences_screen.dart';

class VehicleDetailsScreen extends StatelessWidget {
  final TextEditingController userNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController phoneController;
  final bool gender;
  final bool hasDisability;

  final ValueNotifier<String?> _brand = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _type = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _category = ValueNotifier<String?>(null);

  // Accept the initial values for brand, type, and category from the previous screen
  final String? initialBrand;
  final String? initialType;
  final String? initialCategory;

  VehicleDetailsScreen({
    super.key,
    required this.userNameController,
    required this.emailController,
    required this.passwordController,
    required this.phoneController,
    required this.gender,
    required this.hasDisability,
    this.initialBrand,
    this.initialType,
    this.initialCategory,
  }) {
    // Set the initial values for brand, type, and category if provided
    _brand.value = initialBrand;
    _type.value = initialType;
    _category.value = initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Let\'s start with your car',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<String?>(
                  valueListenable: _brand,
                  builder: (context, value, child) {
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Vehicle Brand',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.black : null, // Black label text in dark mode
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: value,
                      dropdownColor: Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.black : Colors.black, // Black text in dark mode
                      ),
                      items: ['Toyota', 'Honda', 'Ford', 'BMW', 'Tesla']
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.black : Colors.black, // Black text in dark mode
                                  ),
                                ),
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
                      decoration: InputDecoration(
                        labelText: 'Vehicle Type',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.black : null, // Black label text in dark mode
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: value,
                      dropdownColor: Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.black : Colors.black, // Black text in dark mode
                      ),
                      items: ['Sedan', 'SUV', 'Truck', 'Coupe', 'Convertible']
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.black : Colors.black, // Black text in dark mode
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        _type.value = newValue;
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<String?>(
                  valueListenable: _category,
                  builder: (context, value, child) {
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Vehicle Category',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.black : null, // Black label text in dark mode
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: value,
                      dropdownColor: Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.black : Colors.black, // Black text in dark mode
                      ),
                      items: ['EV', 'Hybrid', 'Normal']
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.black : Colors.black, // Black text in dark mode
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        _category.value = newValue;
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
                          'category': _category.value,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 5),
                          Text('BACK'),
                        ],
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
                              phoneController: phoneController,
                              brandController: TextEditingController(text: _brand.value),
                              typeController: TextEditingController(text: _type.value),
                              categoryController: TextEditingController(text: _category.value),
                              gender: gender,
                              hasDisability: hasDisability,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Row(
                        children: [
                          Text('NEXT'),
                          SizedBox(width: 5),
                          Icon(Icons.arrow_forward),
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
    );
  }
}