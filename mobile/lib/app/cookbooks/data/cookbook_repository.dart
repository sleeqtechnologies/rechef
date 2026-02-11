import 'dart:convert';
import '../domain/cookbook.dart';
import '../../recipes/domain/recipe.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';

class CookbookRepository {
  CookbookRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CookbooksResponse> fetchAll() async {
    final response = await _apiClient.get(ApiEndpoints.cookbooks);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch cookbooks');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['cookbooks'] as List<dynamic>;
    final cookbooks = list
        .map((e) => Cookbook.fromJson(e as Map<String, dynamic>))
        .toList();

    return CookbooksResponse(
      cookbooks: cookbooks,
      allRecipesCount: data['allRecipesCount'] as int? ?? 0,
      sharedWithMeCount: data['sharedWithMeCount'] as int? ?? 0,
    );
  }

  Future<Cookbook> create({
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.cookbooks,
      body: {
        'name': name,
        if (description != null) 'description': description,
      },
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create cookbook');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Cookbook.fromJson(data['cookbook'] as Map<String, dynamic>);
  }

  Future<Cookbook> update({
    required String id,
    String? name,
    String? description,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.cookbook(id),
      body: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update cookbook');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Cookbook.fromJson(data['cookbook'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.cookbook(id));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to delete cookbook');
    }
  }

  Future<List<Recipe>> fetchRecipes(String cookbookId) async {
    final response =
        await _apiClient.get(ApiEndpoints.cookbookRecipes(cookbookId));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch cookbook recipes');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['recipes'] as List<dynamic>;
    return list
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addRecipes(String cookbookId, List<String> recipeIds) async {
    final response = await _apiClient.post(
      ApiEndpoints.cookbookRecipes(cookbookId),
      body: {'recipeIds': recipeIds},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to add recipes to cookbook');
    }
  }

  Future<void> removeRecipe(String cookbookId, String recipeId) async {
    final response = await _apiClient.delete(
      ApiEndpoints.cookbookRecipe(cookbookId, recipeId),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(
          error['error'] ?? 'Failed to remove recipe from cookbook');
    }
  }
}

class CookbooksResponse {
  const CookbooksResponse({
    required this.cookbooks,
    required this.allRecipesCount,
    required this.sharedWithMeCount,
  });

  final List<Cookbook> cookbooks;
  final int allRecipesCount;
  final int sharedWithMeCount;
}
