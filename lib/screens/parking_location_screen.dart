import 'package:flutter/material.dart';
import 'package:iprsr/screens/main_screen.dart';

class ParkingLocationScreen extends StatefulWidget {
  final String selectedLocation;

  const ParkingLocationScreen({super.key, required this.selectedLocation});

  @override
  _ParkingLocationScreenState createState() => _ParkingLocationScreenState();
}

class _ParkingLocationScreenState extends State<ParkingLocationScreen> {
  // Define a map of states to their respective parking locations
  final Map<String, List<String>> stateLocations = {
    'Kedah': ['SoC', 'V Mall', 'C-mart Changlun', 'Aman Central'],
    'Penang': ['Penang Times Square', 'Queensbay Mall'],
    'Selangor': ['Sunway Pyramid', 'IOI City Mall'],
    'Kuala Lumpur': ['Pavilion KL', 'Suria KLCC'],
    'Johor': ['Johor Premium Outlets', 'KSL City Mall'],
    // Add more states and locations as needed
  };

  String? selectedState; // Track the currently selected state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    selectedState == null
                        ? 'Select Your State'
                        : 'Available Parking Lots in $selectedState',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      itemCount: selectedState == null
                          ? stateLocations.keys.length
                          : stateLocations[selectedState]!.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (context, index) {
                        if (selectedState == null) {
                          // Display states as the first level
                          String state = stateLocations.keys.elementAt(index);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedState = state;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  state,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        } else {
                          // Display locations within the selected state
                          String location = stateLocations[selectedState]![index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MainScreen(selectedLocation: location),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (selectedState != null)
              Positioned(
                bottom: 16,
                left: 16,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedState = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              ),
            if (selectedState == null)
              Positioned(
                bottom: 16,
                left: 16,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainScreen(selectedLocation: widget.selectedLocation),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              ),
          ],
        ),
      ),
    );
  }
}
