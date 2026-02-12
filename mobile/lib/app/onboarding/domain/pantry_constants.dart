import 'package:easy_localization/easy_localization.dart';

class PantryConstantItem {
  const PantryConstantItem({required this.name, this.nameKey, this.imageUrl});

  final String name;
  final String? nameKey;
  final String? imageUrl;

  String get displayName => nameKey != null ? nameKey!.tr() : name;

  PantryConstantItem copyWith({String? imageUrl}) {
    return PantryConstantItem(
      name: name,
      nameKey: nameKey,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class PantryConstants {
  PantryConstants._();

  static const Map<String, String> categoryDisplayKeys = {
    'Dairy & Eggs': 'pantry_items.dairy_eggs',
    'Proteins': 'pantry_items.proteins',
    'Grains & Pasta': 'pantry_items.grains_pasta',
    'Oils & Condiments': 'pantry_items.oils_condiments',
    'Spices': 'pantry_items.spices',
    'Produce': 'pantry_items.produce',
    'Canned & Pantry': 'pantry_items.canned_pantry',
  };

  static const Map<String, List<PantryConstantItem>> categories = {
    'Dairy & Eggs': [
      PantryConstantItem(name: 'Milk', nameKey: 'pantry_items.milk'),
      PantryConstantItem(name: 'Eggs', nameKey: 'pantry_items.eggs'),
      PantryConstantItem(name: 'Butter', nameKey: 'pantry_items.butter'),
      PantryConstantItem(name: 'Cheese', nameKey: 'pantry_items.cheese'),
      PantryConstantItem(name: 'Yogurt', nameKey: 'pantry_items.yogurt'),
      PantryConstantItem(name: 'Cream', nameKey: 'pantry_items.cream'),
      PantryConstantItem(name: 'Sour Cream', nameKey: 'pantry_items.sour_cream'),
    ],
    'Proteins': [
      PantryConstantItem(name: 'Chicken', nameKey: 'pantry_items.chicken'),
      PantryConstantItem(name: 'Ground Beef', nameKey: 'pantry_items.ground_beef'),
      PantryConstantItem(name: 'Salmon', nameKey: 'pantry_items.salmon'),
      PantryConstantItem(name: 'Shrimp', nameKey: 'pantry_items.shrimp'),
      PantryConstantItem(name: 'Tofu', nameKey: 'pantry_items.tofu'),
      PantryConstantItem(name: 'Bacon', nameKey: 'pantry_items.bacon'),
    ],
    'Grains & Pasta': [
      PantryConstantItem(name: 'Rice', nameKey: 'pantry_items.rice'),
      PantryConstantItem(name: 'Pasta', nameKey: 'pantry_items.pasta'),
      PantryConstantItem(name: 'Bread', nameKey: 'pantry_items.bread'),
      PantryConstantItem(name: 'Flour', nameKey: 'pantry_items.flour'),
      PantryConstantItem(name: 'Oats', nameKey: 'pantry_items.oats'),
      PantryConstantItem(name: 'Tortillas', nameKey: 'pantry_items.tortillas'),
      PantryConstantItem(name: 'Quinoa', nameKey: 'pantry_items.quinoa'),
    ],
    'Oils & Condiments': [
      PantryConstantItem(name: 'Olive Oil', nameKey: 'pantry_items.olive_oil'),
      PantryConstantItem(name: 'Vegetable Oil', nameKey: 'pantry_items.vegetable_oil'),
      PantryConstantItem(name: 'Soy Sauce', nameKey: 'pantry_items.soy_sauce'),
      PantryConstantItem(name: 'Vinegar', nameKey: 'pantry_items.vinegar'),
      PantryConstantItem(name: 'Ketchup', nameKey: 'pantry_items.ketchup'),
      PantryConstantItem(name: 'Mustard', nameKey: 'pantry_items.mustard'),
      PantryConstantItem(name: 'Hot Sauce', nameKey: 'pantry_items.hot_sauce'),
      PantryConstantItem(name: 'Honey', nameKey: 'pantry_items.honey'),
    ],
    'Spices': [
      PantryConstantItem(name: 'Salt', nameKey: 'pantry_items.salt'),
      PantryConstantItem(name: 'Pepper', nameKey: 'pantry_items.pepper'),
      PantryConstantItem(name: 'Garlic Powder', nameKey: 'pantry_items.garlic_powder'),
      PantryConstantItem(name: 'Paprika', nameKey: 'pantry_items.paprika'),
      PantryConstantItem(name: 'Cumin', nameKey: 'pantry_items.cumin'),
      PantryConstantItem(name: 'Oregano', nameKey: 'pantry_items.oregano'),
      PantryConstantItem(name: 'Cinnamon', nameKey: 'pantry_items.cinnamon'),
      PantryConstantItem(name: 'Chili Powder', nameKey: 'pantry_items.chili_powder'),
    ],
    'Produce': [
      PantryConstantItem(name: 'Onions', nameKey: 'pantry_items.onions'),
      PantryConstantItem(name: 'Garlic', nameKey: 'pantry_items.garlic'),
      PantryConstantItem(name: 'Tomatoes', nameKey: 'pantry_items.tomatoes'),
      PantryConstantItem(name: 'Potatoes', nameKey: 'pantry_items.potatoes'),
      PantryConstantItem(name: 'Lemons', nameKey: 'pantry_items.lemons'),
      PantryConstantItem(name: 'Ginger', nameKey: 'pantry_items.ginger'),
    ],
    'Canned & Pantry': [
      PantryConstantItem(name: 'Canned Tomatoes', nameKey: 'pantry_items.canned_tomatoes'),
      PantryConstantItem(name: 'Chicken Broth', nameKey: 'pantry_items.chicken_broth'),
      PantryConstantItem(name: 'Beans', nameKey: 'pantry_items.beans'),
      PantryConstantItem(name: 'Coconut Milk', nameKey: 'pantry_items.coconut_milk'),
      PantryConstantItem(name: 'Peanut Butter', nameKey: 'pantry_items.peanut_butter'),
    ],
  };

  static List<String> get allItemNames => categories.values
      .expand((items) => items)
      .map((item) => item.name)
      .toList();
}
