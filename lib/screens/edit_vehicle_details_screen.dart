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
    super.key,
  });

  @override
  _EditVehicleDetailsScreenState createState() =>
      _EditVehicleDetailsScreenState();
}

class _EditVehicleDetailsScreenState extends State<EditVehicleDetailsScreen> {
  late String brand;
  late String type;
  late Map<String, bool> preferences;

  final List<String> vehicleBrands = [
    'Toyota',
    'Honda',
    'Ford',
    'BMW',
    'Tesla'
  ];
  final List<String> vehicleTypes = [
    'Sedan',
    'SUV',
    'Truck',
    'Coupe',
    'Convertible'
  ];

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
      bottomNavigationBar: CustomBottomNavigationBar(
        userId: widget.userID,
        onFloatingActionButtonPressed: () {
          // Redirect to main screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(selectedLocation: 'SoC'),
            ),
          );
        },
      ),
      floatingActionButton: Container(
        width: 80.0,
        height: 80.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(
                  colors: [
                    Colors.teal,
                    Colors.tealAccent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    const Color(0xFF00B4D8),
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
              MaterialPageRoute(
                builder: (context) => MainScreen(selectedLocation: 'SoC'),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Text(
            'P',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              fontFamily: 'Satisfy',
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.white,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Lets start with your car',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 30),
            Center(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                value: brand,
                items: vehicleBrands
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
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
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                value: type,
                items: vehicleTypes
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 4),
                      Text('BACK', 
                        style: TextStyle(
                          fontSize: 16,
                        )
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('NEXT',
                        style: TextStyle(
                          fontSize: 16,
                        )
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 20),
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
