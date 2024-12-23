import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/providers/countdown_provider.dart';
import 'package:iprsr/screens/splash_screen.dart';
import 'package:iprsr/screens/login_screen.dart';
import 'package:iprsr/screens/registration_screen.dart';
import 'package:iprsr/screens/main_screen.dart';
import 'package:iprsr/screens/parking_location_screen.dart';
import 'package:iprsr/theme/app_theme.dart';
import 'package:iprsr/providers/theme_provider.dart';
import 'package:iprsr/providers/tutorial_provider.dart';
import 'package:iprsr/providers/location_provider.dart'; // Import the LocationProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the countdown provider
  final countdownProvider = CountdownProvider();
  await countdownProvider.checkAndRestoreCountdown();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TutorialProvider()),
        ChangeNotifierProvider.value(value: countdownProvider),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()), // Add LocationProvider here
      ],
      child: const IPRSRApp(),
    ),
  );
}

class IPRSRApp extends StatelessWidget {
  const IPRSRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        ThemeData currentTheme;
        switch (themeProvider.currentTheme) {
          case ThemeType.light:
            currentTheme = AppTheme.lightTheme;
            break;
          case ThemeType.dark:
            currentTheme = AppTheme.darkTheme;
            break;
        }

        return MaterialApp(
          title: 'IPRSR',
          theme: currentTheme,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            try {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                      builder: (context) => const SplashScreen());
                case '/login':
                  return MaterialPageRoute(
                      builder: (context) => LoginScreen());
                case '/register':
                  return MaterialPageRoute(
                      builder: (context) => const RegistrationScreen());
                case '/parking-location':
                  return MaterialPageRoute(
                    builder: (context) => ParkingLocationScreen(
                      lotID: settings.arguments as String? ?? 'DefaultLocation',
                    ),
                  );
                case '/main':
                  return MaterialPageRoute(
                    builder: (context) => const MainScreen(),
                  );

                default:
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Route not found'),
                      ),
                    ),
                  );
              }
            } catch (e, stack) {
              print('Navigation error: $e');
              print('Stack trace: $stack');
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: Text('Error: $e'),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}