import 'package:flutter/material.dart';
import 'package:iprsr/screens/main_screen.dart';
import 'package:iprsr/services/api_service.dart';

class ParkingLocationScreen extends StatefulWidget {
  final String lotID;

  const ParkingLocationScreen({super.key, required this.lotID});

  @override
  _ParkingLocationScreenState createState() => _ParkingLocationScreenState();
}

class _ParkingLocationScreenState extends State<ParkingLocationScreen> {
  String? selectedState;
  String? selectedDistrict;
  List<dynamic> locations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final response = await ApiService.getParkingLocation();
      print('API Response: $response'); // Log the API response
      if (mounted) {
        setState(() {
          locations = response; // Assign grouped structure to `locations`
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (locations.isEmpty)
              const Center(child: Text('No parking locations available'))
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      selectedState == null
                          ? 'Select Your State'
                          : selectedDistrict == null
                              ? 'Select Your District in $selectedState'
                              : 'Select Parking Lot in $selectedDistrict, $selectedState',
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
                            ? locations.length
                            : selectedDistrict == null
                                ? locations
                                    .firstWhere((loc) =>
                                        loc['state'] ==
                                        selectedState)['districts']
                                    .length
                                : locations
                                    .firstWhere((loc) =>
                                        loc['state'] ==
                                        selectedState)['districts']
                                    .firstWhere((d) =>
                                        d['district'] ==
                                        selectedDistrict)['parking_lots']
                                    .length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (context, index) {
                          if (selectedState == null) {
                            final states =
                                locations.map((e) => e['state']).toList();
                            String state = states[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedState = state;
                                });
                              },
                              child: stateCard(state),
                            );
                          } else if (selectedDistrict == null) {
                            final districts = locations.firstWhere((loc) =>
                                loc['state'] == selectedState)['districts'];
                            final district = districts[index]['district'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDistrict = district;
                                });
                              },
                              child: stateCard(district),
                            );
                          } else {
                            final parkingLots = locations
                                .firstWhere((loc) =>
                                    loc['state'] == selectedState)['districts']
                                .firstWhere((d) =>
                                    d['district'] ==
                                    selectedDistrict)['parking_lots'];
                            final lot = parkingLots[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MainScreen(
                                      selectedLocation: {
                                        'lotID': lot['lotID'],
                                        'lot_name': lot['lot_name']
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: stateCard(lot['lot_name']),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              bottom: 16,
              left: 16,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (selectedDistrict != null) {
                      selectedDistrict = null; // Reset to districts
                    } else if (selectedState != null) {
                      selectedState = null; // Reset to states
                    } else {
                      Navigator.pop(context); // Exit the screen
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 20),
                    SizedBox(width: 4),
                    Text(
                      'BACK',
                      style: TextStyle(fontSize: 16),
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

  Widget stateCard(String title) {
    return Container(
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
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
