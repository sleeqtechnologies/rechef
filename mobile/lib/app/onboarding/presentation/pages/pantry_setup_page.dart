import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pantry/pantry_provider.dart';
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
    final imagesAsync = ref.watch(pantryItemImagesProvider);
    final imageMap = imagesAsync.value ?? <String, String?>{};

    return OnboardingPageWrapper(
      title: 'onboarding.pantry_title'.tr(),
      subtitle: 'onboarding.pantry_subtitle'.tr(),
      scrollable: false,
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'onboarding.n_items_selected'.plural(selectedCount),
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
                selectedCount > 0 ? 'common.continue_btn'.tr() : 'onboarding.skip_for_now'.tr(),
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
          final category = PantryConstants.categories.keys.elementAt(index);
          final items = PantryConstants.categories[category]!;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < PantryConstants.categories.length - 1 ? 20 : 0,
            ),
            child: _CategorySection(
              category: category,
              items: items,
              imageMap: imageMap,
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
    required this.imageMap,
    required this.selectedItems,
    required this.onToggle,
  });

  final String category;
  final List<PantryConstantItem> items;
  final Map<String, String?> imageMap;
  final List<String> selectedItems;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PantryConstants.categoryDisplayKeys[category]?.tr() ?? category,
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
            final isSelected = selectedItems.contains(item.name);
            final imageUrl = imageMap[item.name] ?? item.imageUrl;
            return _PantryItemChip(
              label: item.displayName,
              imageUrl: imageUrl,
              isSelected: isSelected,
              onTap: () => onToggle(item.name),
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
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.only(left: 4, right: 14, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _chipPlaceholder(),
                      errorWidget: (_, __, ___) => _chipPlaceholder(),
                    )
                  : _chipPlaceholder(),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipPlaceholder() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.restaurant_outlined,
        size: 16,
        color: Colors.grey.shade400,
      ),
    );
  }
}
