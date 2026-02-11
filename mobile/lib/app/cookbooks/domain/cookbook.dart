class Cookbook {
  const Cookbook({
    required this.id,
    required this.name,
    this.description,
    this.coverImages = const [],
    this.recipeCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final List<String> coverImages;
  final int recipeCount;

  Cookbook copyWith({
    String? name,
    String? description,
    List<String>? coverImages,
    int? recipeCount,
  }) =>
      Cookbook(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        coverImages: coverImages ?? this.coverImages,
        recipeCount: recipeCount ?? this.recipeCount,
      );

  factory Cookbook.fromJson(Map<String, dynamic> json) {
    final images = (json['coverImages'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    return Cookbook(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImages: images,
      recipeCount: json['recipeCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'coverImages': coverImages,
        'recipeCount': recipeCount,
      };
}
