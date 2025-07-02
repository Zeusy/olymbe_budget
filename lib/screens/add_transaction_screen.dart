
import 'package:olymbe_budget/data/database_helper.dart';
import 'package:olymbe_budget/models/account.dart';
import 'package:olymbe_budget/models/category.dart';
import 'package:olymbe_budget/models/transaction.dart';
import 'package:olymbe_budget/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  Account? _selectedAccount;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  List<Account> _accounts = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.transaction != null) {
      _descriptionController.text = widget.transaction!.description ?? '';
      _amountController.text = widget.transaction!.amount.toString();
      _selectedType = widget.transaction!.type;
      _selectedDate = widget.transaction!.date;
    }
  }

  Future<void> _loadData() async {
    final dbHelper = DatabaseHelper.instance;
    final accountMaps = await dbHelper.queryAllAccounts();
    final categoryMaps = await dbHelper.queryAllCategories();
    setState(() {
      _accounts = accountMaps.map((map) => Account.fromMap(map)).toList();
      _categories = categoryMaps.map((map) => Category.fromMap(map)).toList();
      if (_accounts.isNotEmpty) {
        _selectedAccount = _accounts.first;
      }
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
      }
    });
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate() && _selectedAccount != null && _selectedCategory != null) {
      final description = _descriptionController.text;
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      final dbHelper = DatabaseHelper.instance;

      if (widget.transaction == null) {
        // Add new transaction
        final newTransaction = Transaction(
          accountId: _selectedAccount!.id!,
          categoryId: _selectedCategory!.id!,
          amount: amount,
          type: _selectedType,
          date: _selectedDate,
          description: description,
        );
        await dbHelper.insertTransaction(newTransaction.toMap());
      } else {
        // Update existing transaction
        final updatedTransaction = widget.transaction!.copyWith(
          accountId: _selectedAccount!.id!,
          categoryId: _selectedCategory!.id!,
          amount: amount,
          type: _selectedType,
          date: _selectedDate,
          description: description,
        );
        await dbHelper.updateTransaction(updatedTransaction.toMap());
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
        title: Text(widget.transaction == null ? 'Ajouter une transaction' : 'Modifier la transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Veuillez entrer une description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Montant', suffixText: '€'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Veuillez entrer un montant' : null,
              ),
              const SizedBox(height: 16),
              _buildAccountSelector(),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildDateSelector(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<TransactionType>(
      segments: const [
        ButtonSegment(value: TransactionType.expense, label: Text('Dépense'), icon: Icon(Icons.arrow_downward)),
        ButtonSegment(value: TransactionType.income, label: Text('Revenu'), icon: Icon(Icons.arrow_upward)),
      ],
      selected: {_selectedType},
      onSelectionChanged: (newSelection) {
        setState(() {
          _selectedType = newSelection.first;
        });
      },
    );
  }

  Widget _buildAccountSelector() {
    return DropdownButtonFormField<Account>(
      value: _selectedAccount,
      items: _accounts.map((account) {
        return DropdownMenuItem(value: account, child: Text(account.name));
      }).toList(),
      onChanged: (value) => setState(() => _selectedAccount = value),
      decoration: const InputDecoration(labelText: 'Compte'),
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<Category>(
      value: _selectedCategory,
      items: _categories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category.name));
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value),
      decoration: const InputDecoration(labelText: 'Catégorie'),
    );
  }

  Widget _buildDateSelector() {
    return ListTile(
      title: Text('Date: ${DateFormat.yMMMd('fr_FR').format(_selectedDate)}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null && pickedDate != _selectedDate) {
          setState(() {
            _selectedDate = pickedDate;
          });
        }
      },
    );
  }
}
