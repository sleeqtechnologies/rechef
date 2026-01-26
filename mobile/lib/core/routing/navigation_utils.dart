import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationUtils {
  NavigationUtils._();

  static void goToSignIn(BuildContext context) {
    context.go('/');
  }

  static void goToRecipes(BuildContext context) {
    context.go('/recipes');
  }

  static void goToRecipeDetail(BuildContext context, String recipeId) {
    context.go('/recipes/$recipeId');
  }

  static void goToRecipeImport(
    BuildContext context, {
    String? url,
    String? imagePath,
  }) {
    final uri = Uri(
      path: '/recipes/import',
      queryParameters: {
        if (url != null) 'url': url,
        if (imagePath != null) 'image': imagePath,
      },
    );
    context.go(uri.toString());
  }

  static void goToPantry(BuildContext context) {
    context.go('/pantry');
  }

  static void goToGroceryList(BuildContext context, {List<String>? recipeIds}) {
    final uri = Uri(
      path: '/grocery',
      queryParameters: recipeIds != null && recipeIds.isNotEmpty
          ? {'recipes': recipeIds.join(',')}
          : null,
    );
    context.go(uri.toString());
  }

  static void goToMealPlan(BuildContext context) {
    context.go('/meal-plan');
  }

  static void goToInstacartCallback(BuildContext context, {String? cartId}) {
    final uri = Uri(
      path: '/instacart/callback',
      queryParameters: cartId != null ? {'cart_id': cartId} : null,
    );
    context.go(uri.toString());
  }

  /// Push a route (for modals/sheets)
  static Future<T?> push<T>(
    BuildContext context,
    String path, {
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
    Object? extra,
  }) {
    // Build the location string with query parameters if provided
    String location = path;
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final uri = Uri(path: path, queryParameters: queryParameters);
      location = uri.toString();
    }
    
    // For path parameters, they should already be in the path string
    // e.g., '/recipes/:id' should be called as '/recipes/123'
    return context.push<T>(
      location,
      extra: extra,
    );
  }

  /// Pop current route
  static void pop<T>(BuildContext context, [T? result]) {
    context.pop(result);
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return context.canPop();
  }
}
