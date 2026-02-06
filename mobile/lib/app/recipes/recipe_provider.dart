import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/recipe.dart';

class RecipesNotifier extends Notifier<List<Recipe>> {
  @override
  List<Recipe> build() => [];

  void addRecipe(Recipe recipe) {
    state = [recipe, ...state];
  }

  Recipe? byId(String id) {
    try {
      return state.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

final recipesProvider =
    NotifierProvider<RecipesNotifier, List<Recipe>>(RecipesNotifier.new);
