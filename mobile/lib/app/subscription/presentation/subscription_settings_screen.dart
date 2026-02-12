import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_snack_bar.dart';

import '../subscription_provider.dart';

/// A screen for managing subscription settings.
///
/// Shows the current subscription status, and provides actions to:
/// - Upgrade (show paywall) if not subscribed
/// - Manage subscription (Customer Center) if subscribed
/// - Restore purchases
class SubscriptionSettingsScreen extends ConsumerWidget {
  const SubscriptionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('subscription.title'.tr()),
      ),
      body: subscriptionAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'subscription.unable_to_load'.tr(),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => ref.read(subscriptionProvider.notifier).refresh(),
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
        data: (status) => _SubscriptionContent(status: status),
      ),
    );
  }
}

class _SubscriptionContent extends ConsumerWidget {
  const _SubscriptionContent({required this.status});

  final dynamic status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isProUserProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Status card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFE8F5E9)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 48,
                color: isActive
                    ? const Color(0xFF2E7D32)
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                isActive ? 'subscription.pro_active'.tr() : 'subscription.free_plan'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF2E7D32)
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Text(
                  'subscription.full_access'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF388E3C),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'subscription.upgrade_unlock'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Actions
        if (!isActive) ...[
          FilledButton.icon(
            onPressed: () async {
              await ref.read(subscriptionProvider.notifier).showPaywall();
            },
            icon: const Icon(Icons.rocket_launch_rounded),
            label: Text('subscription.upgrade_to_pro'.tr()),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (isActive) ...[
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(subscriptionProvider.notifier).showCustomerCenter();
            },
            icon: const Icon(Icons.settings_rounded),
            label: Text('subscription.manage'.tr()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(subscriptionProvider.notifier).restorePurchases();
            if (!context.mounted) return;
            final restored = ref.read(isProUserProvider);
            AppSnackBar.show(
              context,
              message: restored
                  ? 'subscription.restored_success'.tr()
                  : 'subscription.no_purchases'.tr(),
              type: restored
                  ? SnackBarType.success
                  : SnackBarType.info,
            );
          },
          icon: const Icon(Icons.restore_rounded),
          label: Text('subscription.restore'.tr()),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
