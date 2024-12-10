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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          ThemeData currentTheme;
          switch (themeProvider.currentTheme) {
            case ThemeType.light:
              currentTheme = AppTheme.lightTheme;
            case ThemeType.dark:
              currentTheme = AppTheme.darkTheme;
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
                        selectedLocation:
                            settings.arguments as String? ?? 'DefaultLocation',
                      ),
                    );
                  case '/main':
                    final selectedLocation =
                        settings.arguments as Map<String, String>? ??
                            {
                              'lotID': 'DefaultLotID',
                              'lot_name': 'DefaultLotName',
                            };
                    return MaterialPageRoute(
                      builder: (context) =>
                          MainScreen(selectedLocation: selectedLocation),
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
      ),
    ),
  );
}

class IPRSRApp extends StatelessWidget {
  const IPRSRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(),
          lazy: false,
        ),
        ChangeNotifierProvider<CountdownProvider>(
          create: (context) => CountdownProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          ThemeData currentTheme;
          switch (themeProvider.currentTheme) {
            case ThemeType.light:
              currentTheme = AppTheme.lightTheme;
            case ThemeType.dark:
              currentTheme = AppTheme.darkTheme;
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
                        selectedLocation:
                            settings.arguments as String? ?? 'DefaultLocation',
                      ),
                    );
                  case '/main':
                    final selectedLocation =
                        settings.arguments as Map<String, String>? ??
                            {
                              'lotID': 'DefaultLotID',
                              'lot_name': 'DefaultLotName',
                            };
                    return MaterialPageRoute(
                      builder: (context) =>
                          MainScreen(selectedLocation: selectedLocation),
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
      ),
    );
  }
}
