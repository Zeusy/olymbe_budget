import 'package:flutter/material.dart';
import 'package:olymbe_budget/data/database_helper.dart';
import 'package:olymbe_budget/screens/login_screen.dart';
import 'package:olymbe_budget/main.dart'; // For MainScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    final dbHelper = DatabaseHelper.instance;
    final userAccount = await dbHelper.getPrimaryUserAccount();

    if (userAccount == null) {
      // No user exists, navigate to RegistrationScreen (or LoginScreen if registration is handled there)
      // For now, let's assume LoginScreen handles initial user creation if needed.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      // User exists, navigate to LoginScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}