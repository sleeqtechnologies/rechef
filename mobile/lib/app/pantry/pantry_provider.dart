import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cookbooks/cookbook_provider.dart';
import '../recipe_import/import_provider.dart';
import 'data/pantry_repository.dart';
import 'domain/pantry_item.dart';

final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  return PantryRepository(apiClient: ref.watch(apiClientProvider));
});

class PantryNotifier extends AsyncNotifier<List<PantryItem>> {
  @override
  Future<List<PantryItem>> build() async {
    final repo = ref.read(pantryRepositoryProvider);
    return repo.fetchAll();
  }

  Future<void> addItems(List<String> names) async {
    final repo = ref.read(pantryRepositoryProvider);
    final added = await repo.addItems(names);
    state = AsyncData([...state.value ?? [], ...added]);
    ref.invalidate(pantryPicksProvider);
  }

  Future<void> deleteItem(String id) async {
    final repo = ref.read(pantryRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(
      (state.value ?? []).where((item) => item.id != id).toList(),
    );
    ref.invalidate(pantryPicksProvider);
  }
}

final pantryProvider =
    AsyncNotifierProvider<PantryNotifier, List<PantryItem>>(
        PantryNotifier.new);

/// Groups pantry items by category, maintaining a stable category order.
final pantryByCategoryProvider =
    Provider<AsyncValue<Map<String, List<PantryItem>>>>((ref) {
  final pantryAsync = ref.watch(pantryProvider);
  return pantryAsync.whenData((items) {
    final map = <String, List<PantryItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    // Sort categories alphabetically, but keep "Other" at the end.
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        if (a == 'Other') return 1;
        if (b == 'Other') return -1;
        return a.compareTo(b);
      });
    return {for (final key in sortedKeys) key: map[key]!};
  });
});
