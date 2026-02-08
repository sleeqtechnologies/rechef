class ApiEndpoints {
  ApiEndpoints._();

  // Content parsing
  static String get parseContent => '/api/contents/parse';

  // Content jobs
  static String get contentJobs => '/api/contents/jobs';
  static String contentJob(String jobId) => '/api/contents/jobs/$jobId';

  // Recipe endpoints
  static String get recipes => '/api/recipes';
  static String recipe(String id) => '/api/recipes/$id';
  static String matchPantry(String recipeId) =>
      '/api/recipes/$recipeId/match-pantry';
  static String toggleIngredient(String recipeId, int index) =>
      '/api/recipes/$recipeId/ingredients/$index';
  static String recipeChat(String recipeId) =>
      '/api/recipes/$recipeId/chat';

  // Pantry endpoints
  static String get pantry => '/api/pantry';
  static String pantryItem(String id) => '/api/pantry/$id';

  // Grocery list endpoints
  static String get grocery => '/api/grocery';
  static String groceryItem(String id) => '/api/grocery/$id';
  static String get groceryChecked => '/api/grocery/checked';

  // Instacart / ordering
  static String get groceryOrder => '/api/grocery/order';
}
