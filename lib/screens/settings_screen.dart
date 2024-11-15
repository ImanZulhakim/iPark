import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 26,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person_outline, 
              size: 26,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              'Account',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing: Icon(Icons.chevron_right, 
              size: 26,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onTap: () {
              // Navigate to account settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, size: 26),
            title: const Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, size: 26),
            onTap: () {
              // Navigate to notifications settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined, size: 26),
            title: const Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, size: 26),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Choose Theme'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.brightness_7),
                        title: const Text('Light Theme'),
                        selected: context.read<ThemeProvider>().currentTheme == ThemeType.light,
                        onTap: () {
                          context.read<ThemeProvider>().setTheme(ThemeType.light);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.brightness_4),
                        title: const Text('Dark Theme'),
                        selected: context.read<ThemeProvider>().currentTheme == ThemeType.dark,
                        onTap: () {
                          context.read<ThemeProvider>().setTheme(ThemeType.dark);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, size: 26),
            title: const Text(
              'Privacy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, size: 26),
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          const Divider(height: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red, size: 26),
            title: const Text(
              'Log out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    'Log out',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    'Are you sure you want to log out?',
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Provider.of<AuthService>(context, listen: false).logout();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        'Log out',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 