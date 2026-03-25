import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/routing/expand_page_route.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/platform_segmented_control.dart';
import '../../../core/widgets/recipe_image.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../auth/presentation/account_sheet.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cookbooks/presentation/add_to_cookbook_sheet.dart';
import '../../recipe_import/data/import_repository.dart';
import '../../recipe_import/monthly_import_usage_provider.dart';
import '../../recipe_import/pending_jobs_provider.dart';
import '../../subscription/subscription_provider.dart';
import '../../cookbooks/cookbook_provider.dart';
import '../../cookbooks/presentation/cookbook_list_view.dart';
import '../domain/recipe.dart';
import '../recipe_provider.dart';
import 'share_recipe_sheet.dart';

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
        title: 'recipes.title'.tr(),
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
            child: PlatformSegmentedControl(
              labels: ['recipes.all_recipes'.tr(), 'recipes.cookbooks'.tr()],
              selectedIndex: _selectedSegment,
              onValueChanged: (index) {
                setState(() => _selectedSegment = index);
                if (index == 1) ref.invalidate(cookbooksProvider);
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
            if (index == 1) ref.invalidate(cookbooksProvider);
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
    Future<void> refreshRecipes() async {
      ref.invalidate(recipesProvider);
      await ref.read(recipesProvider.future);
    }

    return recipesAsync.when(
      loading: () => _PlatformRefreshableSliverScroll(
        onRefresh: refreshRecipes,
        slivers: [
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
      error: (error, _) => _PlatformRefreshableSliverScroll(
        onRefresh: refreshRecipes,
        slivers: [
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
                    'recipes.failed_to_load'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => ref.invalidate(recipesProvider),
                    child: Text('common.retry'.tr()),
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

        return _PlatformRefreshableSliverScroll(
          onRefresh: refreshRecipes,
          slivers: [
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

class _PlatformRefreshableSliverScroll extends StatelessWidget {
  const _PlatformRefreshableSliverScroll({
    required this.onRefresh,
    required this.slivers,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    if (isIos) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          ...slivers,
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
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
          hintText: 'recipes.search_hint'.tr(),
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
            'recipes.generate_first'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'recipes.generate_first_subtitle'.tr(),
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
                  ? 'recipes.no_matches'.tr()
                  : 'recipes.no_matches_for'.tr(args: [query.trim()]),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'recipes.try_different_search'.tr(),
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

class _RecipeGridSliver extends ConsumerWidget {
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

  void _showLongPressMenu(BuildContext context, WidgetRef ref, Recipe recipe) {
    HapticFeedback.mediumImpact();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => _RecipeContextMenu(
        recipe: recipe,
        onShare: () {
          Navigator.pop(ctx);
          ShareRecipeSheet.show(context, recipe: recipe);
        },
        onAddToCookbook: () {
          Navigator.pop(ctx);
          AddToCookbookSheet.show(context, recipeId: recipe.id);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDelete(context, ref, recipe);
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Recipe recipe,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('recipes.delete_recipe_title'.tr()),
        content: Text('"${recipe.name}" will be permanently removed.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(recipesProvider.notifier).deleteRecipe(recipe.id);
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: 'recipes.recipe_deleted'.tr(),
        type: SnackBarType.success,
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: 'recipes.failed_to_delete'.tr(args: [e.toString()]),
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                onTap: () => context.push('/recipes/${recipe.id}'),
                onLongPress: () => _showLongPressMenu(context, ref, recipe),
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
                            'recipes.generating'.tr(),
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
                              style: Theme.of(context).textTheme.bodySmall
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
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: Colors.grey.shade600),
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
    required this.onTap,
    this.onLongPress,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      onTap: () {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final pos = box.localToGlobal(Offset.zero);
          ExpandPageTransition.sourceRect = Rect.fromLTWH(
            pos.dx, pos.dy, box.size.width, box.size.width,
          );
        }
        onTap();
      },
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final imageSize = constraints.maxWidth;
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: RecipeImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: imageSize,
                        height: imageSize,
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
                      ),
                    ),
                  ],
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

class _RecipeContextMenu extends StatelessWidget {
  const _RecipeContextMenu({
    required this.recipe,
    required this.onShare,
    required this.onAddToCookbook,
    required this.onDelete,
  });

  final Recipe recipe;
  final VoidCallback onShare;
  final VoidCallback onAddToCookbook;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xE6FFFFFF),
                      Color(0xD9F5F7FB),
                      Color(0xCCECEFF5),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Text(
                        recipe.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                    _ContextMenuItem(
                      icon: CupertinoIcons.share,
                      label: 'recipes.share'.tr(),
                      onTap: onShare,
                    ),
                    Divider(
                      height: 1,
                      indent: 52,
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                    _ContextMenuItem(
                      icon: Icons.menu_book_outlined,
                      label: 'recipes.add_to_cookbook'.tr(),
                      onTap: onAddToCookbook,
                    ),
                    Divider(
                      height: 1,
                      indent: 52,
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                    _ContextMenuItem(
                      icon: CupertinoIcons.delete,
                      label: 'recipes.delete_recipe'.tr(),
                      onTap: onDelete,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextMenuItem extends StatelessWidget {
  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFFF3B30) : Colors.black87;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
