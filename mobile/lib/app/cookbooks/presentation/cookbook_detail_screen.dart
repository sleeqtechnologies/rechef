import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/recipe_provider.dart';
import '../../recipes/presentation/recipe_list_screen.dart';
import '../cookbook_provider.dart';

class CookbookDetailScreen extends ConsumerWidget {
  const CookbookDetailScreen({super.key, required this.cookbookId});

  final String cookbookId;

  static const _allRecipesId = '__all_recipes__';
  static const _sharedWithMeId = '__shared_with_me__';

  bool get _isVirtual =>
      cookbookId == _allRecipesId || cookbookId == _sharedWithMeId;

  String get _title {
    if (cookbookId == _allRecipesId) return 'All Recipes';
    if (cookbookId == _sharedWithMeId) return 'Shared with Me';
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cookbookId == _allRecipesId) {
      return _VirtualCookbookScreen(
        title: 'All Recipes',
        filter: (recipes) => recipes,
      );
    }
    if (cookbookId == _sharedWithMeId) {
      return _VirtualCookbookScreen(
        title: 'Shared with Me',
        filter: (recipes) => recipes.where((r) => r.isShared).toList(),
      );
    }

    return _CustomCookbookScreen(cookbookId: cookbookId);
  }
}

class _VirtualCookbookScreen extends ConsumerWidget {
  const _VirtualCookbookScreen({
    required this.title,
    required this.filter,
  });

  final String title;
  final List<Recipe> Function(List<Recipe>) filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: recipesAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Failed to load recipes',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(recipesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (recipes) {
          final filtered = filter(recipes);
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  Text(
                    'No recipes yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          return _RecipeGrid(recipes: filtered);
        },
      ),
    );
  }
}

class _CustomCookbookScreen extends ConsumerWidget {
  const _CustomCookbookScreen({required this.cookbookId});

  final String cookbookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(cookbookRecipesProvider(cookbookId));
    final cookbooksAsync = ref.watch(cookbooksProvider);

    final cookbookName = cookbooksAsync.whenOrNull(
      data: (state) {
        try {
          return state.cookbooks.firstWhere((c) => c.id == cookbookId).name;
        } catch (_) {
          return null;
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(cookbookName ?? 'Cookbook'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') {
                _showRenameDialog(context, ref, cookbookName ?? '');
              } else if (value == 'delete') {
                _confirmDelete(context, ref, cookbookName ?? '');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Rename'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    Text('Delete',
                        style: TextStyle(color: Colors.red.shade400)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: recipesAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Failed to load recipes',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.invalidate(cookbookRecipesProvider(cookbookId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (recipes) {
          if (recipes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  Text(
                    'No recipes in this cookbook',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add recipes from the recipe detail screen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }
          return _RecipeGrid(recipes: recipes);
        },
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Cookbook'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Cookbook name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(cookbooksProvider.notifier)
                  .updateCookbook(id: cookbookId, name: name);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String cookbookName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cookbook?'),
        content: Text(
          'Are you sure you want to delete "$cookbookName"? '
          'Recipes in this cookbook will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(cookbooksProvider.notifier)
                  .deleteCookbook(cookbookId);
              if (context.mounted) context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _RecipeGrid extends StatelessWidget {
  const _RecipeGrid({required this.recipes});

  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.horizontalMargin,
        12,
        AppSpacing.horizontalMargin,
        140,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 18,
        childAspectRatio: 0.78,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return RecipeCard(
          id: recipe.id,
          title: recipe.name,
          imageUrl: recipe.imageUrl,
          isShared: recipe.isShared,
          onTap: () => context.push('/recipes/${recipe.id}'),
        );
      },
    );
  }
}
