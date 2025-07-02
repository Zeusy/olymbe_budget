import 'package:flutter/material.dart';
import 'package:olymbe_budget/data/database_helper.dart';
import 'package:olymbe_budget/models/user.dart';
import 'package:olymbe_budget/screens/login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> _register() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs.');
      return;
    }

    final existingUser = await _dbHelper.getUserAccount(username);
    if (existingUser != null) {
      _showSnackBar('Ce nom d\'utilisateur existe déjà.');
      return;
    }

    final newUser = User(
      username: username,
      password: password,
      biometricEnabled: false,
    );

    await _dbHelper.insertUserAccount(newUser.toMap());

    if (mounted) {
      _showSnackBar('Inscription réussie !');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
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
        title: const Text('Inscription'),
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
              onPressed: _register,
              child: const Text('S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}