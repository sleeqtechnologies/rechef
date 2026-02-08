import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/recipe.dart';
import '../domain/ingredient.dart';
import '../recipe_provider.dart';
import '../../grocery/grocery_provider.dart';
import 'cooking_mode_sheet.dart';
import 'edit_recipe_sheet.dart';

bool _hasSourceOrAuthor(Recipe recipe) {
  final hasName =
      recipe.sourceAuthorName != null &&
      recipe.sourceAuthorName!.trim().isNotEmpty;
  final hasUrl =
      recipe.sourceUrl != null && recipe.sourceUrl!.trim().isNotEmpty;
  final hasTitle =
      recipe.sourceTitle != null && recipe.sourceTitle!.trim().isNotEmpty;
  final hasAvatar =
      recipe.sourceAuthorAvatarUrl != null &&
      recipe.sourceAuthorAvatarUrl!.trim().isNotEmpty;
  return hasName || hasUrl || hasTitle || hasAvatar;
}

class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;
  bool _isCollapsed = false;
  bool _isMatchingPantry = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _runPantryMatch();
  }

  Future<void> _runPantryMatch() async {
    try {
      await ref.read(recipesProvider.notifier).matchPantry(widget.recipeId);
    } catch (_) {
      // Silently ignore matching errors
    } finally {
      if (mounted) setState(() => _isMatchingPantry = false);
    }
  }

  Future<void> _openEditSheet(Recipe recipe) async {
    final updated = await EditRecipeSheet.show(context, recipe);
    if (updated != null && mounted) {
      try {
        await ref.read(recipesProvider.notifier).updateRecipe(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeByIdProvider(widget.recipeId));
    final recipe = recipeAsync.value;

    if (recipeAsync.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (recipeAsync.hasError) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/recipes');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load recipe',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (recipe == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/recipes');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Recipe not found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final collapseOffset = (screenWidth - kToolbarHeight - topPadding).clamp(
      0.0,
      double.infinity,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis != Axis.vertical) return false;
              final collapsed = notification.metrics.pixels > collapseOffset;
              if (collapsed != _isCollapsed) {
                setState(() => _isCollapsed = collapsed);
              }
              return false;
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: screenWidth,
                  pinned: true,
                  floating: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _AppBarButton(
                      icon: Icons.arrow_back_ios_new,
                      iconColor: _isCollapsed ? Colors.black : Colors.white,
                      glassColor: _isCollapsed
                          ? const Color(0xCCFFFFFF)
                          : const Color(0x33FFFFFF),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/recipes');
                        }
                      },
                    ),
                  ),
                  actions: [
                    _AppBarButton(
                      icon: Icons.edit_outlined,
                      iconColor: _isCollapsed ? Colors.black : Colors.white,
                      glassColor: _isCollapsed
                          ? const Color(0xCCFFFFFF)
                          : const Color(0x33FFFFFF),
                      onPressed: () => _openEditSheet(recipe),
                    ),
                    const SizedBox(width: 4),
                    _AppBarButton(
                      icon: Icons.bookmark_border,
                      iconColor: _isCollapsed ? Colors.black : Colors.white,
                      glassColor: _isCollapsed
                          ? const Color(0xCCFFFFFF)
                          : const Color(0x33FFFFFF),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved (demo)')),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    _AppBarButton(
                      icon: Icons.share_outlined,
                      iconColor: _isCollapsed ? Colors.black : Colors.white,
                      glassColor: _isCollapsed
                          ? const Color(0xCCFFFFFF)
                          : const Color(0x33FFFFFF),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share (demo)')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'recipe-image-${recipe.id}',
                          child: recipe.imageUrl != null
                              ? Image.network(
                                  recipe.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.restaurant,
                                        size: 48,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.restaurant, size: 48),
                                ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          color: _isCollapsed
                              ? Colors.white.withValues(alpha: 0.88)
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title → time/servings on cream background
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFFCF9F5),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                            ),
                            if (_hasSourceOrAuthor(recipe)) ...[
                              const SizedBox(height: 16),
                              _AuthorRow(
                                author: _AuthorInfo(
                                  name:
                                      recipe.sourceAuthorName
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? recipe.sourceAuthorName!
                                      : '',
                                  sourceUrl: recipe.sourceUrl,
                                  sourceTitle: recipe.sourceTitle,
                                  avatarUrl: recipe.sourceAuthorAvatarUrl,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              children: [
                                _MetaInfo(
                                  iconAsset: 'assets/icons/clock.svg',
                                  label: '${recipe.totalMinutes} min',
                                ),
                                const SizedBox(width: 20),
                                _MetaInfo(
                                  iconAsset: 'assets/icons/servings.svg',
                                  label: '${recipe.servings ?? 0} servings',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Tab bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: _TabBarWidget(controller: _tabController),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        return _tabController.index == 0
                            ? _IngredientsTab(
                                recipe: recipe,
                                isMatchingPantry: _isMatchingPantry,
                                onToggle: (index) {
                                  ref
                                      .read(recipesProvider.notifier)
                                      .toggleIngredient(widget.recipeId, index);
                                },
                              )
                            : _CookingTab(recipe: recipe);
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return _BottomButton(
                  isIngredientsTab: _tabController.index == 0,
                  onPressed: () async {
                    if (_tabController.index == 0) {
                      final missing = recipe.ingredients
                          .where((i) => !i.inPantry)
                          .toList();

                      if (missing.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'All ingredients are in your pantry!',
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        final added = await ref
                            .read(groceryProvider.notifier)
                            .addItems(
                              recipeId: widget.recipeId,
                              items: missing
                                  .map(
                                    (i) => {
                                      'name': i.name,
                                      'quantity': i.quantity,
                                      if (i.unit != null) 'unit': i.unit,
                                    },
                                  )
                                  .toList(),
                            );
                        if (context.mounted) {
                          final msg = added == 0
                              ? 'Items already in grocery list'
                              : 'Added $added item${added == 1 ? '' : 's'} to grocery list';
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add to grocery list'),
                            ),
                          );
                        }
                      }
                    } else {
                      CookingModeSheet.show(context, recipe);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({
    required this.icon,
    required this.iconColor,
    required this.glassColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final Color glassColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FakeGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: 999),
      settings: LiquidGlassSettings(blur: 10, glassColor: glassColor),
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          icon: Icon(icon, color: iconColor, size: 20),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _AuthorInfo {
  const _AuthorInfo({
    required this.name,
    this.sourceUrl,
    this.sourceTitle,
    this.avatarUrl,
  });

  final String name;
  final String? sourceUrl;
  final String? sourceTitle;
  final String? avatarUrl;
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.author});

  final _AuthorInfo author;

  String get _displayName =>
      author.name.trim().isNotEmpty ? author.name.trim() : '';

  String get _sourceUrlDisplay {
    if (author.sourceUrl == null || author.sourceUrl!.trim().isEmpty) return '';
    // Show a clean, short version of the URL
    final url = author.sourceUrl!.trim();
    try {
      final uri = Uri.parse(url);
      return uri.host + uri.path;
    } catch (_) {
      return url;
    }
  }

  Future<void> _openSourceUrl() async {
    if (author.sourceUrl == null || author.sourceUrl!.trim().isEmpty) return;
    final uri = Uri.tryParse(author.sourceUrl!.trim());
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showNameLine = _displayName.isNotEmpty;
    final hasUrl = _sourceUrlDisplay.isNotEmpty;

    return GestureDetector(
      onTap: hasUrl ? _openSourceUrl : null,
      child: Row(
        children: [
          ClipOval(
            child:
                author.avatarUrl != null && author.avatarUrl!.trim().isNotEmpty
                ? Image.network(
                    author.avatarUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitialsAvatar(context),
                  )
                : _buildInitialsAvatar(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showNameLine)
                  Text(
                    _displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (hasUrl)
                  Text(
                    _sourceUrlDisplay,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (hasUrl)
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: Colors.grey.shade500,
            ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    final initial = author.name.isNotEmpty
        ? author.name
              .trim()
              .split(RegExp(r'\s+'))
              .map((s) => s.isNotEmpty ? s[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';
    if (initial.isEmpty) return _buildInitialsAvatarFallback(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.length > 2 ? initial.substring(0, 2) : initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildInitialsAvatarFallback(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  const _MetaInfo({required this.iconAsset, required this.label});

  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset(
              iconAsset,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarWidget extends StatelessWidget {
  const _TabBarWidget({required this.controller});

  final TabController controller;

  static const _cream = Color(0xFFFCF9F5);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.all(8),
          child: TabBar(
            controller: controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black87,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 2,
            ),
            tabs: const [
              Tab(text: 'Ingredients'),
              Tab(text: 'Cooking'),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientsTab extends StatelessWidget {
  const _IngredientsTab({
    required this.recipe,
    required this.onToggle,
    this.isMatchingPantry = false,
  });

  final Recipe recipe;
  final void Function(int index) onToggle;
  final bool isMatchingPantry;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Colors.grey.shade200;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Ingredients – (${recipe.ingredientsInPantry} in Pantry)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (isMatchingPantry) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            for (var i = 0; i < recipe.ingredients.length; i++) ...[
              _IngredientRow(
                ingredient: recipe.ingredients[i],
                onTap: () => onToggle(i),
              ),
              if (i != recipe.ingredients.length - 1)
                Divider(height: 1, thickness: 1, color: dividerColor),
            ],
          ],
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient, required this.onTap});

  final Ingredient ingredient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final checkedFill = const Color(0xFFF7B6C0);
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final quantityWidth = constraints.maxWidth * 0.35;
            return Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ingredient.inPantry ? checkedFill : Colors.white,
                    border: Border.all(
                      color: ingredient.inPantry
                          ? Colors.transparent
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: ingredient.inPantry
                      ? SvgPicture.asset(
                          'assets/icons/check-mark.svg',
                          width: 14,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                            textColor,
                            BlendMode.srcIn,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Text(
                    ingredient.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Quantity (capped at 27% of row width)
                SizedBox(
                  width: quantityWidth,
                  child: Text(
                    ingredient.displayQuantity,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CookingTab extends StatelessWidget {
  const _CookingTab({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Cooking Instructions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            for (var i = 0; i < recipe.instructions.length; i++) ...[
              _StepRow(stepNumber: i + 1, text: recipe.instructions[i]),
              if (i != recipe.instructions.length - 1)
                Divider(height: 24, thickness: 1, color: Colors.grey.shade200),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.stepNumber, required this.text});

  final int stepNumber;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade50,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.isIngredientsTab,
    required this.onPressed,
  });

  final bool isIngredientsTab;
  final VoidCallback onPressed;

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final isGreen = isIngredientsTab;
    final fillColor = isGreen ? _green : Colors.red.shade400;
    const foregroundColor = Colors.white;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: fillColor,
              foregroundColor: foregroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isIngredientsTab
                      ? 'Add missing items to Grocery list'
                      : 'Start cooking',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (isIngredientsTab)
                  SvgPicture.asset(
                    'assets/icons/cart.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      foregroundColor,
                      BlendMode.srcIn,
                    ),
                  )
                else
                  SvgPicture.asset(
                    'assets/icons/fire.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      foregroundColor,
                      BlendMode.srcIn,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
