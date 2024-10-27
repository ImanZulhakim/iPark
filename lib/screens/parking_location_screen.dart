import 'package:flutter/material.dart';
import 'package:iprsr/screens/main_screen.dart';

class ParkingLocationScreen extends StatefulWidget {
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 168, 220),
              Color.fromARGB(255, 240, 241, 241),
              Color.fromARGB(255, 131, 245, 245),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Custom Header with Dynamic Title
              Text(
                selectedState == null
                    ? 'Select Your State'
                    : 'Available Parking Lots in $selectedState',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Back to State Selection Button (only shown when a state is selected)
              if (selectedState != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedState = null; // Go back to state selection
                    });
                  },
                  child: const Text(
                    'Back to State Selection',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
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
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 3,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              state,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
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
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 3,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
