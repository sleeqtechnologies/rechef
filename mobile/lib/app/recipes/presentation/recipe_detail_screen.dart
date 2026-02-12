import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

import '../domain/recipe.dart';
import '../domain/ingredient.dart';
import '../data/share_event_service.dart';
import '../recipe_provider.dart';
import '../domain/nutrition_facts.dart';
import '../../grocery/grocery_provider.dart';
import 'cooking_mode_sheet.dart';
import 'edit_recipe_sheet.dart';
import 'share_recipe_sheet.dart';
import '../../cookbooks/presentation/add_to_cookbook_sheet.dart';
import '../../../core/services/cook_reminder_notifications.dart';
import '../../../core/widgets/app_snack_bar.dart';

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

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late final ScrollController _scrollController;
  bool _isCollapsed = false;
  bool _isMatchingPantry = true;
  DateTime? _reminderDate;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _runPantryMatch();
    _loadReminder();
    // For shared recipes, always refresh to get latest version
    _refreshIfShared();
  }

  Future<void> _refreshIfShared() async {
    final recipeAsync = ref.read(recipeByIdProvider(widget.recipeId));
    recipeAsync.whenData((recipe) async {
      if (recipe?.isShared == true && mounted) {
        ref.invalidate(recipesProvider);
        await ref.read(recipesProvider.future);
      }
    });
  }

  Future<void> _runPantryMatch() async {
    try {
      await ref.read(recipesProvider.notifier).matchPantry(widget.recipeId);
    } catch (_) {
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
          AppSnackBar.show(
            context,
            message: 'recipes.recipe_updated'.tr(),
            type: SnackBarType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.show(
            context,
            message: 'recipes.failed_to_save'.tr(args: [e.toString()]),
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  Future<void> _openShareSheet(Recipe recipe) async {
    final ok = await ShareRecipeSheet.show(context, recipe: recipe);
    if (!mounted) return;
    if (!ok) {
      AppSnackBar.show(
        context,
        message: 'recipes.failed_share_link'.tr(),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _removeSharedRecipeFromLibrary(Recipe recipe) async {
    if (recipe.sharedSaveId == null) return;
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'recipes.remove_from_library_title'.tr(),
      message:
          'recipes.remove_from_library_message'.tr(args: [recipe.name]),
      actions: [
        AlertAction(
          title: 'common.cancel'.tr(),
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'recipes.remove'.tr(),
          style: AlertActionStyle.destructive,
          onPressed: () async {
            try {
              await ref
                  .read(recipesProvider.notifier)
                  .removeSharedRecipe(recipe.sharedSaveId!);
              if (!mounted) return;
              AppSnackBar.show(
                context,
                message: 'recipes.removed_from_library'.tr(),
                type: SnackBarType.success,
              );
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/recipes');
              }
            } catch (e) {
              if (mounted) {
                AppSnackBar.show(
                  context,
                  message: 'recipes.failed_to_remove'.tr(args: [e.toString()]),
                  type: SnackBarType.error,
                );
              }
            }
          },
        ),
      ],
    );
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'recipes.delete_recipe_title'.tr(),
      message: '"${recipe.name}" will be permanently removed.',
      actions: [
        AlertAction(
          title: 'common.cancel'.tr(),
          style: AlertActionStyle.cancel,
          onPressed: () {
            // Cancel - do nothing
          },
        ),
        AlertAction(
          title: 'common.delete'.tr(),
          style: AlertActionStyle.destructive,
          onPressed: () async {
            try {
              await ref.read(recipesProvider.notifier).deleteRecipe(recipe.id);
              if (!mounted) return;
              AppSnackBar.show(
                context,
                message: 'recipes.recipe_deleted'.tr(),
                type: SnackBarType.success,
              );
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/recipes');
              }
            } catch (e) {
              if (mounted) {
                AppSnackBar.show(
                  context,
                  message: 'recipes.failed_to_delete'.tr(args: [e.toString()]),
                  type: SnackBarType.error,
                );
              }
            }
          },
        ),
      ],
    );
  }

  Future<void> _loadReminder() async {
    final dt = await CookReminderNotifications.instance.getReminder(
      widget.recipeId,
    );
    if (mounted) setState(() => _reminderDate = dt);
  }

  Future<void> _removeReminder(Recipe recipe) async {
    await CookReminderNotifications.instance.cancel(recipe.id);
    if (!mounted) return;
    setState(() => _reminderDate = null);
    AppSnackBar.show(
      context,
      message: 'recipes.reminder_removed'.tr(),
      type: SnackBarType.info,
    );
  }

  Future<void> _handleReminder(Recipe recipe) async {
    if (_reminderDate != null) {
      await _removeReminder(recipe);
      return;
    }

    // Pick date & time in one adaptive picker.
    final now = DateTime.now();
    final scheduledDate = await AdaptiveDatePicker.show(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      mode: CupertinoDatePickerMode.dateAndTime,
    );
    if (scheduledDate == null || !mounted) return;

    if (scheduledDate.isBefore(DateTime.now())) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'recipes.pick_future_time'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    await CookReminderNotifications.instance.schedule(
      recipe.id,
      recipe.name,
      scheduledDate,
    );

    if (!mounted) return;
    setState(() => _reminderDate = scheduledDate);
    final formatted = _formatReminderDate(scheduledDate);
    AppSnackBar.show(
      context,
      message: 'Reminder set for $formatted',
      type: SnackBarType.success,
    );
  }

  String _formatReminderDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day at $hour:$minute $period';
  }

  @override
  void dispose() {
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
        body: Center(child: CupertinoActivityIndicator()),
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
                'recipes.failed_to_load'.tr(),
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
                'recipes.failed_to_load'.tr(),
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
                      iconColor: Colors.black,
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
                    if (!recipe.isShared) ...[
                      _AppBarTextButton(
                        label: 'recipes.edit'.tr(),
                        textColor: Colors.black,
                        glassColor: _isCollapsed
                            ? const Color(0xCCFFFFFF)
                            : const Color(0x33FFFFFF),
                        onPressed: () => _openEditSheet(recipe),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (!recipe.isShared)
                      _AppBarButton(
                        icon: Icons.share_outlined,
                        iconColor: Colors.black,
                        glassColor: _isCollapsed
                            ? const Color(0xCCFFFFFF)
                            : const Color(0x33FFFFFF),
                        onPressed: () => _openShareSheet(recipe),
                      ),
                    if (!recipe.isShared) const SizedBox(width: 4),
                    if (!recipe.isShared)
                      _RecipeMorePopupMenu(
                        recipe: recipe,
                        isCollapsed: _isCollapsed,
                        hasReminder: _reminderDate != null,
                        onDelete: () => _deleteRecipe(recipe),
                        onAddToCookbook: () => AddToCookbookSheet.show(
                          context,
                          recipeId: recipe.id,
                        ),
                        onSetReminder: () => _handleReminder(recipe),
                      ),
                    if (recipe.isShared && recipe.sharedSaveId != null)
                      _SharedRecipeMorePopupMenu(
                        recipe: recipe,
                        isCollapsed: _isCollapsed,
                        onRemoveFromLibrary: () =>
                            _removeSharedRecipeFromLibrary(recipe),
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
                      // Title → time/servings on off‑white background
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFF7F5F0),
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
                            if (recipe.isShared) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.share,
                                      size: 14,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'recipes.shared_recipe'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
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
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _MetaInfo(
                                  iconAsset: 'assets/icons/clock.svg',
                                  label: '${recipe.totalMinutes} min',
                                ),
                                _MetaInfo(
                                  iconAsset: 'assets/icons/servings.svg',
                                  label: '${recipe.servings ?? 0} servings',
                                ),
                                if (_reminderDate != null)
                                  _ReminderChip(date: _reminderDate!),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Tab bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: AdaptiveSegmentedControl(
                          labels: ['recipes.ingredients'.tr(), 'recipes.cooking'.tr(), 'recipes.nutrition'.tr()],
                          selectedIndex: _selectedTab,
                          onValueChanged: (index) {
                            setState(() => _selectedTab = index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity < -300 && _selectedTab < 2) {
                        setState(() => _selectedTab++);
                      } else if (velocity > 300 && _selectedTab > 0) {
                        setState(() => _selectedTab--);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: switch (_selectedTab) {
                        0 => _IngredientsTab(
                          recipe: recipe,
                          isMatchingPantry: _isMatchingPantry,
                          onToggle: recipe.isShared
                              ? (_) {}
                              : (index) {
                                  ref
                                      .read(recipesProvider.notifier)
                                      .toggleIngredient(widget.recipeId, index);
                                },
                        ),
                        1 => _CookingTab(recipe: recipe),
                        _ => _NutritionTab(recipeId: recipe.id),
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
          if (_selectedTab != 2)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomButton(
                isIngredientsTab: _selectedTab == 0,
                onPressed: () async {
                  if (_selectedTab == 0) {
                    final missing = recipe.ingredients
                        .where((i) => !i.inPantry)
                        .toList();

                    if (missing.isEmpty) {
                      AppSnackBar.show(
                        context,
                        message: 'recipes.all_in_pantry'.tr(),
                        type: SnackBarType.info,
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
                        if (recipe.isShared &&
                            recipe.shareCode != null &&
                            added > 0) {
                          ShareEventService.recordEvent(
                            shareCode: recipe.shareCode!,
                            eventType: 'grocery_add',
                          );
                        }
                        final msg = added == 0
                            ? 'recipes.already_in_grocery'.tr()
                            : 'Added $added item${added == 1 ? '' : 's'} to grocery list';
                        AppSnackBar.show(
                          context,
                          message: msg,
                          type: added == 0
                              ? SnackBarType.info
                              : SnackBarType.success,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackBar.show(
                          context,
                          message: 'recipes.failed_add_grocery'.tr(),
                          type: SnackBarType.error,
                        );
                      }
                    }
                  } else {
                    CookingModeSheet.show(context, recipe);
                  }
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

class _AppBarTextButton extends StatelessWidget {
  const _AppBarTextButton({
    required this.label,
    required this.textColor,
    required this.glassColor,
    required this.onPressed,
  });

  final String label;
  final Color textColor;
  final Color glassColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FakeGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: 999),
      settings: LiquidGlassSettings(blur: 10, glassColor: glassColor),
      child: SizedBox(
        height: 40,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

enum _SharedRecipeMoreAction { removeFromLibrary }

class _SharedRecipeMorePopupMenu extends StatelessWidget {
  const _SharedRecipeMorePopupMenu({
    required this.recipe,
    required this.isCollapsed,
    required this.onRemoveFromLibrary,
  });

  final Recipe recipe;
  final bool isCollapsed;
  final VoidCallback onRemoveFromLibrary;

  static final _items = [
    AdaptivePopupMenuItem<_SharedRecipeMoreAction>(
      label: 'recipes.remove_from_library'.tr(),
      icon: Icons.remove_circle_outline,
      value: _SharedRecipeMoreAction.removeFromLibrary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.black;
    final glassColor = isCollapsed
        ? const Color(0xCCFFFFFF)
        : const Color(0x33FFFFFF);

    return IconTheme(
      data: const IconThemeData(color: Colors.black, size: 20),
      child: FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 999),
        settings: LiquidGlassSettings(blur: 10, glassColor: glassColor),
        child: SizedBox(
          width: 40,
          height: 40,
          child: AdaptivePopupMenuButton.widget<_SharedRecipeMoreAction>(
            items: _items,
            tint: iconColor,
            buttonStyle: PopupButtonStyle.glass,
            onSelected: (index, entry) {
              switch (entry.value) {
                case _SharedRecipeMoreAction.removeFromLibrary:
                  onRemoveFromLibrary();
                  break;
                case null:
                  break;
              }
            },
            child: Center(
              child: Icon(Icons.more_vert, color: Colors.black, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

enum _RecipeMoreAction { addToCookbook, setReminder, delete }

class _RecipeMorePopupMenu extends StatelessWidget {
  const _RecipeMorePopupMenu({
    required this.recipe,
    required this.isCollapsed,
    required this.hasReminder,
    required this.onDelete,
    required this.onAddToCookbook,
    required this.onSetReminder,
  });

  final Recipe recipe;
  final bool isCollapsed;
  final bool hasReminder;
  final VoidCallback onDelete;
  final VoidCallback onAddToCookbook;
  final VoidCallback onSetReminder;

  List<AdaptivePopupMenuItem<_RecipeMoreAction>> get _items => [
    AdaptivePopupMenuItem<_RecipeMoreAction>(
      label: 'recipes.add_to_cookbook'.tr(),
      icon: Icons.menu_book_outlined,
      value: _RecipeMoreAction.addToCookbook,
    ),
    AdaptivePopupMenuItem<_RecipeMoreAction>(
      label: hasReminder ? 'recipes.remove_reminder'.tr() : 'recipes.set_reminder'.tr(),
      icon: hasReminder
          ? Icons.notifications_off_outlined
          : Icons.notifications_outlined,
      value: _RecipeMoreAction.setReminder,
    ),
    AdaptivePopupMenuItem<_RecipeMoreAction>(
      label: 'recipes.delete_recipe'.tr(),
      icon: Icons.delete_outline,
      value: _RecipeMoreAction.delete,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.black;
    final glassColor = isCollapsed
        ? const Color(0xCCFFFFFF)
        : const Color(0x33FFFFFF);

    return IconTheme(
      data: const IconThemeData(color: Colors.black, size: 20),
      child: FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 999),
        settings: LiquidGlassSettings(blur: 10, glassColor: glassColor),
        child: SizedBox(
          width: 40,
          height: 40,
          child: AdaptivePopupMenuButton.widget<_RecipeMoreAction>(
            items: _items,
            tint: iconColor,
            buttonStyle: PopupButtonStyle.glass,
            onSelected: (index, entry) {
              switch (entry.value) {
                case _RecipeMoreAction.addToCookbook:
                  onAddToCookbook();
                  break;
                case _RecipeMoreAction.setReminder:
                  onSetReminder();
                  break;
                case _RecipeMoreAction.delete:
                  onDelete();
                  break;
                case null:
                  break;
              }
            },
            child: Center(
              child: Icon(Icons.more_vert, color: Colors.black, size: 20),
            ),
          ),
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

String? _platformFromUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final lower = url.toLowerCase();
  if (lower.contains('instagram.com')) return 'instagram';
  if (lower.contains('tiktok.com')) return 'tiktok';
  if (lower.contains('youtube.com') || lower.contains('youtu.be'))
    return 'youtube';
  return null;
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.author});

  final _AuthorInfo author;

  String get _displayName {
    if (author.name.trim().isNotEmpty) return author.name.trim();
    final platform = _platformFromUrl(author.sourceUrl);
    if (platform != null) {
      switch (platform) {
        case 'instagram':
          return 'Instagram';
        case 'tiktok':
          return 'TikTok';
        case 'youtube':
          return 'YouTube';
      }
    }
    return '';
  }

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

  IconData? get _platformIcon {
    final platform = _platformFromUrl(author.sourceUrl);
    if (platform == null) return null;
    switch (platform) {
      case 'instagram':
        return SimpleIcons.instagram;
      case 'tiktok':
        return SimpleIcons.tiktok;
      case 'youtube':
        return SimpleIcons.youtube;
      default:
        return null;
    }
  }

  Color? get _platformIconColor {
    final platform = _platformFromUrl(author.sourceUrl);
    if (platform == null) return null;
    switch (platform) {
      case 'instagram':
        return SimpleIconColors.instagram;
      case 'tiktok':
        return SimpleIconColors.tiktok;
      case 'youtube':
        return SimpleIconColors.youtube;
      default:
        return null;
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
                : _buildPlatformOrInitialsAvatar(context),
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

  Widget _buildPlatformOrInitialsAvatar(BuildContext context) {
    if (author.name.trim().isEmpty && _platformIcon != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _platformIconColor ?? Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(_platformIcon!, size: 22, color: Colors.white),
      );
    }
    return _buildInitialsAvatar(context);
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

class _ReminderChip extends StatelessWidget {
  const _ReminderChip({required this.date});

  final DateTime date;

  String get _label {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day;
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $hour:$minute $period';
  }

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
              'assets/icons/alert.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
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
              CupertinoActivityIndicator(
                radius: 7,
                color: Colors.grey.shade400,
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
          'recipes.cooking_instructions'.tr(),
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

class _NutritionTab extends ConsumerWidget {
  const _NutritionTab({required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(nutritionByRecipeProvider(recipeId));

    return nutritionAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, _) => _NutritionError(
        onRetry: () => ref.invalidate(nutritionByRecipeProvider(recipeId)),
      ),
      data: (nutrition) => _NutritionContent(nutrition: nutrition),
    );
  }
}

class _NutritionError extends StatelessWidget {
  const _NutritionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'recipes.nutrition'.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'recipes.nutrition_unavailable'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: Text('recipes.try_again'.tr())),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionContent extends StatefulWidget {
  const _NutritionContent({required this.nutrition});

  final NutritionFacts nutrition;

  @override
  State<_NutritionContent> createState() => _NutritionContentState();
}

class _NutritionContentState extends State<_NutritionContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  bool _chartDataReady = false;

  static const _proteinColor = Color(0xFF5B8DEF);
  static const _carbsColor = Color(0xFFFBBF54);
  static const _fatColor = Color(0xFFEF6B6B);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _chartDataReady = true);
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<_MacroData> _buildMacroData(NutritionFacts nutrition) {
    final items = <_MacroData>[
      _MacroData(
        label: 'recipes.protein'.tr(),
        grams: nutrition.proteinGrams,
        color: _proteinColor,
      ),
      _MacroData(
        label: 'recipes.carbs'.tr(),
        grams: nutrition.carbsGrams,
        color: _carbsColor,
      ),
      _MacroData(label: 'recipes.fat'.tr(), grams: nutrition.fatGrams, color: _fatColor),
    ];
    return items.where((m) => m.grams > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nutrition = widget.nutrition;
    final macros = _buildMacroData(nutrition);
    final totalGrams = macros.fold<double>(0, (s, m) => s + m.grams);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'recipes.nutrition'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        if (!nutrition.hasAnyMacros)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'recipes.nutrition_not_available'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          // Chart card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 280,
                  child: SfCircularChart(
                    margin: EdgeInsets.zero,
                    annotations: <CircularChartAnnotation>[
                      CircularChartAnnotation(
                        widget: FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${nutrition.calories.round()}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'recipes.kcal'.tr(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    series: <DoughnutSeries<_MacroData, String>>[
                      DoughnutSeries<_MacroData, String>(
                        dataSource: _chartDataReady ? macros : <_MacroData>[],
                        xValueMapper: (_MacroData data, _) => data.label,
                        yValueMapper: (_MacroData data, _) => data.grams,
                        pointColorMapper: (_MacroData data, _) => data.color,
                        innerRadius: '68%',
                        radius: '90%',
                        cornerStyle: CornerStyle.bothCurve,
                        animationDuration: 1200,
                        animationDelay: 0,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Legend row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: macros.map((m) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: m.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            m.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Macro breakdown cards
          Text(
            'recipes.per_serving'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          ...macros.map((m) {
            final pct = totalGrams > 0 ? (m.grams / totalGrams * 100) : 0.0;
            return _MacroBreakdownCard(
              label: m.label,
              grams: m.grams,
              percentage: pct,
              color: m.color,
              animation: _animController,
            );
          }),
        ],
      ],
    );
  }
}

class _MacroData {
  _MacroData({required this.label, required this.grams, required this.color});

  final String label;
  final double grams;
  final Color color;
}

class _MacroBreakdownCard extends StatelessWidget {
  const _MacroBreakdownCard({
    required this.label,
    required this.grams,
    required this.percentage,
    required this.color,
    required this.animation,
  });

  final String label;
  final double grams;
  final double percentage;
  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      final progress = Curves.easeOut.transform(
                        animation.value.clamp(0.0, 1.0),
                      );
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (percentage / 100) * progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            color.withValues(alpha: 0.7),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${grams.toStringAsFixed(1)} g',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${percentage.round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
                      ? 'recipes.add_missing_to_grocery'.tr()
                      : 'recipes.start_cooking'.tr(),
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
