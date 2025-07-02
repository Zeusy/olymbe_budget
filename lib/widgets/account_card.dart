import 'package:olymbe_budget/models/account.dart';
import 'package:olymbe_budget/utils/colors.dart';
import 'package:flutter/material.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final double currentBalance;
  final VoidCallback? onTap;
  final Function(Account)? onEdit;
  final Function(Account)? onDelete;
  final Function(Account)? onToggleIgnored;

  const AccountCard({
    super.key,
    required this.account,
    required this.currentBalance,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleIgnored,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(account.id.toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Confirmer la suppression"),
                content: Text("Voulez-vous vraiment supprimer le compte '${account.name}' ?"),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Annuler"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Supprimer"),
                  ),
                ],
              );
            },
          );
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onDelete?.call(account);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: () {
              try {
                return Color(int.parse(account.color));
              } catch (e) {
                print('Error parsing color: ${account.color}, using default. Error: $e');
                return AppColors.primary;
              }
            }(),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white),
          ),
          title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Solde: ${currentBalance.toStringAsFixed(2)} €'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  account.isIgnored ? Icons.visibility_off : Icons.visibility,
                  color: account.isIgnored ? Colors.grey : AppColors.primary,
                ),
                onPressed: () => onToggleIgnored?.call(account),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => onEdit?.call(account),
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}