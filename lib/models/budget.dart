/// Modèle de données pour un budget.
class Budget {
  final int? id;
  final int categoryId;
  final double budgetAmount;
  final double currentAmount;
  final String month; // Format YYYY-MM

  Budget({
    this.id,
    required this.categoryId,
    required this.budgetAmount,
    this.currentAmount = 0.0,
    required this.month,
  });

  /// Convertit un objet Budget en Map.
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'categoryId': categoryId,
      'budgetAmount': budgetAmount,
      'currentAmount': currentAmount,
      'month': month,
    };
  }

  /// Crée un objet Budget à partir d'une Map.
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['_id'],
      categoryId: map['categoryId'],
      budgetAmount: map['budgetAmount'],
      currentAmount: map['currentAmount'],
      month: map['month'],
    );
  }

  Budget copyWith({
    int? id,
    int? categoryId,
    double? budgetAmount,
    double? currentAmount,
    String? month,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      month: month ?? this.month,
    );
  }
}