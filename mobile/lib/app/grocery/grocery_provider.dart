import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../recipe_import/import_provider.dart';
import 'data/grocery_repository.dart';
import 'domain/grocery_item.dart';

final groceryRepositoryProvider = Provider<GroceryRepository>((ref) {
  return GroceryRepository(apiClient: ref.watch(apiClientProvider));
});

class GroceryNotifier extends AsyncNotifier<List<GroceryItem>> {
  @override
  Future<List<GroceryItem>> build() async {
    final repo = ref.read(groceryRepositoryProvider);
    return repo.fetchAll();
  }

  /// Returns the number of items actually added (after dedup).
  Future<int> addItems({
    required String recipeId,
    required List<Map<String, dynamic>> items,
  }) async {
    final repo = ref.read(groceryRepositoryProvider);
    final added = await repo.addItems(recipeId: recipeId, items: items);
    if (added.isNotEmpty) {
      state = AsyncData([...state.value ?? [], ...added]);
    }
    return added.length;
  }

  Future<void> toggleItem(String id) async {
    // Optimistic update
    final prev = state.value ?? [];
    final idx = prev.indexWhere((i) => i.id == id);
    if (idx == -1) return;

    final updated = List<GroceryItem>.from(prev);
    updated[idx] = updated[idx].copyWith(checked: !updated[idx].checked);
    state = AsyncData(updated);

    try {
      final repo = ref.read(groceryRepositoryProvider);
      await repo.toggleItem(id);
    } catch (_) {
      state = AsyncData(prev);
    }
  }

  Future<void> deleteItem(String id) async {
    final prev = state.value ?? [];
    state = AsyncData(prev.where((i) => i.id != id).toList());

    try {
      final repo = ref.read(groceryRepositoryProvider);
      await repo.deleteItem(id);
    } catch (_) {
      state = AsyncData(prev);
    }
  }

  Future<void> clearChecked() async {
    final prev = state.value ?? [];
    state = AsyncData(prev.where((i) => !i.checked).toList());

    try {
      final repo = ref.read(groceryRepositoryProvider);
      await repo.clearChecked();
    } catch (_) {
      state = AsyncData(prev);
    }
  }

  /// Creates an Instacart shopping list from unchecked items.
  /// Returns the shareable URL to open in the browser.
  Future<String> createOrder() async {
    final repo = ref.read(groceryRepositoryProvider);
    return repo.createOrder();
  }
}

final groceryProvider =
    AsyncNotifierProvider<GroceryNotifier, List<GroceryItem>>(
        GroceryNotifier.new);

/// Groups grocery items by ingredient category, matching the pantry's pattern.
final groceryByCategoryProvider =
    Provider<AsyncValue<Map<String, List<GroceryItem>>>>((ref) {
  final groceryAsync = ref.watch(groceryProvider);
  return groceryAsync.whenData((items) {
    final map = <String, List<GroceryItem>>{};
    for (final item in items) {
      final key = item.category;
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  });
});
