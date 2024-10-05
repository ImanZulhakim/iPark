import 'package:flutter/material.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/models/user.dart';

class RecommendationScreen extends StatelessWidget {
  final User user;

  RecommendationScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Parking Recommendations'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: ApiService.getParkingSpaces(),  // Fetch parking spaces from the API
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No parking spaces available.'));
          } else {
            final parkingSpaces = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,  // 2 columns for the grid
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.0,  // Adjust for making each cell taller
                ),
                itemCount: parkingSpaces.length,  // Total number of parking spaces
                itemBuilder: (context, index) {
                  String parkingSpaceID = parkingSpaces[index]['parkingSpaceID'];
                  bool isAvailable = parkingSpaces[index]['isAvailable'] == '1';
                  
                  // Fetch the recommended space based on userID
                  return FutureBuilder<String?>(
                    future: ApiService.getRecommendations(user.userID),
                    builder: (context, recommendationSnapshot) {
                      if (recommendationSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (recommendationSnapshot.hasError) {
                        return Center(child: Text('Error: ${recommendationSnapshot.error}'));
                      } else if (!recommendationSnapshot.hasData) {
                        return Center(child: Text('No recommendation found.'));
                      } else {
                        String recommendedSpace = recommendationSnapshot.data!;
                        bool isRecommended = parkingSpaceID == recommendedSpace;
                        
                        return GestureDetector(
                          onTap: () {
                            // Add navigation or more actions here if needed
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isRecommended
                                  ? Colors.greenAccent
                                  : (isAvailable ? Colors.grey[200] : Colors.redAccent),
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
                                  Icons.local_parking,  // Example icon for parking
                                  size: 24,
                                  color: isRecommended
                                      ? Colors.white
                                      : (isAvailable ? Colors.black54 : Colors.white),
                                ),
                                SizedBox(height: 8), // Spacing between icon and text
                                Text(
                                  isAvailable ? parkingSpaceID : "OCCUPIED",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isRecommended
                                        ? Colors.white
                                        : (isAvailable ? Colors.black87 : Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
