import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';

class PainPointPage extends ConsumerWidget {
  const PainPointPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingPageWrapper(
      title: "We've been there too",
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Illustration area
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4F63).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 80,
                color: Color(0xFFFF4F63),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Recipes scattered across screenshots, bookmarks, and apps.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "We built Rechef because we were tired of losing great recipes. "
            "Every time we found something amazing, it ended up buried in a "
            "sea of screenshots or forgotten in browser tabs.\n\n"
            "Sound familiar? We built this app for people like us -- and you.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
