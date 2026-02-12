import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
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
import '../../cookbooks/presentation/cookbook_list_view.dart';
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
  final _pageController = PageController();
  String _searchQuery = '';
  int _selectedSegment = 0;

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
    _pageController.dispose();
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
            child: _RecipeQuotaBadge(
              isPro: isPro,
              usageAsync: usageAsync,
              onTap: isPro
                  ? null
                  : () => ref.read(subscriptionProvider.notifier).showPaywall(),
            ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.horizontalMargin,
              0,
              AppSpacing.horizontalMargin,
              10,
            ),
            child: AdaptiveSegmentedControl(
              labels: const ['All Recipes', 'Cookbooks'],
              selectedIndex: _selectedSegment,
              onValueChanged: (index) {
                setState(() => _selectedSegment = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _selectedSegment = index);
          },
          children: [
            _AllRecipesTab(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchQuery: _searchQuery,
              onClearSearch: () => _searchController.clear(),
              filterRecipes: _filterRecipes,
            ),
            const CookbookListView(),
          ],
        ),
      ),
    );
  }
}

class _AllRecipesTab extends ConsumerWidget {
  const _AllRecipesTab({
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.onClearSearch,
    required this.filterRecipes,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final List<Recipe> Function(List<Recipe>) filterRecipes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final pendingJobs = ref.watch(pendingJobsProvider);

    return recipesAsync.when(
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
              controller: searchController,
              focusNode: searchFocusNode,
              query: searchQuery,
              onClear: onClearSearch,
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
              controller: searchController,
              focusNode: searchFocusNode,
              query: searchQuery,
              onClear: onClearSearch,
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
        final filtered = filterRecipes(recipes);
        final hasAnyRecipes = filtered.isNotEmpty || pendingJobs.isNotEmpty;

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
                controller: searchController,
                focusNode: searchFocusNode,
                query: searchQuery,
                onClear: onClearSearch,
              ),
            ),
            if (!hasAnyRecipes && searchQuery.trim().isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else if (filtered.isEmpty && recipes.isNotEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NoSearchResults(query: searchQuery),
              )
            else
              _RecipeGridSliver(
                recipes: filtered,
                pendingJobs: searchQuery.trim().isEmpty ? pendingJobs : [],
                onDismissJob: (id) =>
                    ref.read(pendingJobsProvider.notifier).dismissJob(id),
              ),
          ],
        );
      },
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'Generate First Recipe',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'share a recipe with app or\nenter a url to a recipe',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SvgPicture.asset(
                  'assets/icons/drawn-arrow.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _RecipeQuotaBadge extends StatelessWidget {
  const _RecipeQuotaBadge({
    required this.isPro,
    required this.usageAsync,
    this.onTap,
  });

  final bool isPro;
  final AsyncValue<MonthlyImportUsage> usageAsync;
  final VoidCallback? onTap;

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

    final badge = Container(
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

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }
    return badge;
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
  const _RecipeGridSliver({
    required this.recipes,
    required this.pendingJobs,
    required this.onDismissJob,
    this.title,
  });

  final List<Recipe> recipes;
  final List<ContentJob> pendingJobs;
  final ValueChanged<String> onDismissJob;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final totalItems = pendingJobs.length + recipes.length;
    final hasTitle = title != null && totalItems > 0;

    return SliverMainAxisGroup(
      slivers: [
        if (hasTitle)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.horizontalMargin,
                8,
                AppSpacing.horizontalMargin,
                12,
              ),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.horizontalMargin,
            hasTitle ? 0 : 8,
            AppSpacing.horizontalMargin,
            title != null ? 24 : 140,
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
                final job = pendingJobs[index];
                if (job.isFailed) {
                  return _FailedRecipeCard(
                    error: job.error,
                    onDismiss: () => onDismissJob(job.id),
                  );
                }
                return const _PendingRecipeCard();
              }
              final recipe = recipes[index - pendingJobs.length];
              return RecipeCard(
                id: recipe.id,
                title: recipe.name,
                imageUrl: recipe.imageUrl,
                isShared: recipe.isShared,
                onTap: () => context.push('/recipes/${recipe.id}'),
              );
            }, childCount: totalItems),
          ),
        ),
      ],
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

class _FailedRecipeCard extends StatelessWidget {
  const _FailedRecipeCard({required this.onDismiss, this.error});

  final VoidCallback onDismiss;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDADA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFC62828),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Recipe failed',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFFC62828),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                error!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onDismiss,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Generation failed',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
        ),
      ],
    );
  }
}

/// Public RecipeCard widget reused by cookbook detail screen.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.id,
    required this.title,
    this.imageUrl,
    this.isShared = false,
    required this.onTap,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final bool isShared;
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
                  child: Stack(
                    children: [
                      SizedBox(
                        width: imageSize,
                        height: imageSize,
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
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
                                    child: const Icon(
                                      Icons.restaurant,
                                      size: 28,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.restaurant, size: 28),
                              ),
                      ),
                      if (isShared)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.share,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Shared',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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
