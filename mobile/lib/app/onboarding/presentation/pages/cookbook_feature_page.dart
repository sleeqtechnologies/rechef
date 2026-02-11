import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';

class CookbookFeaturePage extends ConsumerWidget {
  const CookbookFeaturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingPageWrapper(
      title: 'Meet your new recipe organizer',
      subtitle: 'Create cookbooks for any occasion',
      showBackButton: true,
      onBack: () => notifier.previousPage(),
      bottomAction: SizedBox(
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
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Cookbook mockup illustration
          _CookbookMockup(),
          const SizedBox(height: 32),
          _FeaturePoint(
            icon: Icons.collections_bookmark_rounded,
            title: 'Organize by theme',
            description:
                'Weeknight dinners, meal prep, holiday favorites -- create a cookbook for anything.',
          ),
          const SizedBox(height: 16),
          _FeaturePoint(
            icon: Icons.add_circle_outline_rounded,
            title: 'Add recipes with a tap',
            description:
                'Save any recipe to one or more cookbooks instantly.',
          ),
          const SizedBox(height: 16),
          _FeaturePoint(
            icon: Icons.search_rounded,
            title: 'Find recipes fast',
            description:
                'No more scrolling through screenshots. Everything in one place.',
          ),
        ],
      ),
    );
  }
}

class _CookbookMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CookbookCard(
            title: 'Weeknight\nDinners',
            color: const Color(0xFFFF4F63),
            recipes: 12,
          ),
          const SizedBox(width: 12),
          _CookbookCard(
            title: 'Meal\nPrep',
            color: const Color(0xFF4F8FFF),
            recipes: 8,
          ),
          const SizedBox(width: 12),
          _CookbookCard(
            title: 'Holiday\nFavorites',
            color: const Color(0xFF4FBF63),
            recipes: 15,
          ),
        ],
      ),
    );
  }
}

class _CookbookCard extends StatelessWidget {
  const _CookbookCard({
    required this.title,
    required this.color,
    required this.recipes,
  });

  final String title;
  final Color color;
  final int recipes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_rounded, color: color, size: 28),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$recipes recipes',
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePoint extends StatelessWidget {
  const _FeaturePoint({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4F63).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFFFF4F63)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
