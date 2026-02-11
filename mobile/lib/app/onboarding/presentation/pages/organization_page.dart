import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/onboarding_data.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';

class OrganizationPage extends ConsumerWidget {
  const OrganizationPage({super.key});

  static const _methodIcons = <String, IconData>{
    OrganizationMethods.screenshots: Icons.screenshot_rounded,
    OrganizationMethods.bookmarks: Icons.bookmark_rounded,
    OrganizationMethods.notesApp: Icons.note_alt_rounded,
    OrganizationMethods.dontOrganize: Icons.shuffle_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingPageWrapper(
      title: 'How do you organize recipes now?',
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
      child: Column(
        children: OrganizationMethods.labels.entries.map((entry) {
          final isSelected = state.data.organizationMethod == entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OrganizationCard(
              label: entry.value,
              icon: _methodIcons[entry.key] ?? Icons.circle,
              isSelected: isSelected,
              onTap: () => notifier.setOrganizationMethod(entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFF4F63);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? accentColor : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? accentColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: accentColor, size: 24),
          ],
        ),
      ),
    );
  }
}
