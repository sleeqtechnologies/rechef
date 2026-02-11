import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';

class BetterCookPage extends ConsumerWidget {
  const BetterCookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingPageWrapper(
      title: 'Become a better cook with Rechef',
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
          // Summary of benefits
          _BenefitRow(
            icon: Icons.import_contacts_rounded,
            title: 'Save from anywhere',
            description:
                'Import recipes from TikTok, Instagram, YouTube, blogs, and more.',
          ),
          const SizedBox(height: 20),
          _BenefitRow(
            icon: Icons.collections_bookmark_rounded,
            title: 'Stay organized',
            description:
                'Create cookbooks to keep your recipes sorted and easy to find.',
          ),
          const SizedBox(height: 20),
          _BenefitRow(
            icon: Icons.kitchen_rounded,
            title: 'Smart pantry',
            description:
                'Track what you have and find recipes that match your ingredients.',
          ),
          const SizedBox(height: 20),
          _BenefitRow(
            icon: Icons.shopping_cart_rounded,
            title: 'Effortless grocery lists',
            description:
                'Add missing ingredients in a tap and order via Instacart.',
          ),
          const SizedBox(height: 20),
          _BenefitRow(
            icon: Icons.share_rounded,
            title: 'Share with anyone',
            description:
                'Send recipes to friends and family with a single link.',
          ),
          const SizedBox(height: 32),
          // Motivational closer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF4F63).withOpacity(0.08),
                  const Color(0xFFFF4F63).withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "You're about to turn your recipe chaos into cooking confidence. "
              "Let's get started.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4F63).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFFFF4F63)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
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
