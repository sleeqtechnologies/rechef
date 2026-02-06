class Ingredient {
  const Ingredient({
    required this.name,
    required this.quantity,
    this.unit,
    this.notes,
  });

  final String name;
  final String quantity;
  final String? unit;
  final String? notes;

  String get displayQuantity {
    final parts = [quantity, unit].where((e) => e != null && e.isNotEmpty);
    return parts.join(' ');
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (notes != null) 'notes': notes,
      };
}
