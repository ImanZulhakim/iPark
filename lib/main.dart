import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/splash_screen.dart';
import 'package:iprsr/screens/login_screen.dart';
import 'package:iprsr/screens/registration_screen.dart';
import 'package:iprsr/screens/main_screen.dart';
import 'package:iprsr/screens/parking_location_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(IPRSRApp());
}

class IPRSRApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'IPRSR',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => SplashScreen());
            case '/login':
              return MaterialPageRoute(builder: (_) => LoginScreen());
            case '/register':
              return MaterialPageRoute(builder: (_) => RegistrationScreen());
            case '/parking-location':
              return MaterialPageRoute(builder: (_) => ParkingLocationScreen());
            case '/main':
              if (settings.arguments is String) {
                final selectedLocation = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => MainScreen(selectedLocation: selectedLocation),
                );
              }
              return MaterialPageRoute(
                builder: (_) => MainScreen(selectedLocation: 'SoC'), // Fallback
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}
