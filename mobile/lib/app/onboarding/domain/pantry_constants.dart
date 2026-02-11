/// Hardcoded pantry staples grouped by category for the onboarding pantry setup.
class PantryConstants {
  PantryConstants._();

  static const Map<String, List<String>> categories = {
    'Dairy & Eggs': [
      'Milk',
      'Eggs',
      'Butter',
      'Cheese',
      'Yogurt',
      'Cream',
      'Sour Cream',
    ],
    'Proteins': [
      'Chicken',
      'Ground Beef',
      'Salmon',
      'Shrimp',
      'Tofu',
      'Bacon',
    ],
    'Grains & Pasta': [
      'Rice',
      'Pasta',
      'Bread',
      'Flour',
      'Oats',
      'Tortillas',
      'Quinoa',
    ],
    'Oils & Condiments': [
      'Olive Oil',
      'Vegetable Oil',
      'Soy Sauce',
      'Vinegar',
      'Ketchup',
      'Mustard',
      'Hot Sauce',
      'Honey',
    ],
    'Spices': [
      'Salt',
      'Pepper',
      'Garlic Powder',
      'Paprika',
      'Cumin',
      'Oregano',
      'Cinnamon',
      'Chili Powder',
    ],
    'Produce': [
      'Onions',
      'Garlic',
      'Tomatoes',
      'Potatoes',
      'Lemons',
      'Ginger',
    ],
    'Canned & Pantry': [
      'Canned Tomatoes',
      'Chicken Broth',
      'Beans',
      'Coconut Milk',
      'Peanut Butter',
    ],
  };

  /// Returns a flat list of all pantry items.
  static List<String> get allItems =>
      categories.values.expand((items) => items).toList();
}
