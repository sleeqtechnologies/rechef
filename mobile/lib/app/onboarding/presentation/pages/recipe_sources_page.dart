import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../domain/onboarding_data.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';
import '../widgets/selectable_chip.dart';

class RecipeSourcesPage extends ConsumerWidget {
  const RecipeSourcesPage({super.key});

  static const _sourceIcons = <String, IconData>{
    RecipeSources.tiktok: SimpleIcons.tiktok,
    RecipeSources.instagram: SimpleIcons.instagram,
    RecipeSources.youtube: SimpleIcons.youtube,
    RecipeSources.pinterest: SimpleIcons.pinterest,
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
        alignment: WrapAlignment.center,
        children: RecipeSources.labels.entries.map((entry) {
          final isSelected = state.data.recipeSources.contains(entry.key);
          return SelectableChip(
            label: entry.value,
            isSelected: isSelected,
            onTap: () => notifier.toggleRecipeSource(entry.key),
            icon: Icon(
              _sourceIcons[entry.key] ?? Icons.circle,
              size: 18,
              color: Colors.black87,
            ),
          );
        }).toList(),
      ),
    );
  }
}
