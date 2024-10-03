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
      body: FutureBuilder<String?>(
        future: ApiService.getRecommendations(user.userID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No recommendations available.'));
          } else {
            // Assuming snapshot.data is a parking space like 'P06'
            String recommendedSpace = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,  // 2 columns for the grid
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.0,  // Adjust for making each cell taller
                ),
                itemCount: 12,  // 12 parking spaces
                itemBuilder: (context, index) {
                  String parkingSpace = 'P${(index + 1).toString().padLeft(2, '0')}';
                  bool isRecommended = parkingSpace == recommendedSpace;

                  // Replace these with the actual icons you plan to use for accessibility, etc.
                  IconData spaceIcon = Icons.local_parking;  // Example icon

                  return GestureDetector(
                    onTap: () {
                      // Add navigation or more actions here if needed
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isRecommended ? Colors.greenAccent : Colors.grey[200],
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
                            spaceIcon,
                            size: 24,
                            color: isRecommended ? Colors.white : Colors.black54,
                          ),
                          SizedBox(height: 8), // Spacing between icon and text
                          Text(
                            parkingSpace,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isRecommended ? Colors.white : Colors.black87,
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
}
