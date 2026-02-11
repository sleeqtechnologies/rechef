import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/onboarding_data.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';
import '../widgets/selectable_chip.dart';

class RecipeSourcesPage extends ConsumerWidget {
  const RecipeSourcesPage({super.key});

  static const _sourceIcons = <String, IconData>{
    RecipeSources.tiktok: Icons.music_note_rounded,
    RecipeSources.instagram: Icons.camera_alt_rounded,
    RecipeSources.youtube: Icons.play_circle_rounded,
    RecipeSources.pinterest: Icons.push_pin_rounded,
    RecipeSources.foodBlogs: Icons.language_rounded,
    RecipeSources.cookbooks: Icons.menu_book_rounded,
    RecipeSources.friendsFamily: Icons.people_rounded,
    RecipeSources.other: Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingPageWrapper(
      title: 'Where do you find recipes?',
      subtitle: 'Select all that apply',
      showBackButton: true,
      onBack: () => notifier.previousPage(),
      bottomAction: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: state.canProceed ? () => notifier.nextPage() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4F63),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade200,
            disabledForegroundColor: Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: RecipeSources.labels.entries.map((entry) {
          final isSelected = state.data.recipeSources.contains(entry.key);
          return SelectableChip(
            label: entry.value,
            isSelected: isSelected,
            onTap: () => notifier.toggleRecipeSource(entry.key),
            icon: Icon(
              _sourceIcons[entry.key] ?? Icons.circle,
              size: 18,
              color: isSelected
                  ? const Color(0xFFFF4F63)
                  : Colors.grey.shade600,
            ),
          );
        }).toList(),
      ),
    );
  }
}
