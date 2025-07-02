import 'package:olymbe_budget/data/database_helper.dart';
import 'package:olymbe_budget/models/account.dart';
import 'package:olymbe_budget/widgets/account_card.dart';
import 'package:olymbe_budget/screens/add_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAccountList();
  }

  void _refreshAccountList() {
    setState(() {
      _accountsFuture = _getAccounts();
    });
  }

  Future<List<Account>> _getAccounts() async {
    final dbHelper = DatabaseHelper.instance;
    final accountMaps = await dbHelper.queryAllAccounts();

    if (accountMaps.isEmpty) {
      await dbHelper.insertAccount({
        DatabaseHelper.columnName: 'Compte Principal',
        DatabaseHelper.columnInitialBalance: 1000.0,
        DatabaseHelper.columnColor: '0xFF4A90E2',
        DatabaseHelper.columnIsIgnored: 0,
      });
      final refreshedAccountMaps = await dbHelper.queryAllAccounts();
      return refreshedAccountMaps.map((map) => Account.fromMap(map)).toList();
    }

    List<Account> accounts = [];
    for (var map in accountMaps) {
      final account = Account.fromMap(map);
      accounts.add(account);
    }
    return accounts;
  }

  void _toggleAccountIgnored(Account account) async {
    final dbHelper = DatabaseHelper.instance;
    final updatedAccount = account.copyWith(isIgnored: !account.isIgnored);
    await dbHelper.updateAccount(updatedAccount.toMap());
    _refreshAccountList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Comptes'),
      ),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun compte trouvé.'));
          } else {
            final accounts = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return FutureBuilder<double>(
                  future: DatabaseHelper.instance.getAccountBalance(account.id!),
                  builder: (context, balanceSnapshot) {
                    double currentBalance = balanceSnapshot.data ?? account.initialBalance;
                    return AccountCard(
                      account: account,
                      currentBalance: currentBalance,
                      onEdit: (accountToEdit) async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddAccountScreen(account: accountToEdit),
                          ),
                        );
                        if (result == true) {
                          _refreshAccountList();
                        }
                      },
                      onDelete: (accountToDelete) async {
                        await DatabaseHelper.instance.deleteAccount(accountToDelete.id!);
                        _refreshAccountList();
                      },
                      onToggleIgnored: _toggleAccountIgnored,
                    );
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddAccountScreen()),
          );
          if (result == true) {
            _refreshAccountList();
          }
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}