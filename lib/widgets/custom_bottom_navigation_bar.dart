import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final String userId;

  const CustomBottomNavigationBar({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                // Logic for Preferences or Settings
                print('Navigate to Preferences/Settings for User: $userId');
              },
              child:  Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Image.asset(
                      'assets/images/preferences.png',
                      width: 28,
                      height: 28,
                    ),
                    const Text(
                      'Preferences',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Provider.of<AuthService>(context, listen: false).logout();
                  Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, color: Colors.black54, size: 28),
                  Text(
                    'Log out',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
