
import 'package:olymbe_budget/models/transaction.dart';
import 'package:olymbe_budget/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Function(Transaction)? onEdit;
  final Function(Transaction)? onDelete;

  const TransactionListItem({super.key, required this.transaction, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    return Dismissible(
      key: Key(transaction.id.toString()), // Unique key for Dismissible
      direction: DismissDirection.horizontal, // Allow swipe in both directions
      background: Container(
        color: Colors.red, // Background color when swiping for delete
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.blue, // Background color when swiping for edit
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onEdit?.call(transaction);
        } else if (direction == DismissDirection.startToEnd) {
          onDelete?.call(transaction);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(transaction.description ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat.yMMMd('fr_FR').format(transaction.date)),
          trailing: Text(
            '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
