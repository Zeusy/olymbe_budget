import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static const _databaseName = "BudgetApp.db";
  static const _databaseVersion = 5;

  static const tableAccounts = 'accounts';
  static const columnName = 'name';
  static const columnInitialBalance = 'initialBalance';
  static const columnColor = 'color';
  static const columnIsIgnored = 'is_ignored';

  static const tableTransactions = 'transactions';
  static const columnId = '_id';
  static const columnAccountId = 'accountId';
  static const columnCategoryId = 'categoryId';
  static const columnAmount = 'amount';
  static const columnType = 'type';
  static const columnDate = 'date';
  static const columnDescription = 'description';

  static const tableCategories = 'categories';
  static const columnIcon = 'icon';

  static const tableBudgets = 'budgets';
  static const columnBudgetAmount = 'budgetAmount';
  static const columnCurrentAmount = 'currentAmount';
  static const columnMonth = 'month';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableCategories ADD COLUMN $columnColor TEXT NOT NULL DEFAULT \'#000000\'');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
        ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE user_accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          biometric_enabled INTEGER DEFAULT 0
        )
        ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE $tableAccounts ADD COLUMN $columnIsIgnored INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableAccounts (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnInitialBalance REAL NOT NULL,
        $columnColor TEXT NOT NULL,
        $columnIsIgnored INTEGER NOT NULL DEFAULT 0
      )
      ''');

    await db.execute('''
      CREATE TABLE $tableCategories (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL UNIQUE,
        $columnIcon TEXT NOT NULL,
        $columnColor TEXT NOT NULL DEFAULT \'#000000\'
      )
      ''');

    await db.execute('''
      CREATE TABLE $tableTransactions (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnAccountId INTEGER NOT NULL,
        $columnCategoryId INTEGER NOT NULL,
        $columnAmount REAL NOT NULL,
        $columnType TEXT NOT NULL CHECK($columnType IN ('income', 'expense')),
        $columnDate TEXT NOT NULL,
        $columnDescription TEXT,
        FOREIGN KEY ($columnAccountId) REFERENCES $tableAccounts ($columnId) ON DELETE CASCADE,
        FOREIGN KEY ($columnCategoryId) REFERENCES $tableCategories ($columnId) ON DELETE RESTRICT
      )
      ''');

    await db.execute('''
      CREATE TABLE $tableBudgets (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnCategoryId INTEGER NOT NULL UNIQUE,
        $columnBudgetAmount REAL NOT NULL,
        $columnCurrentAmount REAL NOT NULL DEFAULT 0,
        $columnMonth TEXT NOT NULL,
        FOREIGN KEY ($columnCategoryId) REFERENCES $tableCategories ($columnId) ON DELETE CASCADE
      )
      ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE user_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        biometric_enabled INTEGER DEFAULT 0
      )
      ''');
  }

  Future<int> insertAccount(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableAccounts, row);
  }

  Future<List<Map<String, dynamic>>> queryAllAccounts() async {
    Database db = await instance.database;
    return await db.query(tableAccounts);
  }

  Future<int> updateAccount(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(tableAccounts, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteAccount(int id) async {
    Database db = await instance.database;
    return await db.delete(tableAccounts, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    Database db = await instance.database;
    final id = await db.insert(tableTransactions, row);
    final transactionDate = DateTime.parse(row[columnDate]);
    final categoryId = row[columnCategoryId];
    await _updateBudgetCurrentAmount(categoryId, transactionDate);
    return id;
  }

  Future<List<Map<String, dynamic>>> queryAllTransactions() async {
    Database db = await instance.database;
    return await db.query(tableTransactions);
  }

  Future<int> updateTransaction(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    final rowsAffected = await db.update(tableTransactions, row, where: '$columnId = ?', whereArgs: [id]);
    final transactionDate = DateTime.parse(row[columnDate]);
    final categoryId = row[columnCategoryId];
    await _updateBudgetCurrentAmount(categoryId, transactionDate);
    return rowsAffected;
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await instance.database;
    return await db.delete(tableTransactions, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> insertCategory(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableCategories, row);
  }

  Future<List<Map<String, dynamic>>> queryAllCategories() async {
    Database db = await instance.database;
    return await db.query(tableCategories);
  }

  Future<int> insertBudget(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableBudgets, row);
  }

  Future<List<Map<String, dynamic>>> queryAllBudgets() async {
    Database db = await instance.database;
    return await db.query(tableBudgets);
  }

  Future<int> updateBudget(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(tableBudgets, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteBudget(int id) async {
    Database db = await instance.database;
    return await db.delete(tableBudgets, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory() async {
    Database db = await instance.database;
    return await db.rawQuery('''
      SELECT
        c.name, c.color, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.categoryId = c._id
      WHERE t.type = 'expense'
      GROUP BY c.name, c.color
    ''');
  }

  Future<int> insertSetting(String key, String value) async {
    Database db = await instance.database;
    return await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) {
      return result.first['value'];
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> queryAllUserAccounts() async {
    Database db = await instance.database;
    return await db.query('user_accounts');
  }

  Future<Map<String, dynamic>?> getUserAccount(String username) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query('user_accounts', where: 'username = ?', whereArgs: [username]);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getPrimaryUserAccount() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query('user_accounts', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> insertUserAccount(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('user_accounts', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUserAccount(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update('user_accounts', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUserAccount(int id) async {
    Database db = await instance.database;
    return await db.delete('user_accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryLatestTransactions(int limit) async {
    Database db = await instance.database;
    return await db.query(
      tableTransactions,
      orderBy: '$columnDate DESC',
      limit: limit,
    );
  }

  Future<double> getAccountBalance(int accountId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        (SELECT initialBalance FROM accounts WHERE _id = ?) +
        (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE accountId = ? AND type = 'income') -
        (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE accountId = ? AND type = 'expense')
        AS balance
    ''', [accountId, accountId, accountId]);

    if (result.isNotEmpty && result.first['balance'] != null) {
      return result.first['balance'] as double;
    }
    return 0.0;
  }

  Future<double> getCategoryExpensesForMonth(int categoryId, String month) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM $tableTransactions
      WHERE $columnCategoryId = ?
      AND $columnType = 'expense'
      AND STRFTIME('%Y-%m', $columnDate) = ?
    ''', [categoryId, month]);
    return result.first['total'] as double;
  }

  Future<void> _updateBudgetCurrentAmount(int categoryId, DateTime transactionDate) async {
    final db = await database;
    final month = DateFormat('yyyy-MM').format(transactionDate);

    final currentExpenses = await getCategoryExpensesForMonth(categoryId, month);

    final existingBudgets = await db.query(
      tableBudgets,
      where: '$columnCategoryId = ? AND $columnMonth = ?',
      whereArgs: [categoryId, month],
    );

    if (existingBudgets.isNotEmpty) {
      final budgetId = existingBudgets.first[columnId];
      await db.update(
        tableBudgets,
        {columnCurrentAmount: currentExpenses},
        where: '$columnId = ?',
        whereArgs: [budgetId],
      );
    }
  }
}