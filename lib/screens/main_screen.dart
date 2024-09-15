import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/edit_profile_screen.dart';
import 'package:iprsr/services/api_service.dart'; // Import the API service for recommendations

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the authenticated user's data
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tap for Recommendation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                // Log when the button is tapped
                print('Parking button tapped');

                // Fetch the recommendations when tapped
                if (user != null) {
                  // Log that the user is logged in and their userID
                  print('User is logged in. UserID: ${user.userID}');

                  try {
                    // Call the getRecommendations function with userID instead of preferences
                    final recommendations =
                        await ApiService.getRecommendations(user.userID);

                    // Log the recommendations received from the API
                    print('Recommendations received: $recommendations');

                    // Handle the result: you can show it in a dialog or navigate to a new screen
                    if (recommendations.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Recommendations'),
                          content: Text(recommendations
                              .toString()), // Display the fetched recommendations
                          actions: [
                            TextButton(
                              child: Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Log that no recommendations were available
                      print('No recommendations available');

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('No Recommendations'),
                          content: Text(
                              'No parking suggestions available at the moment.'),
                          actions: [
                            TextButton(
                              child: Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    // Log any error that occurs
                    print('Error fetching recommendations: $e');
                  }
                } else {
                  // Log if the user is not logged in
                  print('User is not logged in');
                }
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.pinkAccent, Colors.cyanAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Text(
                    'P',
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your central button logic here
        },
        backgroundColor: Colors.white,
        child: Icon(Icons.person, color: Colors.pinkAccent),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                // Navigate to the EditProfileScreen and pass the user details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      userID: user!.userID, // Pass the current userID
                      email: user.email, // Pass the current email
                      username: user.username, // Pass the current username
                      brand: user.brand, // Pass the current vehicle brand
                      type: user.type, // Pass the current vehicle type
                      preferences: user.preferences, // Pass parking preferences
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
