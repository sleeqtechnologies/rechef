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
import 'pages/pro_plan_page.dart';
import 'pages/create_account_page.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          // Progress bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: _ProgressBar(progress: state.progress),
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: notifier.pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: notifier.setPage,
              children: const [
                WelcomePage(),           // 0
                GoalsPage(),             // 1
                PainPointPage(),         // 2
                RecipeSourcesPage(),     // 3
                ImportDemoPage(),        // 4
                OrganizationPage(),      // 5
                CookbookFeaturePage(),   // 6
                PantrySetupPage(),       // 7
                GroceryFeaturePage(),    // 8
                ShareFeaturePage(),      // 9
                BetterCookPage(),        // 10
                ProPlanPage(),           // 11
                CreateAccountPage(),     // 12
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: Colors.grey.shade200,
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4F63)),
      ),
    );
  }
}
