import 'dart:convert';
import '../../recipes/domain/recipe.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';

class ImportRepository {
  ImportRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Recipe> parseContent(String url) async {
    final response = await _apiClient.post(
      ApiEndpoints.parseContent,
      body: {'url': url},
    );

    if (response.statusCode != 200) {
      if (response.body.isEmpty) {
        throw Exception(
          'Server returned status ${response.statusCode} with no response',
        );
      }
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to parse content');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final recipeJson = data['recipe'] as Map<String, dynamic>;
    return Recipe.fromJson(recipeJson);
  }
}
