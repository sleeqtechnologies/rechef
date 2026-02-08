import 'dart:convert';
import '../domain/grocery_item.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';

class GroceryRepository {
  GroceryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<GroceryItem>> fetchAll() async {
    final response = await _apiClient.get(ApiEndpoints.grocery);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch grocery items');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>;
    return list
        .map((e) => GroceryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GroceryItem>> addItems({
    required String recipeId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.grocery,
      body: {
        'recipeId': recipeId,
        'items': items,
      },
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to add grocery items');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>;
    return list
        .map((e) => GroceryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GroceryItem> toggleItem(String id) async {
    final response = await _apiClient.patch(ApiEndpoints.groceryItem(id));

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle grocery item');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return GroceryItem.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<void> deleteItem(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.groceryItem(id));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete grocery item');
    }
  }

  Future<void> clearChecked() async {
    final response = await _apiClient.delete(ApiEndpoints.groceryChecked);

    if (response.statusCode != 200) {
      throw Exception('Failed to clear checked items');
    }
  }

  /// Creates an Instacart shopping list from unchecked grocery items.
  /// Returns the shareable Instacart URL.
  Future<String> createOrder() async {
    final response = await _apiClient.post(ApiEndpoints.groceryOrder);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Failed to create order');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
  }
}
