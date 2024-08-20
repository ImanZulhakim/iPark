import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:iprsr/services/auth_service.dart';

class EditProfileScreen extends StatelessWidget {
  final TextEditingController vehicleController = TextEditingController();
  final TextEditingController preferencesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: vehicleController,
              decoration: InputDecoration(labelText: 'Vehicle Details'),
            ),
            TextField(
              controller: preferencesController,
              decoration: InputDecoration(labelText: 'Parking Preferences'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save updated vehicle details and preferences in the backend
                // Add your backend logic here
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
