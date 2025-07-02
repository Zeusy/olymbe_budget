
/// Modèle de données pour une catégorie.
class Category {
  final int? id;
  final String name;
  final String icon;
  final String color;

  Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  /// Convertit un objet Category en Map.
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'icon': icon,
      'color': color,
    };
  }

  /// Crée un objet Category à partir d'une Map.
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['_id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
    );
  }
}
