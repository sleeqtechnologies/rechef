import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import 'pages/welcome_page.dart';
import 'pages/goals_page.dart';
import 'pages/pain_point_page.dart';
import 'pages/recipe_sources_page.dart';
import 'pages/import_demo_page.dart';
import 'pages/organization_page.dart';
import 'pages/cookbook_feature_page.dart';
import 'pages/pantry_setup_page.dart';
import 'pages/grocery_feature_page.dart';
import 'pages/share_feature_page.dart';
import 'pages/better_cook_page.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final isWelcomePage = state.currentPage == 0;

    return Scaffold(
      body: Stack(
        children: [
          // Page content (full screen)
          PageView(
            controller: notifier.pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: notifier.setPage,
            children: const [
              WelcomePage(), // 0
              GoalsPage(), // 1
              PainPointPage(), // 2
              RecipeSourcesPage(), // 3
              ImportDemoPage(), // 4
              OrganizationPage(), // 5
              CookbookFeaturePage(), // 6
              PantrySetupPage(), // 7
              GroceryFeaturePage(), // 8
              ShareFeaturePage(), // 9
              BetterCookPage(), // 10
            ],
          ),

          // Back button + segmented progress bar (hidden on welcome page)
          if (!isWelcomePage)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          onPressed: () => notifier.previousPage(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _SegmentedProgressBar(
                          currentStep: state.currentPage,
                          // Skip counting the welcome page in the bar
                          totalSteps: onboardingPageCount - 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Segmented progress bar inspired by the cooking mode progress bar.
/// Each segment fills with accent color as you progress.
class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    // currentStep is 1-indexed here (page 1 = first segment)
    final activeIndex = currentStep - 1;

    return Row(
      children: List.generate(totalSteps, (index) {
        final isFilled = index <= activeIndex;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 3 : 0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: isFilled ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4F63),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
