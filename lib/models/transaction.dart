/// Enum pour le type de transaction.
enum TransactionType { income, expense }

/// Modèle de données pour une transaction.
class Transaction {
  final int? id;
  final int accountId;
  final int categoryId;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? description;

  Transaction({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    this.description,
  });

  /// Convertit un objet Transaction en Map.
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'type': type.toString().split('.').last, // Stocke "income" ou "expense"
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  /// Crée un objet Transaction à partir d'une Map.
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['_id'],
      accountId: map['accountId'],
      categoryId: map['categoryId'],
      amount: map['amount'],
      type: TransactionType.values.firstWhere((e) => e.toString().split('.').last == map['type']),
      date: DateTime.parse(map['date']),
      description: map['description'],
    );
  }

  Transaction copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? description,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}