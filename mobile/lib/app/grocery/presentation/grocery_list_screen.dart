import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../domain/grocery_item.dart';
import '../grocery_provider.dart';

class GroceryListScreen extends ConsumerWidget {
  const GroceryListScreen({super.key, this.recipeIds});

  final List<String>? recipeIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byCategoryAsync = ref.watch(groceryByCategoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Grocery',
        actions: [
          if (byCategoryAsync.value != null &&
              byCategoryAsync.value!.values
                  .expand((items) => items)
                  .any((i) => i.checked))
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
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
            ),
        ],
      ),
      body: byCategoryAsync.when(
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
        data: (byCategory) {
          if (byCategory.isEmpty) {
            return Center(
              child: Text(
                'Your grocery list is empty.\nAdd missing items from a recipe.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.horizontalMargin,
              8,
              AppSpacing.horizontalMargin,
              140,
            ),
            children: [
              for (final entry in byCategory.entries) ...[
                _CategoryHeader(title: entry.key),
                Divider(
                    height: 1, thickness: 1, color: Colors.grey.shade200),
                for (final item in entry.value) ...[
                  _GroceryItemRow(
                    item: item,
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
                      height: 1, thickness: 1, color: Colors.grey.shade200),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title});

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

class _GroceryItemRow extends StatelessWidget {
  const _GroceryItemRow({
    required this.item,
    required this.onToggle,
    required this.onDismissed,
  });

  final GroceryItem item;
  final VoidCallback onToggle;
  final VoidCallback onDismissed;

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
                  color: item.checked
                      ? const Color(0xFF2E7D32)
                      : Colors.white,
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
                    if (item.recipeName != null && item.recipeName!.isNotEmpty)
                      Text(
                        item.recipeName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
