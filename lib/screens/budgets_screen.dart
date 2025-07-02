
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:olymbe_budget/data/database_helper.dart';
import 'package:olymbe_budget/models/budget.dart';
import 'package:olymbe_budget/screens/add_budget_screen.dart';
import 'package:olymbe_budget/widgets/budget_card.dart';
import 'package:intl/intl.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late Future<List<Budget>> _budgetsFuture;
  Map<int, String> _categoryNames = {};

  @override
  void initState() {
    super.initState();
    _refreshBudgetList();
  }

  void _refreshBudgetList() {
    setState(() {
      _budgetsFuture = _getBudgets();
    });
  }

  Future<List<Budget>> _getBudgets() async {
    final dbHelper = DatabaseHelper.instance;
    final budgetMaps = await dbHelper.queryAllBudgets();
    final categoryMaps = await dbHelper.queryAllCategories();

    _categoryNames = {
      for (var categoryMap in categoryMaps) categoryMap[DatabaseHelper.columnId]: categoryMap[DatabaseHelper.columnName]
    };

    List<Budget> budgets = [];
    for (var map in budgetMaps) {
      final budget = Budget.fromMap(map);
      final currentAmount = await dbHelper.getCategoryExpensesForMonth(budget.categoryId, budget.month);
      budgets.add(budget.copyWith(currentAmount: currentAmount));
    }
    return budgets;
  }

  void _navigateToEditBudget(Budget budget) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(budget: budget),
      ),
    );
    if (result == true) {
      _refreshBudgetList();
    }
  }

  void _deleteBudget(int id) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.deleteBudget(id);
    _refreshBudgetList();
  }

  void _showDeleteConfirmation(Budget budget) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le budget'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce budget ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Supprimer'),
              onPressed: () {
                _deleteBudget(budget.id!);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Budgets'),
      ),
      body: FutureBuilder<List<Budget>>(
        future: _budgetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun budget trouvé.'));
          } else {
            final budgets = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final categoryName = _categoryNames[budget.categoryId] ?? 'Inconnue';
                return BudgetCard(
                  budget: budget,
                  categoryName: categoryName,
                  onEdit: () => _navigateToEditBudget(budget),
                  onDelete: () => _showDeleteConfirmation(budget),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
          );
          if (result == true) {
            _refreshBudgetList();
          }
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
