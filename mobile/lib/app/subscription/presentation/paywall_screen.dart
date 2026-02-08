import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// A full-screen route that embeds the RevenueCat PaywallView widget.
///
/// Use this when you want the paywall as a navigable route (e.g. via GoRouter)
/// rather than a modal overlay.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: PaywallView(
          onDismiss: () {
            Navigator.of(context).maybePop();
          },
          onRestoreCompleted: (CustomerInfo customerInfo) {
            debugPrint(
              '[PaywallScreen] Restore completed: '
              '${customerInfo.entitlements.active.keys}',
            );
          },
          onPurchaseCompleted: (CustomerInfo customerInfo, StoreTransaction storeTransaction) {
            debugPrint(
              '[PaywallScreen] Purchase completed: '
              '${customerInfo.entitlements.active.keys}',
            );
          },
        ),
      ),
    );
  }
}
