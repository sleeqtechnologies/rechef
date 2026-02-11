import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../recipe_import/import_provider.dart';
import '../recipes/domain/recipe.dart';
import 'data/cookbook_repository.dart';
import 'domain/cookbook.dart';

final cookbookRepositoryProvider = Provider<CookbookRepository>((ref) {
  return CookbookRepository(apiClient: ref.watch(apiClientProvider));
});

class CookbooksState {
  const CookbooksState({
    required this.cookbooks,
    required this.allRecipesCount,
    required this.sharedWithMeCount,
  });

  final List<Cookbook> cookbooks;
  final int allRecipesCount;
  final int sharedWithMeCount;
}

class CookbooksNotifier extends AsyncNotifier<CookbooksState> {
  @override
  Future<CookbooksState> build() async {
    final repo = ref.read(cookbookRepositoryProvider);
    final response = await repo.fetchAll();
    return CookbooksState(
      cookbooks: response.cookbooks,
      allRecipesCount: response.allRecipesCount,
      sharedWithMeCount: response.sharedWithMeCount,
    );
  }

  Future<Cookbook> createCookbook({
    required String name,
    String? description,
  }) async {
    final repo = ref.read(cookbookRepositoryProvider);
    final cookbook = await repo.create(name: name, description: description);
    final current = state.value;
    if (current != null) {
      state = AsyncData(CookbooksState(
        cookbooks: [cookbook, ...current.cookbooks],
        allRecipesCount: current.allRecipesCount,
        sharedWithMeCount: current.sharedWithMeCount,
      ));
    }
    return cookbook;
  }

  Future<Cookbook> updateCookbook({
    required String id,
    String? name,
    String? description,
  }) async {
    final repo = ref.read(cookbookRepositoryProvider);
    final updated =
        await repo.update(id: id, name: name, description: description);
    final current = state.value;
    if (current != null) {
      final cookbooks = List<Cookbook>.from(current.cookbooks);
      final idx = cookbooks.indexWhere((c) => c.id == id);
      if (idx != -1) {
        cookbooks[idx] = updated;
      }
      state = AsyncData(CookbooksState(
        cookbooks: cookbooks,
        allRecipesCount: current.allRecipesCount,
        sharedWithMeCount: current.sharedWithMeCount,
      ));
    }
    return updated;
  }

  Future<void> deleteCookbook(String id) async {
    final repo = ref.read(cookbookRepositoryProvider);
    await repo.delete(id);
    final current = state.value;
    if (current != null) {
      state = AsyncData(CookbooksState(
        cookbooks: current.cookbooks.where((c) => c.id != id).toList(),
        allRecipesCount: current.allRecipesCount,
        sharedWithMeCount: current.sharedWithMeCount,
      ));
    }
  }

  Future<void> addRecipesToCookbook(
      String cookbookId, List<String> recipeIds) async {
    final repo = ref.read(cookbookRepositoryProvider);
    await repo.addRecipes(cookbookId, recipeIds);
    // Refresh to get updated counts
    ref.invalidateSelf();
  }

  Future<void> removeRecipeFromCookbook(
      String cookbookId, String recipeId) async {
    final repo = ref.read(cookbookRepositoryProvider);
    await repo.removeRecipe(cookbookId, recipeId);
    // Refresh to get updated counts
    ref.invalidateSelf();
  }
}

final cookbooksProvider =
    AsyncNotifierProvider<CookbooksNotifier, CookbooksState>(
  CookbooksNotifier.new,
);

final cookbookRecipesProvider =
    FutureProvider.family<List<Recipe>, String>((ref, cookbookId) async {
  final repo = ref.read(cookbookRepositoryProvider);
  return repo.fetchRecipes(cookbookId);
});
