import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/login_screen.dart';
import 'package:iprsr/screens/main_screen.dart';
import 'package:iprsr/providers/location_provider.dart'; // Import LocationProvider

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer<AuthService>(
          builder: (context, auth, child) {
            // Check if the user is authenticated
            if (auth.user != null) {
              // Fetch the selected location from the LocationProvider
              final locationProvider = Provider.of<LocationProvider>(context, listen: false);
              locationProvider.fetchLastUsedLot(auth.user!.userID);

              // Navigate to the MainScreen without passing selectedLocation
              return const MainScreen();
            } else {
              // Navigate to the LoginScreen if the user is not authenticated
              return LoginScreen();
            }
          },
        ),
      ),
    );
  }
}