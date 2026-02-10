import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/ingredient.dart';
import '../domain/recipe.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/config/env.dart';

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

  Stream<Map<String, dynamic>> sendChatMessageStream(
    String recipeId, {
    required String message,
    String? imageBase64,
    int? currentStep,
  }) async* {
    final body = <String, dynamic>{'message': message};
    if (imageBase64 != null) body['imageBase64'] = imageBase64;
    if (currentStep != null) body['currentStep'] = currentStep;

    final response = await _apiClient.postStream(
      ApiEndpoints.recipeChat(recipeId),
      body: body,
    );

    if (response.statusCode != 200) {
      final bodyStr = await response.stream.bytesToString();
      final error = jsonDecode(bodyStr) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to send message');
    }

    var buffer = '';
    await for (final bytes in response.stream.transform(utf8.decoder)) {
      buffer += bytes;

      while (buffer.contains('\n\n')) {
        final idx = buffer.indexOf('\n\n');
        final raw = buffer.substring(0, idx);
        buffer = buffer.substring(idx + 2);

        String? event;
        String? data;
        for (final line in raw.split('\n')) {
          if (line.startsWith('event: ')) event = line.substring(7);
          if (line.startsWith('data: ')) data = line.substring(6);
        }

        if (data == null || event == null) continue;

        final parsed = jsonDecode(data) as Map<String, dynamic>;
        parsed['_event'] = event;
        yield parsed;
      }
    }
  }

  /// Fetch a shared recipe from the public endpoint (no auth required)
  Future<Recipe> fetchSharedRecipe(String shareCode) async {
    final url = Uri.parse('$apiBaseUrl${ApiEndpoints.getSharedRecipePublic(shareCode)}');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to fetch shared recipe');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final recipeJson = data['recipe'] as Map<String, dynamic>;
    return Recipe.fromJson(recipeJson);
  }

  /// Save a shared recipe to the user's library
  Future<Recipe> saveSharedRecipe(String shareCode) async {
    final response = await _apiClient.post(
      ApiEndpoints.saveSharedRecipe(shareCode),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to save shared recipe');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final recipeJson = data['recipe'] as Map<String, dynamic>;
    return Recipe.fromJson(recipeJson);
  }

  Future<void> removeSharedRecipe(String sharedSaveId) async {
    final response =
        await _apiClient.delete(ApiEndpoints.removeSharedRecipe(sharedSaveId));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to remove shared recipe');
    }
  }

  Future<Map<String, dynamic>> fetchShareStats(String recipeId) async {
    final response = await _apiClient.get(ApiEndpoints.shareStats(recipeId));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to fetch share stats');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final stats = data['stats'] as Map<String, dynamic>?;
    return stats ?? {};
  }
}
