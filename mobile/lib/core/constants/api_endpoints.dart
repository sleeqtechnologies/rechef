import '../config/env.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => apiBaseUrl;

  // Content parsing
  static String get parseContent => '/api/contents/parse';

  // Recipe endpoints
  static String get importRecipe => '$baseUrl/api/recipes/import';
  static String get extractFromImage => '$baseUrl/api/recipes/extract';
  static String get recipes => '$baseUrl/api/recipes';
  static String recipe(String id) => '$baseUrl/api/recipes/$id';

  // Pantry endpoints
  static String get pantry => '$baseUrl/api/pantry';
  static String pantryItem(String id) => '$baseUrl/api/pantry/$id';

  // Grocery list endpoints
  static String get groceryList => '$baseUrl/api/grocery';
  static String generateGroceryList(List<String> recipeIds) =>
      '$baseUrl/api/grocery/generate?recipes=${recipeIds.join(',')}';

  // Instacart endpoints
  static String get instacartCart => '$baseUrl/api/instacart/cart';
}
