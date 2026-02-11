import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/recipe_provider.dart';
import '../cookbook_provider.dart';
import 'add_to_cookbook_sheet.dart';

class CookbookDetailScreen extends ConsumerWidget {
  const CookbookDetailScreen({super.key, required this.cookbookId});

  final String cookbookId;

  static const _allRecipesId = '__all_recipes__';
  static const _sharedWithMeId = '__shared_with_me__';
  static const _pantryPicksId = '__pantry_picks__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cookbookId == _allRecipesId) {
      return _VirtualCookbookScreen(
        title: 'All recipes',
        filter: (recipes) => recipes,
      );
    }
    if (cookbookId == _sharedWithMeId) {
      return _VirtualCookbookScreen(
        title: 'Shared with me',
        filter: (recipes) => recipes.where((r) => r.isShared).toList(),
      );
    }
    if (cookbookId == _pantryPicksId) {
      return const _PantryPicksScreen();
    }

    return _CustomCookbookScreen(cookbookId: cookbookId);
  }
}

// ---------------------------------------------------------------------------
// Virtual cookbook screen (All Recipes / Shared with Me)
// ---------------------------------------------------------------------------

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
      backgroundColor: Colors.white,
      body: recipesAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            _DetailAppBar(title: title),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ],
        ),
        error: (error, _) => CustomScrollView(
          slivers: [
            _DetailAppBar(title: title),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.grey.shade300),
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
            ),
          ],
        ),
        data: (recipes) {
          final filtered = filter(recipes);
          final images =
              filtered.where((r) => r.imageUrl != null).take(3).map((r) => r.imageUrl!).toList();

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _DetailAppBar(title: title),
              SliverToBoxAdapter(
                child: _CookbookHeader(
                  title: title,
                  recipeCount: filtered.length,
                  images: images,
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else
                _RecipeListSliver(
                  recipes: filtered,
                  onRecipeTap: (recipe) =>
                      context.push('/recipes/${recipe.id}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pantry Picks screen (AI-powered recommendations)
// ---------------------------------------------------------------------------

class _PantryPicksScreen extends ConsumerWidget {
  const _PantryPicksScreen();

  static const _title = 'Pantry Picks';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picksAsync = ref.watch(pantryPicksProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: picksAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            const _DetailAppBar(title: _title),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ],
        ),
        error: (error, _) => CustomScrollView(
          slivers: [
            const _DetailAppBar(title: _title),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Failed to load recommendations',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(pantryPicksProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        data: (response) {
          final recommended = response.recipes;
          final images = recommended
              .where((r) => r.recipe.imageUrl != null)
              .take(3)
              .map((r) => r.recipe.imageUrl!)
              .toList();

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(pantryPicksProvider);
                  await ref.read(pantryPicksProvider.future);
                },
              ),
              const _DetailAppBar(title: _title),
              SliverToBoxAdapter(
                child: _CookbookHeader(
                  title: _title,
                  recipeCount: recommended.length,
                  images: images,
                ),
              ),
              if (recommended.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    message: response.pantryItemCount == 0
                        ? 'Add items to your pantry\nto get recipe recommendations'
                        : 'No matching recipes found\nfor your pantry items',
                  ),
                )
              else
                _PantryRecipeListSliver(
                  recipes: recommended,
                  onRecipeTap: (recipe) =>
                      context.push('/recipes/${recipe.id}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom cookbook screen (user-created)
// ---------------------------------------------------------------------------

class _CustomCookbookScreen extends ConsumerWidget {
  const _CustomCookbookScreen({required this.cookbookId});

  final String cookbookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(cookbookRecipesProvider(cookbookId));
    final cookbooksAsync = ref.watch(cookbooksProvider);

    final cookbook = cookbooksAsync.whenOrNull(
      data: (state) {
        try {
          return state.cookbooks.firstWhere((c) => c.id == cookbookId);
        } catch (_) {
          return null;
        }
      },
    );

    final cookbookName = cookbook?.name ?? 'Cookbook';
    final coverImages = cookbook?.coverImages ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: recipesAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            _DetailAppBar(
              title: cookbookName,
              showMenu: true,
              onRename: () =>
                  _showRenameSheet(context, ref, cookbookName),
              onDelete: () =>
                  _confirmDelete(context, ref, cookbookName),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ],
        ),
        error: (error, _) => CustomScrollView(
          slivers: [
            _DetailAppBar(
              title: cookbookName,
              showMenu: true,
              onRename: () =>
                  _showRenameSheet(context, ref, cookbookName),
              onDelete: () =>
                  _confirmDelete(context, ref, cookbookName),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.grey.shade300),
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
            ),
          ],
        ),
        data: (recipes) {
          // Use recipe images from loaded recipes when available
          final images = recipes
              .where((r) => r.imageUrl != null)
              .take(3)
              .map((r) => r.imageUrl!)
              .toList();
          final displayImages = images.isNotEmpty ? images : coverImages;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(cookbookRecipesProvider(cookbookId));
                  await ref.read(cookbookRecipesProvider(cookbookId).future);
                },
              ),
              _DetailAppBar(
                title: cookbookName,
                showMenu: true,
                onRename: () =>
                    _showRenameSheet(context, ref, cookbookName),
                onDelete: () =>
                    _confirmDelete(context, ref, cookbookName),
              ),
              SliverToBoxAdapter(
                child: _CookbookHeader(
                  title: cookbookName,
                  recipeCount: recipes.length,
                  images: displayImages,
                ),
              ),
              if (recipes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    message: 'No recipes in this cookbook',
                    subtitle: 'Add recipes from the recipe detail screen',
                  ),
                )
              else
                _RecipeListSliver(
                  recipes: recipes,
                  cookbookId: cookbookId,
                  onRecipeTap: (recipe) =>
                      context.push('/recipes/${recipe.id}'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showRenameSheet(
      BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Rename Cookbook',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Cookbook name',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    await ref
                        .read(cookbooksProvider.notifier)
                        .updateCookbook(id: cookbookId, name: name);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Rename',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

enum _CookbookMoreAction { rename, delete }

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({
    required this.title,
    this.showMenu = false,
    this.onRename,
    this.onDelete,
  });

  final String title;
  final bool showMenu;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  static const _menuItems = [
    AdaptivePopupMenuItem<_CookbookMoreAction>(
      label: 'Rename',
      icon: Icons.edit_outlined,
      value: _CookbookMoreAction.rename,
    ),
    AdaptivePopupMenuItem<_CookbookMoreAction>(
      label: 'Delete',
      icon: Icons.delete_outline,
      value: _CookbookMoreAction.delete,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.grey.shade50.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/recipes');
          }
        },
      ),
      actions: [
        if (showMenu)
          SizedBox(
            width: 48,
            height: 48,
            child: AdaptivePopupMenuButton.widget<_CookbookMoreAction>(
              items: _menuItems,
              onSelected: (index, entry) {
                switch (entry.value) {
                  case _CookbookMoreAction.rename:
                    onRename?.call();
                    break;
                  case _CookbookMoreAction.delete:
                    onDelete?.call();
                    break;
                  case null:
                    break;
                }
              },
              child: const Center(
                child: Icon(Icons.more_vert, size: 22),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cookbook header with fanned images + name + count pill
// ---------------------------------------------------------------------------

class _CookbookHeader extends StatelessWidget {
  const _CookbookHeader({
    required this.title,
    required this.recipeCount,
    required this.images,
  });

  final String title;
  final int recipeCount;
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade50,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        children: [
          // Fanned images
          SizedBox(
            height: 120,
            child: images.isNotEmpty
                ? _HeaderFannedImages(images: images)
                : Icon(Icons.menu_book_outlined,
                    size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
          ),
          const SizedBox(height: 10),
          // Count pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$recipeCount ${recipeCount == 1 ? 'recipe' : 'recipes'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header fanned images (centered, larger)
// ---------------------------------------------------------------------------

class _HeaderFannedImages extends StatelessWidget {
  const _HeaderFannedImages({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final count = images.length.clamp(0, 3);
    if (count == 0) return const SizedBox.shrink();

    const double imgSize = 90;

    // Rotations and horizontal offsets for centered fanning
    const rotations = [-0.18, 0.0, 0.18];
    const xOffsets = [-50.0, 0.0, 50.0];
    const yOffsets = [8.0, 0.0, 8.0];

    final startIdx = 3 - count;

    return SizedBox(
      width: 200,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              left: 100 - imgSize / 2 + xOffsets[startIdx + i],
              top: 15 + yOffsets[startIdx + i],
              child: Transform.rotate(
                angle: rotations[startIdx + i],
                child: Container(
                  width: imgSize,
                  height: imgSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.restaurant,
                            size: 24, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe list sliver
// ---------------------------------------------------------------------------

class _RecipeListSliver extends StatelessWidget {
  const _RecipeListSliver({
    required this.recipes,
    this.cookbookId,
    required this.onRecipeTap,
  });

  final List<Recipe> recipes;
  final String? cookbookId;
  final void Function(Recipe recipe) onRecipeTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.horizontalMargin,
        8,
        AppSpacing.horizontalMargin,
        140,
      ),
      sliver: SliverList.separated(
        itemCount: recipes.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.grey.shade100,
          indent: 80,
        ),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _RecipeListTile(
            recipe: recipe,
            onTap: () => onRecipeTap(recipe),
            cookbookId: cookbookId,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pantry recipe list sliver (with match indicator)
// ---------------------------------------------------------------------------

class _PantryRecipeListSliver extends StatelessWidget {
  const _PantryRecipeListSliver({
    required this.recipes,
    required this.onRecipeTap,
  });

  final List<RecommendedRecipe> recipes;
  final void Function(Recipe recipe) onRecipeTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.horizontalMargin,
        8,
        AppSpacing.horizontalMargin,
        140,
      ),
      sliver: SliverList.separated(
        itemCount: recipes.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.grey.shade100,
          indent: 80,
        ),
        itemBuilder: (context, index) {
          final rec = recipes[index];
          return _RecipeListTile(
            recipe: rec.recipe,
            onTap: () => onRecipeTap(rec.recipe),
            matchLabel: '${rec.matchCount}/${rec.totalIngredients} ingredients',
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe list tile (matching the reference: thumbnail + name + metadata + menu)
// ---------------------------------------------------------------------------

class _RecipeListTile extends StatelessWidget {
  const _RecipeListTile({
    required this.recipe,
    required this.onTap,
    this.cookbookId,
    this.matchLabel,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final String? cookbookId;
  final String? matchLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70,
                height: 70,
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.restaurant,
                              size: 24, color: Colors.grey.shade400),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.restaurant,
                            size: 24, color: Colors.grey.shade400),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                  ),
                  const SizedBox(height: 6),
                  if (matchLabel != null)
                    _MatchBadge(label: matchLabel!)
                  else
                    _RecipeMetaRow(recipe: recipe),
                ],
              ),
            ),
            // Three-dot menu -> opens cookbook picker
            IconButton(
              icon: Icon(Icons.more_vert,
                  color: Colors.grey.shade500, size: 22),
              onPressed: () {
                AddToCookbookSheet.show(
                  context,
                  recipeId: recipe.id,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4F63).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.kitchen_outlined,
            size: 13,
            color: const Color(0xFFFF4F63),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFF4F63),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe metadata row (servings, prep, cook)
// ---------------------------------------------------------------------------

class _RecipeMetaRow extends StatelessWidget {
  const _RecipeMetaRow({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (recipe.servings != null) {
      items.add(_MetaChip(
        icon: Icons.people_outline,
        label: '${recipe.servings}',
      ));
    }
    if (recipe.prepTimeMinutes != null) {
      items.add(_MetaChip(
        icon: Icons.access_time,
        label: '${recipe.prepTimeMinutes} min',
      ));
    }
    if (recipe.cookTimeMinutes != null) {
      items.add(_MetaChip(
        icon: Icons.local_fire_department_outlined,
        label: '${recipe.cookTimeMinutes} min',
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: items,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.message = 'No recipes yet',
    this.subtitle,
  });

  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
