import 'package:flutter/material.dart';
import 'package:iprsr/screens/edit_parking_preferences_screen.dart';

class EditVehicleDetailsScreen extends StatefulWidget {
  final String userID;
  final String initialBrand;
  final String initialType;
  final Map<String, bool> initialPreferences; // Add this parameter

  const EditVehicleDetailsScreen({
    required this.userID,
    required this.initialBrand,
    required this.initialType,
    required this.initialPreferences, // Accept initial preferences
    Key? key,
  }) : super(key: key);

  @override
  _EditVehicleDetailsScreenState createState() =>
      _EditVehicleDetailsScreenState();
}

class _EditVehicleDetailsScreenState extends State<EditVehicleDetailsScreen> {
  late String brand;
  late String type;

  final List<String> vehicleBrands = ['Toyota', 'Honda', 'Ford', 'BMW', 'Tesla'];
  final List<String> vehicleTypes = ['Sedan', 'SUV', 'Truck', 'Coupe', 'Convertible'];

  @override
  void initState() {
    super.initState();
    brand = vehicleBrands.contains(widget.initialBrand) ? widget.initialBrand : vehicleBrands.first;
    type = vehicleTypes.contains(widget.initialType) ? widget.initialType : vehicleTypes.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Vehicle Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Vehicle Brand',
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
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Vehicle Type',
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
            SizedBox(height: 20),
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
                      Text('Back'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'brand': brand,
                      'type': type,
                    });
                  },
                  child: Row(
                    children: [
                      Text('Save'),
                      SizedBox(width: 5),
                      Icon(Icons.check),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditParkingPreferencesScreen(
                        initialPreferences: widget.initialPreferences, // Pass initial preferences
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Edit Parking Preferences'),
                    SizedBox(width: 5),
                    Icon(Icons.edit),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
