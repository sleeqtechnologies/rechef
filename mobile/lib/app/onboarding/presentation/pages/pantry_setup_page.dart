import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pantry_constants.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';

class PantrySetupPage extends ConsumerWidget {
  const PantrySetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final selectedCount = state.data.pantryItems.length;

    return OnboardingPageWrapper(
      title: "What's in your pantry?",
      subtitle: 'Select items you usually have on hand',
      showBackButton: true,
      onBack: () => notifier.previousPage(),
      scrollable: false,
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$selectedCount item${selectedCount == 1 ? '' : 's'} selected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => notifier.nextPage(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                selectedCount > 0 ? 'Continue' : 'Skip for now',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: PantryConstants.categories.length,
        itemBuilder: (context, index) {
          final category =
              PantryConstants.categories.keys.elementAt(index);
          final items = PantryConstants.categories[category]!;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < PantryConstants.categories.length - 1 ? 20 : 0,
            ),
            child: _CategorySection(
              category: category,
              items: items,
              selectedItems: state.data.pantryItems,
              onToggle: notifier.togglePantryItem,
            ),
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.items,
    required this.selectedItems,
    required this.onToggle,
  });

  final String category;
  final List<String> items;
  final List<String> selectedItems;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            return _PantryItemChip(
              label: item,
              isSelected: isSelected,
              onTap: () => onToggle(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PantryItemChip extends StatelessWidget {
  const _PantryItemChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFF4F63);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? accentColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
