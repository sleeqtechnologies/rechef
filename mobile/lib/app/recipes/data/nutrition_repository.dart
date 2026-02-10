import 'dart:convert';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/nutrition_facts.dart';

class NutritionRepository {
  NutritionRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<NutritionFacts> fetchNutrition(String recipeId) async {
    final response =
        await _apiClient.get(ApiEndpoints.recipeNutrition(recipeId));

    if (response.statusCode != 200) {
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorBody['error'] ?? 'Failed to fetch nutrition');
      } catch (_) {
        throw Exception('Failed to fetch nutrition');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final nutritionJson = data['nutrition'];

    if (nutritionJson is! Map<String, dynamic>) {
      throw Exception('Invalid nutrition response format');
    }

    return NutritionFacts.fromJson(nutritionJson);
  }
}

