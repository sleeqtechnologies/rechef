class NutritionFacts {
  const NutritionFacts({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  /// Calories per serving (kcal).
  final double calories;

  /// Protein per serving in grams.
  final double proteinGrams;

  /// Carbohydrates per serving in grams.
  final double carbsGrams;

  /// Fat per serving in grams.
  final double fatGrams;

  factory NutritionFacts.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      return 0;
    }

    return NutritionFacts(
      calories: _toDouble(json['calories']),
      proteinGrams: _toDouble(json['protein_g']),
      carbsGrams: _toDouble(json['carbs_g']),
      fatGrams: _toDouble(json['fat_g']),
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein_g': proteinGrams,
        'carbs_g': carbsGrams,
        'fat_g': fatGrams,
      };

  double get totalMacroGrams => proteinGrams + carbsGrams + fatGrams;

  bool get hasAnyMacros =>
      proteinGrams > 0 || carbsGrams > 0 || fatGrams > 0 || calories > 0;
}

