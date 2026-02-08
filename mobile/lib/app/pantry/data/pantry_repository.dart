import 'dart:convert';
import '../domain/pantry_item.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';

class PantryRepository {
  PantryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<PantryItem>> fetchAll() async {
    final response = await _apiClient.get(ApiEndpoints.pantry);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch pantry items');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>;
    return list
        .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PantryItem>> addItems(List<String> names) async {
    final response = await _apiClient.post(
      ApiEndpoints.pantry,
      body: {'items': names},
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to add pantry items');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>;
    return list
        .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.pantryItem(id));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete pantry item');
    }
  }
}
