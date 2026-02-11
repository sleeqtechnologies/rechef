import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../cookbook_provider.dart';
import '../domain/cookbook.dart';

class CookbookListView extends ConsumerWidget {
  const CookbookListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cookbooksAsync = ref.watch(cookbooksProvider);

    return cookbooksAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Failed to load cookbooks',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(cookbooksProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (state) {
        // Virtual cookbooks + user cookbooks + create button = total items
        final virtualCount = 2; // "All Recipes" and "Shared with Me"
        final userCookbooks = state.cookbooks;
        final totalItems = virtualCount + userCookbooks.length + 1; // +1 for create card

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(cookbooksProvider);
                await ref.read(cookbooksProvider.future);
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.horizontalMargin,
                12,
                AppSpacing.horizontalMargin,
                140,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return _CookbookCard(
                        name: 'All Recipes',
                        recipeCount: state.allRecipesCount,
                        icon: Icons.restaurant_menu_rounded,
                        iconColor: const Color(0xFFFF4F63),
                        onTap: () =>
                            context.push('/cookbooks/__all_recipes__'),
                      );
                    }
                    if (index == 1) {
                      return _CookbookCard(
                        name: 'Shared with Me',
                        recipeCount: state.sharedWithMeCount,
                        icon: Icons.people_outline_rounded,
                        iconColor: const Color(0xFF4A90D9),
                        onTap: () =>
                            context.push('/cookbooks/__shared_with_me__'),
                      );
                    }
                    if (index == totalItems - 1) {
                      return _CreateCookbookCard(
                        onTap: () => _showCreateCookbookDialog(context, ref),
                      );
                    }

                    final cookbook = userCookbooks[index - virtualCount];
                    return _CookbookCard(
                      name: cookbook.name,
                      recipeCount: cookbook.recipeCount,
                      coverImageUrl: cookbook.coverImageUrl,
                      onTap: () => context.push('/cookbooks/${cookbook.id}'),
                      onLongPress: () =>
                          _showCookbookOptions(context, ref, cookbook),
                    );
                  },
                  childCount: totalItems,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateCookbookDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Cookbook'),
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
                  .createCookbook(name: name);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCookbookOptions(
      BuildContext context, WidgetRef ref, Cookbook cookbook) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameCookbookDialog(context, ref, cookbook);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Delete',
                  style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteCookbook(context, ref, cookbook);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameCookbookDialog(
      BuildContext context, WidgetRef ref, Cookbook cookbook) {
    final controller = TextEditingController(text: cookbook.name);
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
                  .updateCookbook(id: cookbook.id, name: name);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCookbook(
      BuildContext context, WidgetRef ref, Cookbook cookbook) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cookbook?'),
        content: Text(
          'Are you sure you want to delete "${cookbook.name}"? '
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
                  .deleteCookbook(cookbook.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CookbookCard extends StatelessWidget {
  const _CookbookCard({
    required this.name,
    required this.recipeCount,
    this.coverImageUrl,
    this.icon,
    this.iconColor,
    required this.onTap,
    this.onLongPress,
  });

  final String name;
  final int recipeCount;
  final String? coverImageUrl;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth;
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: size,
                  height: size,
                  color: Colors.grey.shade100,
                  child: coverImageUrl != null
                      ? Image.network(
                          coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildIconPlaceholder(size),
                        )
                      : _buildIconPlaceholder(size),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$recipeCount ${recipeCount == 1 ? 'recipe' : 'recipes'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPlaceholder(double size) {
    return Center(
      child: Icon(
        icon ?? Icons.menu_book_rounded,
        size: 32,
        color: iconColor ?? Colors.grey.shade400,
      ),
    );
  }
}

class _CreateCookbookCard extends StatelessWidget {
  const _CreateCookbookCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'New Cookbook',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
