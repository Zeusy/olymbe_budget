import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:olymbe_budget/data/database_helper.dart';
import 'package:local_auth/local_auth.dart';
import 'package:olymbe_budget/models/user.dart';
import 'package:olymbe_budget/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  final TextEditingController _profileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _sgApiController = TextEditingController();
  final TextEditingController _caApiController = TextEditingController();
  final TextEditingController _revolutApiController = TextEditingController();

  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    var userAccount = await _dbHelper.getPrimaryUserAccount();
    if (userAccount == null) {
      // Create a default user if none exists
      await _dbHelper.insertUserAccount({
        'username': 'MonUtilisateur',
        'password': 'monmotdepasse',
        'biometric_enabled': 0,
      });
      userAccount = await _dbHelper.getPrimaryUserAccount();
    }

    if (userAccount != null) {
      final user = User.fromMap(userAccount);
      _profileController.text = user.username;
      _passwordController.text = user.password;
      _biometricEnabled = user.biometricEnabled;
    }

    _sgApiController.text = await _dbHelper.getSetting('sgApiSetting') ?? '';
    _caApiController.text = await _dbHelper.getSetting('caApiSetting') ?? '';
    _revolutApiController.text = await _dbHelper.getSetting('revolutApiSetting') ?? '';
    setState(() {});
  }

  Future<void> _saveProfileAndSecurity() async {
    final userAccount = await _dbHelper.getPrimaryUserAccount();
    if (userAccount != null) {
      final user = User.fromMap(userAccount);
      await _dbHelper.updateUserAccount(user.copyWith(
        username: _profileController.text,
        password: _passwordController.text,
        biometricEnabled: _biometricEnabled,
      ).toMap());
      _showSnackBar('Profil et sécurité sauvegardés !');
    } else {
      _showSnackBar('Erreur: Aucun utilisateur trouvé pour la sauvegarde.');
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    if (canCheckBiometrics) {
      List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isNotEmpty) {
        setState(() {
          _biometricEnabled = value;
        });
        final userAccount = await _dbHelper.getPrimaryUserAccount();
        if (userAccount != null) {
          final user = User.fromMap(userAccount);
          await _dbHelper.updateUserAccount(user.copyWith(biometricEnabled: value).toMap());
          _showSnackBar('Authentification biométrique ${value ? 'activée' : 'désactivée'}');
        }
      } else {
        _showSnackBar('Aucune biométrie disponible sur cet appareil.');
      }
    } else {
      _showSnackBar('La biométrie n\'est pas supportée sur cet appareil.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _profileController.dispose();
    _passwordController.dispose();
    _sgApiController.dispose();
    _caApiController.dispose();
    _revolutApiController.dispose();
    super.dispose();
  }

  Widget _buildAccountAndSecuritySection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compte et Sécurité',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _profileController,
              decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Activer l\'authentification biométrique'),
                Switch(
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveProfileAndSecurity,
              child: const Text('Sauvegarder'),
            ),
            ListTile(
              title: const Text('Déconnexion'),
              trailing: const Icon(Icons.logout),
              onTap: () {
                // TODO: Implémenter la logique de déconnexion
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankApiSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connexion API Banques',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sgApiController,
              decoration: const InputDecoration(labelText: 'Clé API Société Générale'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _dbHelper.insertSetting('sgApiSetting', _sgApiController.text),
              child: const Text('Sauvegarder SG API'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caApiController,
              decoration: const InputDecoration(labelText: 'Clé API Crédit Agricole'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _dbHelper.insertSetting('caApiSetting', _caApiController.text),
              child: const Text('Sauvegarder CA API'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _revolutApiController,
              decoration: const InputDecoration(labelText: 'Clé API Revolut'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _dbHelper.insertSetting('revolutApiSetting', _revolutApiController.text),
              child: const Text('Sauvegarder Revolut API'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(ThemeModeNotifier themeNotifier) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thème',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<ThemeMode>(
              title: const Text('Clair'),
              value: ThemeMode.light,
              groupValue: themeNotifier.themeMode,
              onChanged: (mode) => themeNotifier.toggleTheme(false),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sombre'),
              value: ThemeMode.dark,
              groupValue: themeNotifier.themeMode,
              onChanged: (mode) => themeNotifier.toggleTheme(true),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Système'),
              value: ThemeMode.system,
              groupValue: themeNotifier.themeMode,
              onChanged: (mode) => themeNotifier.toggleTheme(MediaQuery.of(context).platformBrightness == Brightness.dark),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeModeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildThemeSection(themeNotifier),
          const Divider(),
          _buildAccountAndSecuritySection(),
          const Divider(),
          _buildBankApiSection(),
        ],
      ),
    );
  }
}
