import 'package:flutter/material.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/models/user.dart';

class RecommendationScreen extends StatelessWidget {
  final User user;
  final String location; // Added as a field

  const RecommendationScreen({
    required this.user,
    required this.location, // Initialize the location field
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommendations for $location'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future:
            fetchRecommendationsAndSpaces(), // Fetch both spaces and recommendations
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No parking spaces available.'));
          } else {
            // Extract data from snapshot
            final parkingSpaces =
                snapshot.data!['parkingSpaces'] as List<Map<String, dynamic>>;
            final String recommendedSpace =
                snapshot.data!['recommendedSpace'] as String;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.0,
                ),
                itemCount: parkingSpaces.length,
                itemBuilder: (context, index) {
                  final parkingSpace = parkingSpaces[index];
                  final String parkingSpaceID = parkingSpace['parkingSpaceID'];
                  final bool isAvailable =
                      parkingSpace['isAvailable'].toString() == '1';
                  final bool isRecommended = parkingSpaceID == recommendedSpace;

                  return GestureDetector(
                    onTap: () {
                      // Add actions on tap, such as booking the space
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isRecommended
                            ? Colors.greenAccent
                            : (isAvailable
                                ? Colors.grey[200]
                                : Colors.redAccent),
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
                            Icons.local_parking,
                            size: 24,
                            color: isRecommended
                                ? Colors.white
                                : (isAvailable ? Colors.black54 : Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAvailable ? parkingSpaceID : "OCCUPIED",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isRecommended
                                  ? Colors.white
                                  : (isAvailable
                                      ? Colors.black87
                                      : Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> fetchRecommendationsAndSpaces() async {
    try {
      // Fetch parking spaces for the selected location
      final parkingSpaces = await ApiService.getParkingSpaces(location);

      // Fetch the recommended parking space based on user preferences
      final recommendedSpace = await ApiService.getRecommendations(user.userID,
          location);

      return {
        'parkingSpaces': parkingSpaces,
        'recommendedSpace': recommendedSpace,
      };
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }
}
