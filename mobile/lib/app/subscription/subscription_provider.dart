import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../core/config/env.dart';
import '../../core/services/firebase_analytics_provider.dart';
import 'data/subscription_repository.dart';
import 'domain/subscription_status.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(apiKey: revenueCatApiKey);
});

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
      SubscriptionNotifier.new,
    );

class SubscriptionNotifier extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    final repo = ref.read(subscriptionRepositoryProvider);

    repo.addCustomerInfoUpdateListener((customerInfo) {
      final newStatus = SubscriptionStatus.fromCustomerInfo(customerInfo);
      state = AsyncData(newStatus);
    });

    return repo.getSubscriptionStatus();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(subscriptionRepositoryProvider).getSubscriptionStatus();
    });
  }

  Future<PaywallResult> showPaywall({String source = 'unknown'}) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final analytics = ref.read(appAnalyticsProvider);
    await analytics.logPaywallViewed(source: source);
    final result = await repo.presentPaywall();
    await analytics.logPaywallResult(
      source: source,
      result: result.toString().split('.').last,
    );

    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await refresh();
    }

    return result;
  }

  Future<PaywallResult> showPaywallIfNeeded({String source = 'unknown'}) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final analytics = ref.read(appAnalyticsProvider);
    await analytics.logPaywallViewed(source: source);
    final result = await repo.presentPaywallIfNeeded();
    await analytics.logPaywallResult(
      source: source,
      result: result.toString().split('.').last,
    );

    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await refresh();
    }

    return result;
  }

  Future<void> showCustomerCenter({String source = 'unknown'}) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    await ref
        .read(appAnalyticsProvider)
        .logCustomerCenterOpened(source: source);
    await repo.presentCustomerCenter();
    await refresh();
  }

  Future<void> restorePurchases({String source = 'unknown'}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final status = await ref
          .read(subscriptionRepositoryProvider)
          .restorePurchases();
      await ref
          .read(appAnalyticsProvider)
          .logSubscriptionRestoreCompleted(
            source: source,
            active: status.isActive,
            entitlementCount: status.customerInfo.entitlements.active.length,
          );
      return status;
    });
  }
}

final isProUserProvider = Provider<bool>((ref) {
  final status = ref.watch(subscriptionProvider);
  return status.value?.isActive ?? false;
});

final activeEntitlementProvider = Provider<EntitlementInfo?>((ref) {
  final status = ref.watch(subscriptionProvider);
  return status.value?.activeEntitlement;
});
