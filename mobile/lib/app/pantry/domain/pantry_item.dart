class PantryItem {
  const PantryItem({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String category;
  final String? imageUrl;

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Other',
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'imageUrl': imageUrl,
  };
}
