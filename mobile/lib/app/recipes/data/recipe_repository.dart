import 'dart:convert';
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

  Future<void> delete(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.recipe(id));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete recipe');
    }
  }
}
