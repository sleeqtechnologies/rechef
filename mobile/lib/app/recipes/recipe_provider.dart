import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../recipe_import/import_provider.dart';
import 'data/recipe_repository.dart';
import 'domain/recipe.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(apiClient: ref.watch(apiClientProvider));
});

class RecipesNotifier extends AsyncNotifier<List<Recipe>> {
  @override
  Future<List<Recipe>> build() async {
    final repo = ref.read(recipeRepositoryProvider);
    return repo.fetchAll();
  }

  Future<Recipe> addRecipe(Recipe recipe) async {
    final repo = ref.read(recipeRepositoryProvider);
    final saved = await repo.save(recipe);
    state = AsyncData([saved, ...state.value ?? []]);
    return saved;
  }

  Recipe? byId(String id) {
    final recipes = state.value ?? [];
    try {
      return recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteRecipe(String id) async {
    final repo = ref.read(recipeRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(
      (state.value ?? []).where((r) => r.id != id).toList(),
    );
  }
}

final recipesProvider =
    AsyncNotifierProvider<RecipesNotifier, List<Recipe>>(RecipesNotifier.new);
