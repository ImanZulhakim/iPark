import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/login_screen.dart';
import 'package:iprsr/screens/main_screen.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer<AuthService>(
          builder: (context, auth, child) {
            if (auth.user != null) {
              return MainScreen();
            } else {
              return LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
