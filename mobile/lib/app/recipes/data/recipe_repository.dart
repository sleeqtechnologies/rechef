import 'dart:convert';
import '../domain/ingredient.dart';
import '../domain/recipe.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';

class RecipeRepository {
  RecipeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Recipe>> fetchAll() async {
    final response = await _apiClient.get(ApiEndpoints.recipes);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch recipes');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['recipes'] as List<dynamic>;
    return list
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Recipe> save(Recipe recipe) async {
    final response = await _apiClient.post(
      ApiEndpoints.recipes,
      body: recipe.toJson(),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to save recipe');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final recipeJson = data['recipe'] as Map<String, dynamic>;
    return Recipe.fromJson(recipeJson);
  }

  Future<Recipe> update(Recipe recipe) async {
    final response = await _apiClient.put(
      ApiEndpoints.recipe(recipe.id),
      body: recipe.toJson(),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update recipe');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final recipeJson = data['recipe'] as Map<String, dynamic>;
    return Recipe.fromJson(recipeJson);
  }

  Future<List<Ingredient>> matchPantry(String recipeId) async {
    final response = await _apiClient.post(
      ApiEndpoints.matchPantry(recipeId),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to match pantry');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['ingredients'] as List<dynamic>;
    return list
        .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Ingredient> toggleIngredient(String recipeId, int index) async {
    final response = await _apiClient.patch(
      ApiEndpoints.toggleIngredient(recipeId, index),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle ingredient');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Ingredient.fromJson(data['ingredient'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.recipe(id));

    if (response.statusCode != 200) {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete recipe');
      } catch (_) {
        throw Exception('Failed to delete recipe');
      }
    }
  }


  Future<List<Map<String, dynamic>>> fetchChatHistory(String recipeId) async {
    final response = await _apiClient.get(ApiEndpoints.recipeChat(recipeId));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch chat history');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['messages'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> sendChatMessage(
    String recipeId, {
    required String message,
    String? imageBase64,
    int? currentStep,
  }) async {
    final body = <String, dynamic>{'message': message};
    if (imageBase64 != null) body['imageBase64'] = imageBase64;
    if (currentStep != null) body['currentStep'] = currentStep;

    final response = await _apiClient.post(
      ApiEndpoints.recipeChat(recipeId),
      body: body,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to send message');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
