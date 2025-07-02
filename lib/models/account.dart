/// Modèle de données pour un compte bancaire.
class Account {
  final int? id;
  final String name;
  final double initialBalance;
  final String color;
  final bool isIgnored;

  Account({
    this.id,
    required this.name,
    required this.initialBalance,
    required this.color,
    this.isIgnored = false,
  });

  /// Convertit un objet Account en Map.
  /// Utile pour l'insertion dans la base de données.
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'initialBalance': initialBalance,
      'color': color,
      'is_ignored': isIgnored ? 1 : 0,
    };
  }

  /// Crée un objet Account à partir d'une Map.
  /// Utile pour la lecture depuis la base de données.
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['_id'],
      name: map['name'],
      initialBalance: map['initialBalance'],
      color: map['color'],
      isIgnored: map['is_ignored'] == 1 ? true : false,
    );
  }

  Account copyWith({
    int? id,
    String? name,
    double? initialBalance,
    String? color,
    bool? isIgnored,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      color: color ?? this.color,
      isIgnored: isIgnored ?? this.isIgnored,
    );
  }
}