import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';

class ShareFeaturePage extends ConsumerWidget {
  const ShareFeaturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingPageWrapper(
      title: 'Share recipes with anyone',
      subtitle: 'Send any recipe to friends and family with a single link',
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
          const SizedBox(height: 24),
          // Share link preview mockup
          _SharePreviewMockup(),
          const SizedBox(height: 40),
          // Share channels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareChannel(
                icon: Icons.message_rounded,
                label: 'Message',
                color: const Color(0xFF34C759),
              ),
              _ShareChannel(
                icon: Icons.email_rounded,
                label: 'Email',
                color: const Color(0xFF007AFF),
              ),
              _ShareChannel(
                icon: Icons.copy_rounded,
                label: 'Copy Link',
                color: const Color(0xFFFF9500),
              ),
              _ShareChannel(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                color: Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Recipients can view the full recipe -- no app download required.',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.6),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SharePreviewMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Recipe image placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4F63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              size: 32,
              color: Color(0xFFFF4F63),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Garlic Butter Salmon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '25 min  ·  4 servings',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4F63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'rechef.app/recipe/abc123',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF4F63),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareChannel extends StatelessWidget {
  const _ShareChannel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
