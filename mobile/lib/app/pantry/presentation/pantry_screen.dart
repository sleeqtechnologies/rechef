import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../domain/pantry_item.dart';
import '../pantry_provider.dart';

class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byCategoryAsync = ref.watch(pantryByCategoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Pantry'),
      body: byCategoryAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load pantry.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (byCategory) {
          if (byCategory.isEmpty) {
            return Center(
              child: Text(
                'Your pantry is empty.\nTap + to add ingredients.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
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
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                for (final item in entry.value) ...[
                  _PantryItemRow(
                    item: item,
                    onDismissed: () {
                      ref.read(pantryProvider.notifier).deleteItem(item.id);
                    },
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
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
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PantryItemRow extends StatelessWidget {
  const _PantryItemRow({required this.item, required this.onDismissed});

  final PantryItem item;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(item.name, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
