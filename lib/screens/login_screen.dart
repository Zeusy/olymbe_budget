import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:olymbe_budget/data/database_helper.dart';
import 'package:olymbe_budget/models/user.dart';
import 'package:olymbe_budget/main.dart'; // For MainScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadUserAndAttemptBiometrics();
  }

  Future<void> _loadUserAndAttemptBiometrics() async {
    final userAccount = await _dbHelper.getPrimaryUserAccount();
    if (userAccount != null) {
      final user = User.fromMap(userAccount);
      _usernameController.text = user.username;
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final userMap = await _dbHelper.getPrimaryUserAccount();
    if (userMap == null || !User.fromMap(userMap).biometricEnabled) {
      _showSnackBar('Authentification biométrique non activée pour cet utilisateur.');
      return;
    }

    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à l\'application',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
      if (authenticated) {
        _navigateToMainScreen();
      } else {
        _showSnackBar('Authentification biométrique échouée.');
      }
    } catch (e) {
      _showSnackBar('Erreur d\'authentification biométrique: $e');
    }
  }

  Future<void> _login() async {
    final userMap = await _dbHelper.getPrimaryUserAccount();

    if (userMap != null) {
      final user = User.fromMap(userMap);
      if (user.username == _usernameController.text && user.password == _passwordController.text) {
        _navigateToMainScreen();
      } else {
        _showSnackBar('Nom d\'utilisateur ou mot de passe incorrect.');
      }
    } else {
      _showSnackBar('Nom d\'utilisateur introuvable.');
    }
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _authenticateWithBiometrics,
              child: const Text('Se connecter avec la biométrie'),
            ),
          ],
        ),
      ),
    );
  }
}