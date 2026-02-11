class Cookbook {
  const Cookbook({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.recipeCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final int recipeCount;

  Cookbook copyWith({
    String? name,
    String? description,
    String? coverImageUrl,
    int? recipeCount,
  }) =>
      Cookbook(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        recipeCount: recipeCount ?? this.recipeCount,
      );

  factory Cookbook.fromJson(Map<String, dynamic> json) {
    return Cookbook(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      recipeCount: json['recipeCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        'recipeCount': recipeCount,
      };
}
