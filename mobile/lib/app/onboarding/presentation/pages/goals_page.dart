import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/onboarding_data.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';
import '../widgets/selectable_chip.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingPageWrapper(
      title: 'onboarding.goals_title'.tr(),
      subtitle: 'onboarding.goals_subtitle'.tr(),
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
          child: Text(
            'common.continue_btn'.tr(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: OnboardingGoals.labels.entries.map((entry) {
          final isSelected = state.data.goals.contains(entry.key);
          return SelectableChip(
            label: entry.value.tr(),
            isSelected: isSelected,
            onTap: () => notifier.toggleGoal(entry.key),
          );
        }).toList(),
      ),
    );
  }
}
