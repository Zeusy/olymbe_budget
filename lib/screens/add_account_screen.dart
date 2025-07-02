
import 'package:olymbe_budget/data/database_helper.dart';
import 'package:olymbe_budget/models/account.dart';
import 'package:olymbe_budget/utils/colors.dart';
import 'package:flutter/material.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account;

  const AddAccountScreen({super.key, this.account});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.initialBalance.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final balance = double.tryParse(_balanceController.text) ?? 0.0;
      final color = widget.account?.color ?? '0xFFF5A623'; // Keep existing color or default

      final dbHelper = DatabaseHelper.instance;
      if (widget.account == null) {
        // Add new account
        await dbHelper.insertAccount({
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnInitialBalance: balance,
          DatabaseHelper.columnColor: color,
        });
      } else {
        // Update existing account
        await dbHelper.updateAccount({
          DatabaseHelper.columnId: widget.account!.id,
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnInitialBalance: balance,
          DatabaseHelper.columnColor: color,
        });
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Retourne true pour indiquer un succès
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'Ajouter un compte' : 'Modifier le compte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du compte',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Solde initial',
                  border: OutlineInputBorder(),
                  suffixText: '€',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un solde';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: Text(widget.account == null ? 'Enregistrer' : 'Modifier', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
