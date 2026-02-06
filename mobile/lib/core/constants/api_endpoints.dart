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

  // Pantry endpoints
  static String get pantry => '/api/pantry';
  static String pantryItem(String id) => '/api/pantry/$id';

  // Grocery list endpoints
  static String get groceryList => '/api/grocery';
  static String generateGroceryList(List<String> recipeIds) =>
      '/api/grocery/generate?recipes=${recipeIds.join(',')}';

  // Instacart endpoints
  static String get instacartCart => '/api/instacart/cart';
}
