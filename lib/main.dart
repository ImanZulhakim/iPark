import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:iprsr/providers/location_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize Local Notifications
Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// Request Notification Permissions (for Android 13+)
Future<void> requestNotificationPermissions() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Request notification permissions for Android 13+
  final bool? result = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  if (result == true) {
    print('Notification permission granted');
  } else {
    print('Notification permission denied');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize the countdown provider
  final countdownProvider = CountdownProvider();
  await countdownProvider.checkAndRestoreCountdown();

  // Initialize the AuthService and restore login status
  final authService = AuthService();
  await authService.init(prefs);

  // Initialize the ThemeProvider and restore the theme
  final themeProvider = ThemeProvider();
  await themeProvider.init(prefs);

  // Initialize local notifications
  await initializeLocalNotifications();

  // Request notification permissions
  await requestNotificationPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TutorialProvider()),
        ChangeNotifierProvider.value(value: countdownProvider),
        ChangeNotifierProvider<AuthService>(
          create: (_) => authService,
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const IPRSRApp(),
    ),
  );
}

class IPRSRApp extends StatefulWidget {
  const IPRSRApp({super.key});

  @override
  _IPRSRAppState createState() => _IPRSRAppState();
}

class _IPRSRAppState extends State<IPRSRApp> with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    print('Lifecycle observer added'); // Debugging
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    super.dispose();
    print('Lifecycle observer removed'); // Debugging
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('AppLifecycleState: $state'); // Debugging

    // Handle lifecycle events
    if (state == AppLifecycleState.resumed) {
      // Restore app state when the app resumes
      final authService = Provider.of<AuthService>(context, listen: false);
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      authService.restoreLoginStatus(); // Restore login status
      themeProvider.restoreTheme(); // Restore theme
    }
  }

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