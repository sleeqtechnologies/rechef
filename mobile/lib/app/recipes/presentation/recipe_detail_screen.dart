import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'demo_recipes.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = DemoRecipes.byId(widget.recipeId);
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    // When the header image has collapsed into the toolbar.
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
                // Adaptive app bar with image background
                SliverAppBar(
                  expandedHeight: screenWidth, // Square image
                  pinned: true,
                  floating: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _AppBarButton(
                      icon: Icons.arrow_back,
                      iconColor: _isCollapsed ? Colors.black : Colors.white,
                      glassColor: _isCollapsed
                          ? const Color(0xCCFFFFFF)
                          : const Color(0x33FFFFFF),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  actions: [
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
                          child: Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.restaurant, size: 48),
                              );
                            },
                          ),
                        ),
                        // When collapsed, add a subtle white scrim so buttons
                        // remain visible over the white content below.
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

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          recipe.title,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                        ),
                        const SizedBox(height: 16),

                        // Author info
                        if (recipe.author != null) ...[
                          _AuthorRow(author: recipe.author!),
                          const SizedBox(height: 16),
                        ],

                        // Time and servings
                        Row(
                          children: [
                            _MetaInfo(
                              icon: Icons.access_time_outlined,
                              label: '${recipe.minutes} min',
                            ),
                            const SizedBox(width: 20),
                            _MetaInfo(
                              icon: Icons.restaurant_outlined,
                              label: '${recipe.servings} servings',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tab bar
                        _TabBarWidget(controller: _tabController),
                      ],
                    ),
                  ),
                ),

                // Tab content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        return _tabController.index == 0
                            ? _IngredientsTab(recipe: recipe)
                            : _CookingTab(recipe: recipe);
                      },
                    ),
                  ),
                ),

                // Spacer so content doesn't hide behind floating CTA.
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // Floating CTA (no bottom bar/background)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return _BottomButton(
                  isIngredientsTab: _tabController.index == 0,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _tabController.index == 0
                              ? 'Added to grocery list (demo)'
                              : 'Starting cooking mode (demo)',
                        ),
                      ),
                    );
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
    // Keep this small for performance: glass effects are expensive on large areas.
    return FakeGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: 999),
      settings: LiquidGlassSettings(
        blur: 10,
        glassColor: glassColor,
      ),
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

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.author});

  final RecipeAuthor author;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            author.name.isNotEmpty ? author.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name and source
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (author.sourceUrl != null)
                Text(
                  author.sourceUrl!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaInfo extends StatelessWidget {
  const _MetaInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
      ],
    );
  }
}

class _TabBarWidget extends StatelessWidget {
  const _TabBarWidget({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Ingredients'),
          Tab(text: 'Cooking'),
        ],
      ),
    );
  }
}

class _IngredientsTab extends StatelessWidget {
  const _IngredientsTab({required this.recipe});

  final DemoRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Colors.grey.shade200;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Ingredients – (${recipe.ingredientsInPantry} in Pantry)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: dividerColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                for (var i = 0; i < recipe.ingredients.length; i++) ...[
                  _IngredientRow(ingredient: recipe.ingredients[i]),
                  if (i != recipe.ingredients.length - 1)
                    Divider(height: 1, thickness: 1, color: dividerColor),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient});

  final RecipeIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    final checkedFill = const Color(0xFFF7B6C0);
    final checkedIcon = const Color(0xFFE05A6B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Checkbox
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ingredient.inPantry ? checkedFill : Colors.white,
              border: Border.all(
                color:
                    ingredient.inPantry ? Colors.transparent : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: ingredient.inPantry
                ? Icon(Icons.check, size: 16, color: checkedIcon)
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
          // Quantity
          Text(
            ingredient.quantity,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}

class _CookingTab extends StatelessWidget {
  const _CookingTab({required this.recipe});

  final DemoRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Cooking Instructions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          recipe.steps.length,
          (index) => _StepRow(
            stepNumber: index + 1,
            text: recipe.steps[index],
          ),
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              stepNumber.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.red.shade300, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isIngredientsTab
                      ? 'Add missing items to Grocery list'
                      : 'Start cooking',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isIngredientsTab ? '🛒' : '🔥',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
