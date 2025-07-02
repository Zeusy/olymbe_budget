import 'package:olymbe_budget/data/database_helper.dart';
import 'package:olymbe_budget/models/budget.dart';
import 'package:olymbe_budget/models/category.dart';
import 'package:olymbe_budget/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetAmountController = TextEditingController();

  Category? _selectedCategory;
  DateTime _selectedMonth = DateTime.now();

  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.budget != null) {
      _budgetAmountController.text = widget.budget!.budgetAmount.toString();
      _selectedMonth = DateFormat('yyyy-MM').parse(widget.budget!.month);
    }
  }

  Future<void> _loadCategories() async {
    final dbHelper = DatabaseHelper.instance;
    final categoryMaps = await dbHelper.queryAllCategories();
    setState(() {
      _categories = categoryMaps.map((map) => Category.fromMap(map)).toList();
      if (widget.budget != null) {
        _selectedCategory = _categories.firstWhere((cat) => cat.id == widget.budget!.categoryId);
      } else if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
      }
    });
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final budgetAmount = double.tryParse(_budgetAmountController.text) ?? 0.0;
      final month = DateFormat('yyyy-MM').format(_selectedMonth);

      final dbHelper = DatabaseHelper.instance;

      if (widget.budget == null) {
        // Add new budget
        final newBudget = Budget(
          categoryId: _selectedCategory!.id!,
          budgetAmount: budgetAmount,
          month: month,
        );
        await dbHelper.insertBudget(newBudget.toMap());
      } else {
        // Update existing budget
        final updatedBudget = widget.budget!.copyWith(
          categoryId: _selectedCategory!.id!,
          budgetAmount: budgetAmount,
          month: month,
        );
        await dbHelper.updateBudget(updatedBudget.toMap());
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? 'Ajouter un budget' : 'Modifier le budget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category.name));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                decoration: const InputDecoration(labelText: 'Catégorie'),
                validator: (value) => value == null ? 'Veuillez sélectionner une catégorie' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Montant du budget',
                  suffixText: '€',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Mois: ${DateFormat.yMMMM('fr_FR').format(_selectedMonth)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedMonth,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (pickedDate != null && pickedDate != _selectedMonth) {
                    setState(() {
                      _selectedMonth = DateTime(pickedDate.year, pickedDate.month, 1);
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveBudget,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}