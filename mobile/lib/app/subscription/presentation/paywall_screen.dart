import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../domain/subscription_status.dart';
import '../subscription_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offering? _offering;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOffering();
    });
  }

  Future<void> _loadOffering() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final offering = await repo.getOffering(SubscriptionConstants.offeringId);
    if (mounted) {
      setState(() {
        _offering = offering;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _offering == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'subscription.unable_to_load_offerings'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadOffering();
                      },
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              )
            : PaywallView(
                offering: _offering!,
                onDismiss: () {
                  Navigator.of(context).maybePop();
                },
                onRestoreCompleted: (CustomerInfo customerInfo) {
                  debugPrint(
                    '[PaywallScreen] Restore completed: '
                    '${customerInfo.entitlements.active.keys}',
                  );
                },
                onPurchaseCompleted:
                    (
                      CustomerInfo customerInfo,
                      StoreTransaction storeTransaction,
                    ) {
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
