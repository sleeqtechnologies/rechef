import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'data/subscription_repository.dart';
import 'domain/subscription_status.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// The RevenueCat API key. Replace with platform-specific keys if needed.
const _revenueCatApiKey = 'test_HZPsnVkxuDTJGMjFiKBaxHhNTiu';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(apiKey: _revenueCatApiKey);
});

// ---------------------------------------------------------------------------
// Subscription status notifier
// ---------------------------------------------------------------------------

/// Manages the subscription status and listens for real-time updates.
final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
  SubscriptionNotifier.new,
);

class SubscriptionNotifier extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    final repo = ref.read(subscriptionRepositoryProvider);

    // Listen for RevenueCat customer info changes and refresh state.
    repo.addCustomerInfoUpdateListener((customerInfo) {
      final newStatus = SubscriptionStatus.fromCustomerInfo(customerInfo);
      state = AsyncData(newStatus);
    });

    return repo.getSubscriptionStatus();
  }

  /// Refresh subscription status from RevenueCat.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(subscriptionRepositoryProvider).getSubscriptionStatus();
    });
  }

  /// Present the RevenueCat paywall and update status on completion.
  Future<PaywallResult> showPaywall() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.presentPaywall();

    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await refresh();
    }

    return result;
  }

  /// Present the paywall only if the user doesn't have Rechef Pro.
  Future<PaywallResult> showPaywallIfNeeded() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.presentPaywallIfNeeded();

    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await refresh();
    }

    return result;
  }

  /// Present the RevenueCat Customer Center.
  Future<void> showCustomerCenter() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    await repo.presentCustomerCenter();
    // Refresh after user may have made changes.
    await refresh();
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(subscriptionRepositoryProvider).restorePurchases();
    });
  }
}

// ---------------------------------------------------------------------------
// Convenience providers
// ---------------------------------------------------------------------------

/// Whether the current user has an active "Rechef Pro" subscription.
final isProUserProvider = Provider<bool>((ref) {
  final status = ref.watch(subscriptionProvider);
  return status.value?.isActive ?? false;
});

/// The active entitlement info, if any.
final activeEntitlementProvider = Provider<EntitlementInfo?>((ref) {
  final status = ref.watch(subscriptionProvider);
  return status.value?.activeEntitlement;
});
