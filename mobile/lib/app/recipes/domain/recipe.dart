import 'ingredient.dart';

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    this.description = '',
    required this.ingredients,
    required this.instructions,
    this.servings,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final int? servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final String? imageUrl;

  int get totalMinutes => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);

  int get ingredientsInPantry => ingredients.where((i) => i.inPantry).length;

  Recipe copyWith({List<Ingredient>? ingredients}) => Recipe(
    id: id,
    name: name,
    description: description,
    ingredients: ingredients ?? this.ingredients,
    instructions: instructions,
    servings: servings,
    prepTimeMinutes: prepTimeMinutes,
    cookTimeMinutes: cookTimeMinutes,
    imageUrl: imageUrl,
  );

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients =
        (json['ingredients'] as List<dynamic>?)
            ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final instructions =
        (json['instructions'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    return Recipe(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Untitled Recipe',
      description: json['description'] as String? ?? '',
      ingredients: ingredients,
      instructions: instructions,
      servings: json['servings'] as int?,
      prepTimeMinutes: json['prepTimeMinutes'] as int?,
      cookTimeMinutes: json['cookTimeMinutes'] as int?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'instructions': instructions,
    if (servings != null) 'servings': servings,
    if (prepTimeMinutes != null) 'prepTimeMinutes': prepTimeMinutes,
    if (cookTimeMinutes != null) 'cookTimeMinutes': cookTimeMinutes,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}
