import 'package:flutter/material.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/models/user.dart';

class RecommendationScreen extends StatelessWidget {
  final User user;
  final String location;

  const RecommendationScreen({
    required this.user,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parking Recommendations for $location'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Parking Recommendations for $location',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.green),
                        Text('Entrance', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Exit', style: TextStyle(color: Colors.red)),
                        Icon(Icons.arrow_upward, color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: fetchRecommendationsAndSpaces(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('No parking spaces available.'));
                } else {
                  final parkingSpaces = snapshot.data!['parkingSpaces'] as List<Map<String, dynamic>>;
                  final String recommendedSpace = snapshot.data!['recommendedSpace'] as String;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        for (int i = 0; i < parkingSpaces.length; i += 4)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int j = 0; j < 4 && i + j < parkingSpaces.length; j++)
                                ParkingSpace(
                                  space: parkingSpaces[i + j],
                                  isRecommended: parkingSpaces[i + j]['parkingSpaceID'] == recommendedSpace,
                                  onTap: () {
                                    if (parkingSpaces[i + j]['parkingType'] == 'premium' && parkingSpaces[i + j]['isAvailable'] == '1') {
                                      _showPaymentDialog(context, parkingSpaces[i + j]['parkingSpaceID']);
                                    }
                                  },
                                ),
                            ],
                          ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchRecommendationsAndSpaces() async {
    try {
      final parkingSpaces = await ApiService.getParkingSpaces(location);
      final recommendedSpace = await ApiService.getRecommendations(user.userID, location);
      return {
        'parkingSpaces': parkingSpaces,
        'recommendedSpace': recommendedSpace,
      };
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  void _showPaymentDialog(BuildContext context, String parkingSpaceID) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Premium Parking"),
          content: const Text("This is a premium parking spot. Proceed with payment?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Parking spot $parkingSpaceID booked successfully!'),
                  backgroundColor: Colors.green,
                ));
              },
              child: const Text("Pay"),
            ),
          ],
        );
      },
    );
  }
}

class ParkingSpace extends StatelessWidget {
  final Map<String, dynamic> space;
  final bool isRecommended;
  final VoidCallback onTap;

  const ParkingSpace({
    required this.space,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = space['isAvailable'].toString() == '1';
    final String parkingType = space['parkingType']?.toString() ?? 'Regular';
    final String parkingSpaceID = space['parkingSpaceID'];

    Color bgColor;
    IconData? icon;

    // Set colors and icons based on the parking type
    switch (parkingType) {
      case 'Special':
        bgColor = Colors.blueAccent;
        icon = Icons.accessible; // Disability icon for special parking
        break;
      case 'Female':
        bgColor = Colors.pinkAccent;
        icon = Icons.female; // Female icon
        break;
      case 'Family':
        bgColor = Colors.purpleAccent;
        icon = Icons.family_restroom; // Family parking icon
        break;
      case 'EV Car':
        bgColor = Colors.tealAccent;
        icon = Icons.electric_car; // EV car icon
        break;
      case 'Premium':
        bgColor = Colors.yellowAccent;
        icon = Icons.star; // Premium icon
        break;
      default:
        bgColor = isAvailable ? Colors.grey[200]! : Colors.redAccent;
        icon = Icons.local_parking; // Default parking icon for regular
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 80,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isRecommended ? Colors.greenAccent : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isRecommended ? Colors.green : Colors.black12,
            width: isRecommended ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isRecommended ? Colors.white : (isAvailable ? Colors.black54 : Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              isAvailable ? parkingSpaceID : "OCCUPIED",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isRecommended ? Colors.white : (isAvailable ? Colors.black87 : Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

