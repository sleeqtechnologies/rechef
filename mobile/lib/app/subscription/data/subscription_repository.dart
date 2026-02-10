import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../domain/subscription_status.dart';

/// Repository handling all RevenueCat SDK interactions.
class SubscriptionRepository {
  SubscriptionRepository({required this.apiKey});

  final String apiKey;
  bool _isConfigured = false;

  /// Initialize and configure the RevenueCat SDK.
  ///
  /// Call this once during app startup, after Firebase Auth is ready.
  /// Pass the Firebase UID as [appUserId] to link RevenueCat to the user.
  Future<void> configure({String? appUserId}) async {
    if (_isConfigured) return;

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

    final configuration = PurchasesConfiguration(apiKey)
      ..appUserID = appUserId;

    try {
      await Purchases.configure(configuration);
      _isConfigured = true;
    } catch (e) {
      // Handle configuration errors gracefully
      // Common issue: Products not configured in RevenueCat dashboard yet
      if (kDebugMode) {
        debugPrint('[RevenueCat] Configuration warning: $e');
        debugPrint('[RevenueCat] This is usually safe to ignore if you\'re still setting up products in the dashboard.');
      }
      // Still mark as configured so we don't retry repeatedly
      _isConfigured = true;
      // Re-throw only if it's a critical error (not configuration warnings)
      final errorString = e.toString();
      if (!errorString.contains('CONFIGURATION_ERROR') && 
          !errorString.contains('offerings')) {
        rethrow;
      }
    }
  }

  /// Log in to RevenueCat with the given user ID (typically Firebase UID).
  ///
  /// This merges any anonymous purchases with the identified user.
  Future<CustomerInfo> logIn(String appUserId) async {
    final result = await Purchases.logIn(appUserId);
    return result.customerInfo;
  }

  /// Log out the current RevenueCat user (revert to anonymous).
  Future<CustomerInfo> logOut() async {
    return Purchases.logOut();
  }

  /// Fetch the current customer info from RevenueCat.
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    final customerInfo = await Purchases.getCustomerInfo();
    return SubscriptionStatus.fromCustomerInfo(customerInfo);
  }

  /// Check if the user has the "Rechef Pro" entitlement.
  Future<bool> isProUser() async {
    final status = await getSubscriptionStatus();
    return status.isActive;
  }

  /// Fetch the current offerings (products configured in RevenueCat dashboard).
  Future<Offerings> getOfferings() async {
    return Purchases.getOfferings();
  }

  /// Fetch a specific offering by identifier.
  Future<Offering?> getOffering(String offeringId) async {
    final offerings = await getOfferings();
    return offerings.all[offeringId];
  }

  /// Purchase a specific package (e.g. monthly or yearly).
  Future<SubscriptionStatus> purchasePackage(Package package) async {
    final result = await Purchases.purchasePackage(package);
    return SubscriptionStatus.fromCustomerInfo(result.customerInfo);
  }

  /// Restore previous purchases.
  Future<SubscriptionStatus> restorePurchases() async {
    final customerInfo = await Purchases.restorePurchases();
    return SubscriptionStatus.fromCustomerInfo(customerInfo);
  }

  /// Present the RevenueCat paywall UI.
  ///
  /// Returns the paywall result indicating what happened.
  Future<PaywallResult> presentPaywall() async {
    final offering = await getOffering(SubscriptionConstants.offeringId);
    if (offering != null) {
      return RevenueCatUI.presentPaywall(offering: offering);
    }
    // Fallback to default offering if "pro" offering not found
    return RevenueCatUI.presentPaywall();
  }

  /// Present the paywall only if the user doesn't have the entitlement.
  Future<PaywallResult> presentPaywallIfNeeded() async {
    return RevenueCatUI.presentPaywallIfNeeded(
      SubscriptionConstants.entitlementId,
    );
  }

  /// Present the RevenueCat Customer Center for subscription management.
  Future<void> presentCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
  }

  /// Listen to customer info updates from RevenueCat.
  ///
  /// Returns a stream that emits whenever the customer info changes
  /// (after purchases, restores, or server-side changes).
  void addCustomerInfoUpdateListener(
    void Function(CustomerInfo) listener,
  ) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }
}
