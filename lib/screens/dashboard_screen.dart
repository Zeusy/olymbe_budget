import 'package:provider/provider.dart';
import 'package:olymbe_budget/data/database_helper.dart';
import 'package:olymbe_budget/models/transaction.dart';
import 'package:olymbe_budget/screens/add_transaction_screen.dart';
import 'package:olymbe_budget/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:olymbe_budget/screens/settings_screen.dart';
import 'package:olymbe_budget/widgets/transaction_list_item.dart';
import 'package:olymbe_budget/main.dart';
import 'package:olymbe_budget/models/account.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<void> _dataLoadingFuture;
  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  List<Map<String, dynamic>> _expensesByCategory = [];
  List<Transaction> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _dataLoadingFuture = _refreshData();
  }

  Future<void> _refreshData() async {
    final dbHelper = DatabaseHelper.instance;

    final allAccounts = await dbHelper.queryAllAccounts();
    double calculatedTotalBalance = 0.0;
    for (var accountMap in allAccounts) {
      final account = Account.fromMap(accountMap);
      if (!account.isIgnored) {
        calculatedTotalBalance += await dbHelper.getAccountBalance(account.id!); 
      }
    }

    final transactions = await dbHelper.queryAllTransactions();
    double income = 0.0;
    double expense = 0.0;
    final now = DateTime.now();
    final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    for (var transactionMap in transactions) {
      final transactionDate = DateTime.parse(transactionMap[DatabaseHelper.columnDate]);
      final transactionMonth = "${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}";

      if (transactionMonth == currentMonth) {
        if (transactionMap[DatabaseHelper.columnType] == 'income') {
          income += transactionMap[DatabaseHelper.columnAmount];
        } else {
          expense += transactionMap[DatabaseHelper.columnAmount];
        }
      }
    }

    final expensesByCategory = await dbHelper.getExpensesByCategory();
    final recentTransactionsMaps = await dbHelper.queryLatestTransactions(5);

    if (mounted) {
      setState(() {
        _totalBalance = calculatedTotalBalance;
        _monthlyIncome = income;
        _monthlyExpense = expense;
        _expensesByCategory = expensesByCategory;
        _recentTransactions = recentTransactionsMaps.map((map) => Transaction.fromMap(map)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: Provider.of<ThemeModeNotifier>(context, listen: false),
                    child: const SettingsScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _dataLoadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            return _buildBody();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
          if (result == true) {
            setState(() {
              _dataLoadingFuture = _refreshData();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 24),
          _buildMonthlySummary(),
          const SizedBox(height: 24),
          _buildChart(),
          const SizedBox(height: 24),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solde total',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${_totalBalance.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé du mois',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildIncomeExpenseCard(
                title: 'Revenus',
                amount: _monthlyIncome,
                color: AppColors.income,
                icon: Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildIncomeExpenseCard(
                title: 'Dépenses',
                amount: _monthlyExpense,
                color: AppColors.expense,
                icon: Icons.arrow_downward,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${amount.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transactions récentes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 16),
        _recentTransactions.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text('Aucune transaction récente.'),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _recentTransactions[index];
                  return TransactionListItem(transaction: transaction);
                },
              ),
      ],
    );
  }

  Widget _buildChart() {
    if (_expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalExpenses = _expensesByCategory.fold(0.0, (sum, item) => sum + (item['total'] ?? 0.0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Répartition des dépenses',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _getChartSections(totalExpenses),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getChartSections(double totalExpenses) {
    return _expensesByCategory.map((data) {
      final categoryName = data['name'] as String;
      final total = data['total'] as double;
      final percentage = totalExpenses > 0 ? (total / totalExpenses * 100).toStringAsFixed(1) : '0.0';
      final colorString = data['color'] as String?;
      Color color = AppColors.primary;
      if (colorString != null && colorString.startsWith('0x')) {
        try {
          color = Color(int.parse(colorString));
        } catch (e) {
          color = AppColors.primary;
        }
      }

      return PieChartSectionData(
        color: color,
        value: total,
        title: '$categoryName $percentage%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}