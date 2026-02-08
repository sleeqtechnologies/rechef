import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/providers/auth_providers.dart';
import '../../recipe_import/data/import_repository.dart';
import '../../recipe_import/pending_jobs_provider.dart';
import '../domain/recipe.dart';
import '../recipe_provider.dart';

class RecipeListScreen extends ConsumerWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final pendingJobs = ref.watch(pendingJobsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Recipes',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 22),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authRepositoryProvider).signOut();
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: recipesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load recipes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => ref.invalidate(recipesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (recipes) => recipes.isEmpty && pendingJobs.isEmpty
                ? const _EmptyState()
                : _RecipeGrid(recipes: recipes, pendingJobs: pendingJobs),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'No recipes yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import a recipe from a URL or photo to get started',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeGrid extends StatelessWidget {
  const _RecipeGrid({required this.recipes, required this.pendingJobs});

  final List<Recipe> recipes;
  final List<ContentJob> pendingJobs;

  @override
  Widget build(BuildContext context) {
    final totalItems = pendingJobs.length + recipes.length;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.horizontalMargin,
        8,
        AppSpacing.horizontalMargin,
        140,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 18,
        childAspectRatio: 0.78,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < pendingJobs.length) {
          return const _PendingRecipeCard();
        }
        final recipe = recipes[index - pendingJobs.length];
        return _RecipeCard(
          id: recipe.id,
          title: recipe.name,
          imageUrl: recipe.imageUrl,
          onTap: () => context.push('/recipes/${recipe.id}'),
        );
      },
    );
  }
}

class _PendingRecipeCard extends StatefulWidget {
  const _PendingRecipeCard();

  @override
  State<_PendingRecipeCard> createState() => _PendingRecipeCardState();
}

class _PendingRecipeCardState extends State<_PendingRecipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final imageSize = constraints.maxWidth;
            return AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200.withValues(
                        alpha: _animation.value + 0.3,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Generating...',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          height: 14,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.onTap,
  });

  final String id;
  final String title;
  final String? imageUrl;
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
              final imageSize = constraints.maxWidth;
              return Hero(
                tag: 'recipe-image-$id',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.restaurant, size: 28),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.restaurant, size: 28),
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Flexible(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
