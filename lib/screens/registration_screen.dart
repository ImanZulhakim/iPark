import 'package:flutter/material.dart';
import 'vehicle_details_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Store boolean values for gender and disability
  final ValueNotifier<bool?> _isFemale = ValueNotifier<bool?>(null);  // true for Female, false for Male
  final ValueNotifier<bool?> _hasDisability = ValueNotifier<bool?>(null);  // true for Yes, false for No

  String? vehicleBrand; // Store vehicle brand
  String? vehicleType;  // Store vehicle type

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create new account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: userNameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    // Simple email validation
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                // Gender selection using boolean values
                ValueListenableBuilder<bool?>(
                  valueListenable: _isFemale,
                  builder: (context, value, child) {
                    return DropdownButtonFormField<bool>(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      value: value,
                      items: [
                        DropdownMenuItem<bool>(
                          child: Text('Male'),
                          value: false, // Male as false
                        ),
                        DropdownMenuItem<bool>(
                          child: Text('Female'),
                          value: true,  // Female as true
                        ),
                      ],
                      onChanged: (newValue) {
                        _isFemale.value = newValue;  // Store as boolean
                      },
                    );
                  },
                ),
                SizedBox(height: 10),

                // Disability selection using boolean values
                ValueListenableBuilder<bool?>(
                  valueListenable: _hasDisability,
                  builder: (context, value, child) {
                    return DropdownButtonFormField<bool>(
                      decoration: InputDecoration(
                        labelText: 'Do you have a disability?',
                        border: OutlineInputBorder(),
                      ),
                      value: value,
                      items: [
                        DropdownMenuItem<bool>(
                          child: Text('No'),
                          value: false,  // No as false
                        ),
                        DropdownMenuItem<bool>(
                          child: Text('Yes'),
                          value: true,  // Yes as true
                        ),
                      ],
                      onChanged: (newValue) {
                        _hasDisability.value = newValue;  // Store as boolean
                      },
                    );
                  },
                ),
                SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // Navigate to the Vehicle Details screen and await results
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehicleDetailsScreen(
                              userNameController: userNameController,
                              emailController: emailController,
                              passwordController: passwordController,
                              gender: _isFemale.value ?? false, // Default to Male if null
                              hasDisability: _hasDisability.value ?? false, // Default to No if null
                              initialBrand: vehicleBrand,
                              initialType: vehicleType,
                            ),
                          ),
                        );

                        // Check if values were returned from the VehicleDetailsScreen
                        if (result != null) {
                          setState(() {
                            vehicleBrand = result['brand'];
                            vehicleType = result['type'];
                          });
                        }
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('NEXT'),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text('Already have an account? Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
