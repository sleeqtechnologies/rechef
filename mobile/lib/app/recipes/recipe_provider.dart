import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../recipe_import/import_provider.dart';
import 'data/recipe_repository.dart';
import 'data/nutrition_repository.dart';
import 'domain/ingredient.dart';
import 'domain/recipe.dart';
import 'domain/nutrition_facts.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(apiClient: ref.watch(apiClientProvider));
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(apiClient: ref.watch(apiClientProvider));
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

  Future<Recipe> updateRecipe(Recipe recipe) async {
    final repo = ref.read(recipeRepositoryProvider);
    final saved = await repo.update(recipe);
    final recipes = state.value ?? [];
    final idx = recipes.indexWhere((r) => r.id == saved.id);
    if (idx != -1) {
      final updated = List<Recipe>.from(recipes);
      updated[idx] = saved;
      state = AsyncData(updated);
    }
    return saved;
  }

  Future<void> deleteRecipe(String id) async {
    final repo = ref.read(recipeRepositoryProvider);
    await repo.delete(id);
    state = AsyncData((state.value ?? []).where((r) => r.id != id).toList());
  }

  Future<void> removeSharedRecipe(String sharedSaveId) async {
    final repo = ref.read(recipeRepositoryProvider);
    await repo.removeSharedRecipe(sharedSaveId);
    state = AsyncData(
      (state.value ?? []).where((r) => r.sharedSaveId != sharedSaveId).toList(),
    );
  }

  Future<void> matchPantry(String recipeId) async {
    final repo = ref.read(recipeRepositoryProvider);
    final updatedIngredients = await repo.matchPantry(recipeId);
    _updateRecipeIngredients(recipeId, updatedIngredients);
  }

  Future<void> toggleIngredient(String recipeId, int index) async {
    final recipes = state.value ?? [];
    final recipeIndex = recipes.indexWhere((r) => r.id == recipeId);
    if (recipeIndex == -1) return;

    final recipe = recipes[recipeIndex];
    if (index < 0 || index >= recipe.ingredients.length) return;
    final updatedIngredients = List<Ingredient>.from(recipe.ingredients);
    updatedIngredients[index] = updatedIngredients[index].copyWith(
      inPantry: !updatedIngredients[index].inPantry,
    );
    final updated = List<Recipe>.from(recipes);
    updated[recipeIndex] = recipe.copyWith(ingredients: updatedIngredients);
    state = AsyncData(updated);

    try {
      final repo = ref.read(recipeRepositoryProvider);
      await repo.toggleIngredient(recipeId, index);
    } catch (_) {
      state = AsyncData(recipes);
    }
  }

  void _updateRecipeIngredients(String recipeId, List<Ingredient> ingredients) {
    final recipes = state.value ?? [];
    final idx = recipes.indexWhere((r) => r.id == recipeId);
    if (idx == -1) return;
    final updated = List<Recipe>.from(recipes);
    updated[idx] = recipes[idx].copyWith(ingredients: ingredients);
    state = AsyncData(updated);
  }
}

final recipesProvider = AsyncNotifierProvider<RecipesNotifier, List<Recipe>>(
  RecipesNotifier.new,
);

final recipeByIdProvider = Provider.family<AsyncValue<Recipe?>, String>((
  ref,
  recipeId,
) {
  final recipesAsync = ref.watch(recipesProvider);
  return recipesAsync.whenData((recipes) {
    try {
      return recipes.firstWhere((r) => r.id == recipeId);
    } catch (_) {
      return null;
    }
  });
});

final nutritionByRecipeProvider =
    FutureProvider.family<NutritionFacts, String>((ref, recipeId) async {
  final repo = ref.read(nutritionRepositoryProvider);
  return repo.fetchNutrition(recipeId);
});

