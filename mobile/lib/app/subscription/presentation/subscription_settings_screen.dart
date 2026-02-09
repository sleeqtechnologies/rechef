import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text('Subscription'),
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
                  'Unable to load subscription info',
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
                  child: const Text('Retry'),
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
                isActive ? 'Rechef Pro Active' : 'Free Plan',
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
                  'You have full access to all features',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF388E3C),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'Upgrade to unlock all features',
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
            label: const Text('Upgrade to Rechef Pro'),
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
            label: const Text('Manage Subscription'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  restored
                      ? 'Purchases restored successfully!'
                      : 'No previous purchases found.',
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          icon: const Icon(Icons.restore_rounded),
          label: const Text('Restore Purchases'),
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
