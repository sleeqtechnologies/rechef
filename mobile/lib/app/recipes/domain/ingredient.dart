class Ingredient {
  const Ingredient({
    required this.name,
    required this.quantity,
    this.unit,
    this.notes,
    this.inPantry = false,
  });

  final String name;
  final String quantity;
  final String? unit;
  final String? notes;
  final bool inPantry;

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
      inPantry: json['inPantry'] as bool? ?? false,
    );
  }

  Ingredient copyWith({
    String? name,
    String? quantity,
    String? unit,
    String? notes,
    bool? inPantry,
  }) =>
      Ingredient(
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        notes: notes ?? this.notes,
        inPantry: inPantry ?? this.inPantry,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    if (unit != null) 'unit': unit,
    if (notes != null) 'notes': notes,
    if (inPantry) 'inPantry': inPantry,
  };
}
