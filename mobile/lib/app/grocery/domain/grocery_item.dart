class GroceryItem {
  const GroceryItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    required this.category,
    required this.checked,
    this.recipeId,
    this.recipeName,
  });

  final String id;
  final String name;
  final String? quantity;
  final String? unit;
  final String category;
  final bool checked;
  final String? recipeId;
  final String? recipeName;

  String get displayQuantity {
    final parts = [quantity, unit].where((e) => e != null && e.isNotEmpty);
    return parts.join(' ');
  }

  GroceryItem copyWith({bool? checked}) => GroceryItem(
    id: id,
    name: name,
    quantity: quantity,
    unit: unit,
    category: category,
    checked: checked ?? this.checked,
    recipeId: recipeId,
    recipeName: recipeName,
  );

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String?,
      unit: json['unit'] as String?,
      category: json['category'] as String? ?? 'Other',
      checked: json['checked'] as bool? ?? false,
      recipeId: json['recipeId'] as String?,
      recipeName: json['recipeName'] as String?,
    );
  }
}
