import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final String userID;
  final String email;
  final String username;
  final String brand;
  final String type;
  final Map<String, bool> preferences;

  EditProfileScreen({
    required this.userID,
    required this.email,
    required this.username,
    required this.brand,
    required this.type,
    required this.preferences,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _brandController;
  late TextEditingController _typeController;
  late Map<String, bool> _preferences;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _usernameController = TextEditingController(text: widget.username);
    _brandController = TextEditingController(text: widget.brand);
    _typeController = TextEditingController(text: widget.type);
    _preferences = Map<String, bool>.from(widget.preferences);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _brandController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _brandController,
              decoration: InputDecoration(labelText: 'Vehicle Brand'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _typeController,
              decoration: InputDecoration(labelText: 'Vehicle Type'),
            ),
            SizedBox(height: 20),
            Text(
              'Parking Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            CheckboxListTile(
              title: Text('Nearest'),
              value: _preferences['Nearest'],
              onChanged: (newValue) {
                setState(() {
                  _preferences['Nearest'] = newValue!;
                });
              },
            ),
            CheckboxListTile(
              title: Text('Covered'),
              value: _preferences['Covered'],
              onChanged: (newValue) {
                setState(() {
                  _preferences['Covered'] = newValue!;
                });
              },
            ),
            CheckboxListTile(
              title: Text('Large Space'),
              value: _preferences['Large space'],
              onChanged: (newValue) {
                setState(() {
                  _preferences['Large space'] = newValue!;
                });
              },
            ),
            // Add more preferences here as needed
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Submit the updated data
                // You would typically call an API or update the database here
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
