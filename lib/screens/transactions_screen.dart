
import 'package:olymbe_budget/data/database_helper.dart';
import 'package:olymbe_budget/models/transaction.dart';
import 'package:olymbe_budget/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:olymbe_budget/screens/add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _refreshTransactionList();
  }

  void _refreshTransactionList() {
    setState(() {
      _transactionsFuture = _getTransactions();
    });
  }

  Future<List<Transaction>> _getTransactions() async {
    final dbHelper = DatabaseHelper.instance;
    final transactionMaps = await dbHelper.queryAllTransactions();

    // Ajoute des catégories par défaut si la table est vide.
    final categories = await dbHelper.queryAllCategories();
    if (categories.isEmpty) {
      await dbHelper.insertCategory({'name': 'Salaire', 'icon': 'trending-up', 'color': '0xFF4CAF50'});
      await dbHelper.insertCategory({'name': 'Courses', 'icon': 'shopping-cart', 'color': '0xFFF44336'});
      await dbHelper.insertCategory({'name': 'Loisirs', 'icon': 'gamepad-2', 'color': '0xFF2196F3'});
      await dbHelper.insertCategory({'name': 'Transport', 'icon': 'car', 'color': '0xFFFFC107'});
    }

    return transactionMaps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.deleteTransaction(transaction.id!);
    _refreshTransactionList();
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );
    if (result == true) {
      _refreshTransactionList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune transaction trouvée.'));
          } else {
            final transactions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return TransactionListItem(
                  transaction: transactions[index],
                  onEdit: _editTransaction,
                  onDelete: _deleteTransaction,
                );
              },
            );
          }
        },
      ),
    );
  }
}
