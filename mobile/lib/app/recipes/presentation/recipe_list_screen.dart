import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/presentation/account_sheet.dart';
import '../../auth/providers/auth_providers.dart';
import '../../recipe_import/data/import_repository.dart';
import '../../recipe_import/monthly_import_usage_provider.dart';
import '../../recipe_import/pending_jobs_provider.dart';
import '../../subscription/subscription_provider.dart';
import '../domain/recipe.dart';
import '../recipe_provider.dart';

class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Recipe> _filterRecipes(List<Recipe> recipes) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return recipes;
    return recipes
        .where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              (r.description.isNotEmpty &&
                  r.description.toLowerCase().contains(q)),
        )
        .toList();
  }

  static const _accentColor = Color(0xFFFF4F63);

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider);
    final pendingJobs = ref.watch(pendingJobsProvider);
    final user = ref.watch(userModelProvider);
    final initials = user?.initials ?? 'AN';
    final isPro = ref.watch(isProUserProvider);
    final usageAsync = ref.watch(monthlyImportUsageProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Recipes',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _RecipeQuotaBadge(isPro: isPro, usageAsync: usageAsync),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => AccountSheet.show(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: recipesAsync.when(
          loading: () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(recipesProvider);
                  await ref.read(recipesProvider.future);
                },
              ),
              SliverToBoxAdapter(
                child: _SearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  query: _searchQuery,
                  onClear: () => _searchController.clear(),
                ),
              ),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ],
          ),
          error: (error, _) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(recipesProvider);
                  await ref.read(recipesProvider.future);
                },
              ),
              SliverToBoxAdapter(
                child: _SearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  query: _searchQuery,
                  onClear: () => _searchController.clear(),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
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
              ),
            ],
          ),
          data: (recipes) {
            final filtered = _filterRecipes(recipes);
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    ref.invalidate(recipesProvider);
                    await ref.read(recipesProvider.future);
                  },
                ),
                SliverToBoxAdapter(
                  child: _SearchField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    query: _searchQuery,
                    onClear: () => _searchController.clear(),
                  ),
                ),
                if (filtered.isEmpty && pendingJobs.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else if (filtered.isEmpty && recipes.isNotEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoSearchResults(query: _searchQuery),
                  )
                else
                  _RecipeGridSliver(
                    recipes: filtered,
                    pendingJobs: _searchQuery.trim().isEmpty ? pendingJobs : [],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.horizontalMargin,
        8,
        AppSpacing.horizontalMargin,
        12,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: 'Search recipes…',
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SvgPicture.asset(
              'assets/icons/search.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                Colors.grey.shade800,
                BlendMode.srcIn,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
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

class _RecipeQuotaBadge extends StatelessWidget {
  const _RecipeQuotaBadge({required this.isPro, required this.usageAsync});

  final bool isPro;
  final AsyncValue<MonthlyImportUsage> usageAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String label;
    if (isPro) {
      label = 'Pro';
    } else {
      final usage = usageAsync.maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );
      if (usage == null) {
        label = '–/5';
      } else {
        label = '${usage.used}/${usage.limit}';
      }
    }

    final Color backgroundColor;
    final Color textColor;
    const accentColor = Color(0xFFFF4F63);
    if (isPro) {
      backgroundColor = const Color(0xFFE7F8EB);
      textColor = const Color(0xFF219653);
    } else {
      backgroundColor = const Color(0xFFFFF3C4);
      textColor = const Color(0xFF4A4A4A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/bolt.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(accentColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              query.trim().isEmpty
                  ? 'No matches'
                  : 'No matches for "${query.trim()}"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
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

class _RecipeGridSliver extends StatelessWidget {
  const _RecipeGridSliver({required this.recipes, required this.pendingJobs});

  final List<Recipe> recipes;
  final List<ContentJob> pendingJobs;

  @override
  Widget build(BuildContext context) {
    final totalItems = pendingJobs.length + recipes.length;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.horizontalMargin,
        8,
        AppSpacing.horizontalMargin,
        140,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 18,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
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
        }, childCount: totalItems),
      ),
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
                          CupertinoActivityIndicator(
                            radius: 12,
                            color: Colors.grey.shade400,
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
                                child: const CupertinoActivityIndicator(
                                  radius: 11,
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
