import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/recipe.dart';
import '../recipe_provider.dart';
import 'demo_recipes.dart';

class RecipeListScreen extends ConsumerWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsedRecipes = ref.watch(recipesProvider);
    final demoRecipes = DemoRecipes.all;

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
          child: parsedRecipes.isEmpty
              ? _DemoGrid(recipes: demoRecipes)
              : _MixedGrid(
                  parsedRecipes: parsedRecipes,
                  demoRecipes: demoRecipes,
                ),
        ),
      ),
    );
  }
}

class _MixedGrid extends StatelessWidget {
  const _MixedGrid({required this.parsedRecipes, required this.demoRecipes});

  final List<Recipe> parsedRecipes;
  final List<DemoRecipe> demoRecipes;

  @override
  Widget build(BuildContext context) {
    final totalCount = parsedRecipes.length + demoRecipes.length;

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
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < parsedRecipes.length) {
          final recipe = parsedRecipes[index];
          return _RecipeCard(
            id: recipe.id,
            title: recipe.name,
            imageUrl: recipe.imageUrl,
            onTap: () => context.push('/recipes/${recipe.id}'),
          );
        }

        final demo = demoRecipes[index - parsedRecipes.length];
        return _RecipeCard(
          id: demo.id,
          title: demo.title,
          imageUrl: demo.imageUrl,
          onTap: () => context.push('/recipes/${demo.id}'),
        );
      },
    );
  }
}

class _DemoGrid extends StatelessWidget {
  const _DemoGrid({required this.recipes});

  final List<DemoRecipe> recipes;

  @override
  Widget build(BuildContext context) {
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
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _RecipeCard(
          id: recipe.id,
          title: recipe.title,
          imageUrl: recipe.imageUrl,
          onTap: () => context.push('/recipes/${recipe.id}'),
        );
      },
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
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
