import 'package:purchases_flutter/purchases_flutter.dart';

/// Constants for RevenueCat entitlement and product identifiers.
class SubscriptionConstants {
  SubscriptionConstants._();

  /// The entitlement identifier configured in RevenueCat dashboard.
  static const String entitlementId = 'Rechef Pro';

  /// Product identifiers for subscription tiers.
  static const String monthlyProductId = 'monthly';
  static const String yearlyProductId = 'yearly';
}

/// Represents the current subscription status of the user.
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isActive,
    required this.customerInfo,
    this.activeEntitlement,
  });

  /// Whether the user has an active "Rechef Pro" entitlement.
  final bool isActive;

  /// The full customer info from RevenueCat.
  final CustomerInfo customerInfo;

  /// The active entitlement info, if any.
  final EntitlementInfo? activeEntitlement;

  /// Convenience: the product identifier of the active subscription.
  String? get activeProductIdentifier =>
      activeEntitlement?.productIdentifier;

  /// Convenience: when the subscription will expire (or null).
  DateTime? get expirationDate {
    final dateStr = activeEntitlement?.expirationDate;
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Convenience: whether the subscription will auto-renew.
  bool get willRenew => activeEntitlement?.willRenew ?? false;

  /// Factory to create a status from raw CustomerInfo.
  factory SubscriptionStatus.fromCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.all[SubscriptionConstants.entitlementId];
    return SubscriptionStatus(
      isActive: entitlement?.isActive ?? false,
      customerInfo: info,
      activeEntitlement: entitlement?.isActive == true ? entitlement : null,
    );
  }
}
