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
        title: Text('Recommendations'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getRecommendations(user.userID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No recommendations available.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var recommendation = snapshot.data![index];
                return ListTile(
                  title: Text('Parking Lot: ${recommendation['parkingLot']}'),
                  subtitle: Text('Details: ${recommendation['details']}'),
                  onTap: () {
                    // Navigate to parking space (implement navigation logic here)
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
