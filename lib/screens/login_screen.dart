import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/screens/main_screen.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Theme.of(context).colorScheme.surface,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/icon/icon.png',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Login to your account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: emailController,
                    style: Theme.of(context).brightness == Brightness.dark
                        ? const TextStyle(color: Colors.black)
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: Theme.of(context).brightness == Brightness.dark
                          ? const TextStyle(color: Colors.black54)
                          : null,
                      hintText: 'Enter your email',
                      hintStyle: Theme.of(context).brightness == Brightness.dark
                          ? const TextStyle(color: Colors.black38)
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: Theme.of(context).brightness == Brightness.dark
                        ? const TextStyle(color: Colors.black)
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: Theme.of(context).brightness == Brightness.dark
                          ? const TextStyle(color: Colors.black54)
                          : null,
                      hintText: 'Enter your password',
                      hintStyle: Theme.of(context).brightness == Brightness.dark
                          ? const TextStyle(color: Colors.black38)
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      suffixText: 'Forgot password?',
                      suffixStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _handleLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('or continue with'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Google sign-in logic
                    },
                    icon: Image.asset('assets/images/google_logo.png', height: 24),
                    label: const Text('Google'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'Register',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    final email = emailController.text;
    final password = passwordController.text;

    try {
      // Trigger login
      await Provider.of<AuthService>(context, listen: false)
          .login(email, password);

      // Check if login was successful and get the user ID
      final userId =
          Provider.of<AuthService>(context, listen: false).getUserId();
      if (userId != null) {
        print('User ID: $userId'); // Print the userId to debug

  
        // Navigate to MainScreen and pass userId and selectedLocation
       Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => MainScreen(
      selectedLocation: {
        'lotID': 'SOC_01', // Replace with the actual lotID
        'lot_name': 'SOC', // Replace with the actual lot name
      },
    ),
  ),
);

      } else {
        _showSnackBar(context, 'Login failed');
      }
    } catch (error) {
      _showSnackBar(context, 'Login error: ${error.toString()}');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
