import 'package:flutter/material.dart';
import 'package:iprsr/screens/edit_parking_preferences_screen.dart';
import 'package:iprsr/widgets/custom_bottom_navigation_bar.dart';
import 'package:iprsr/screens/main_screen.dart'; // Import the main screen

class EditVehicleDetailsScreen extends StatefulWidget {
  final String userID;
  final String initialBrand;
  final String initialType;
  final Map<String, bool> initialPreferences;

  const EditVehicleDetailsScreen({
    required this.userID,
    required this.initialBrand,
    required this.initialType,
    required this.initialPreferences,
    Key? key,
  }) : super(key: key);

  @override
  _EditVehicleDetailsScreenState createState() =>
      _EditVehicleDetailsScreenState();
}

class _EditVehicleDetailsScreenState extends State<EditVehicleDetailsScreen> {
  late String brand;
  late String type;
  late Map<String, bool> preferences;

  final List<String> vehicleBrands = ['Toyota', 'Honda', 'Ford', 'BMW', 'Tesla'];
  final List<String> vehicleTypes = ['Sedan', 'SUV', 'Truck', 'Coupe', 'Convertible'];

  @override
  void initState() {
    super.initState();
    brand = widget.initialBrand;
    type = widget.initialType;
    preferences = Map<String, bool>.from(widget.initialPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Floating Action Button at the center docked
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 80.0,
        height: 80.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 245, 107, 153),
              Color.fromARGB(255, 131, 245, 245),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Redirect to main screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()), // Navigate to main screen
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0, // Remove elevation to avoid shadow over gradient
          child: const Text(
            'P',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              fontFamily: 'Satisfy',
              color: Colors.white,
            ),
          ),
        ),
      ),

      // Bottom Navigation Bar with Notch for FloatingActionButton
      bottomNavigationBar: CustomBottomNavigationBar(userId: widget.userID),

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
          mainAxisAlignment: MainAxisAlignment.center, // Center the elements vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center the elements horizontally
          children: [
            const Center(
              child: Text(
                'Lets start with your car',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
                value: brand,
                items: vehicleBrands
                    .map((label) => DropdownMenuItem(
                          child: Text(label),
                          value: label,
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    brand = newValue!;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                value: type,
                items: vehicleTypes
                    .map((label) => DropdownMenuItem(
                          child: Text(label),
                          value: label,
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    type = newValue!;
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            // The updated row with "PREV" and "NEXT" buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Navigate back to the previous screen
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('PREV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final updatedPreferences = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditParkingPreferencesScreen(
                          initialPreferences: preferences,
                          userID: widget.userID,
                          vehicleBrand: brand,
                          vehicleType: type,
                        ),
                      ),
                    );

                    if (updatedPreferences != null) {
                      setState(() {
                        preferences = updatedPreferences;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('NEXT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
