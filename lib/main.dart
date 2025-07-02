import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:olymbe_budget/utils/colors.dart';
import 'package:intl/date_symbol_data_local.dart';

// Importe les écrans (qui seront créés plus tard)
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/splash_screen.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'package:olymbe_budget/data/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database; // Ensure database is initialized and migrated
  await initializeDateFormatting('fr_FR', null);

  runApp(
    ChangeNotifierProvider(create: (context) => ThemeModeNotifier(dbHelper), child: const MyApp()),
  );
}

class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final DatabaseHelper _dbHelper;

  ThemeModeNotifier(this._dbHelper) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    final savedTheme = await _dbHelper.getSetting('themeMode');
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await _dbHelper.insertSetting('themeMode', isDarkMode ? 'dark' : 'light');
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Gestion de Budget',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeNotifier.themeMode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  /// Construit le thème clair de l'application.
  ThemeData _buildLightTheme() {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.card,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: AppColors.text),
        headlineMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.text),
        headlineSmall: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.text),
        bodyLarge: TextStyle(fontSize: 16.0, color: AppColors.text),
        bodyMedium: TextStyle(fontSize: 14.0, color: AppColors.textSecondary),
      ),
    );
  }

  /// Construit le thème sombre de l'application.
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkText),
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.darkCard,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: AppColors.darkText),
        headlineMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.darkText),
        headlineSmall: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.darkText),
        bodyLarge: TextStyle(fontSize: 16.0, color: AppColors.darkText),
        bodyMedium: TextStyle(fontSize: 14.0, color: AppColors.darkTextSecondary),
      ),
    );
  }
}

/// Écran principal avec la navigation par onglets.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Liste des écrans à afficher.
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    BudgetsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Comptes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Budgets',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
