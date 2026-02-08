import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../pantry/presentation/add_item_sheet.dart';
import '../domain/grocery_item.dart';
import '../grocery_provider.dart';

class GroceryListScreen extends ConsumerWidget {
  const GroceryListScreen({super.key, this.recipeIds});

  final List<String>? recipeIds;

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<List<String>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final keyboardHeight =
            MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AddItemSheet(),
              Container(
                height: keyboardHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.80),
                ),
              ),
            ],
          ),
        );
      },
    ).then((names) {
      if (names != null && names.isNotEmpty) {
        ref.read(groceryProvider.notifier).addItems(
              items: names.map((n) => {'name': n}).toList(),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(groceryGroupModeProvider);
    final groupedAsync = mode == GroceryGroupMode.category
        ? ref.watch(groceryByCategoryProvider)
        : ref.watch(groceryByRecipeProvider);

    // Check for any checked items across all groups for the "Clear checked" button.
    final hasChecked = groupedAsync.value != null &&
        groupedAsync.value!.values
            .expand((items) => items)
            .any((i) => i.checked);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Grocery',
        actions: [
          if (hasChecked)
            TextButton(
              onPressed: () {
                ref.read(groceryProvider.notifier).clearChecked();
              },
              child: Text(
                'Clear checked',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAddSheet(context, ref),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/plus.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load grocery list.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (grouped) {
          return Column(
            children: [
              // ── Toggle chips ───────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.horizontalMargin,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Category',
                      selected: mode == GroceryGroupMode.category,
                      onTap: () => ref
                          .read(groceryGroupModeProvider.notifier)
                          .set(GroceryGroupMode.category),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Recipe',
                      selected: mode == GroceryGroupMode.recipe,
                      onTap: () => ref
                          .read(groceryGroupModeProvider.notifier)
                          .set(GroceryGroupMode.recipe),
                    ),
                  ],
                ),
              ),

              // ── List content ───────────────────────────────────────────
              Expanded(
                child: grouped.isEmpty
                    ? Center(
                        child: Text(
                          'Your grocery list is empty.\nAdd missing items from a recipe.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.horizontalMargin,
                          0,
                          AppSpacing.horizontalMargin,
                          140,
                        ),
                        children: [
                          for (final entry in grouped.entries) ...[
                            _SectionHeader(title: entry.key),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.grey.shade200,
                            ),
                            for (final item in entry.value) ...[
                              _GroceryItemRow(
                                item: item,
                                showRecipeSubtitle: false,
                                onToggle: () {
                                  ref
                                      .read(groceryProvider.notifier)
                                      .toggleItem(item.id);
                                },
                                onDismissed: () {
                                  ref
                                      .read(groceryProvider.notifier)
                                      .deleteItem(item.id);
                                },
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey.shade200,
                              ),
                            ],
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ── Grocery item row ─────────────────────────────────────────────────────────

class _GroceryItemRow extends StatelessWidget {
  const _GroceryItemRow({
    required this.item,
    required this.onToggle,
    required this.onDismissed,
    this.showRecipeSubtitle = false,
  });

  final GroceryItem item;
  final VoidCallback onToggle;
  final VoidCallback onDismissed;
  final bool showRecipeSubtitle;

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      item.checked ? const Color(0xFF2E7D32) : Colors.white,
                  border: Border.all(
                    color: item.checked
                        ? Colors.transparent
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: item.checked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              // Name + optional recipe subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            decoration: item.checked
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.checked
                                ? Colors.grey.shade400
                                : textColor,
                          ),
                    ),
                    if (showRecipeSubtitle &&
                        item.recipeName != null &&
                        item.recipeName!.isNotEmpty)
                      Text(
                        item.recipeName!,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                      ),
                  ],
                ),
              ),
              // Quantity
              if (item.displayQuantity.isNotEmpty)
                Text(
                  item.displayQuantity,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
