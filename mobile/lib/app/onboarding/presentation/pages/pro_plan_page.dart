import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../subscription/domain/subscription_status.dart';
import '../../../subscription/subscription_provider.dart';
import '../../providers/onboarding_provider.dart';

class ProPlanPage extends ConsumerStatefulWidget {
  const ProPlanPage({super.key});

  @override
  ConsumerState<ProPlanPage> createState() => _ProPlanPageState();
}

class _ProPlanPageState extends ConsumerState<ProPlanPage> {
  Offering? _offering;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOffering();
    });
  }

  Future<void> _loadOffering() async {
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final offering = await repo.getOffering(SubscriptionConstants.offeringId);
      if (mounted) {
        setState(() {
          _offering = offering;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProvider.notifier);

    return SafeArea(
      child: Column(
        children: [
          // Space for header overlay + skip button
          const SizedBox(height: 52),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
                child: TextButton(
                onPressed: () => notifier.nextPage(),
                child: Text(
                  'onboarding.maybe_later'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),

          // Paywall content
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _loadFailed || _offering == null
                ? _FallbackProContent(onSkip: () => notifier.nextPage())
                : PaywallView(
                    offering: _offering!,
                    onDismiss: () => notifier.nextPage(),
                    onRestoreCompleted: (CustomerInfo customerInfo) {
                      notifier.setProSubscription(true);
                      notifier.nextPage();
                    },
                    onPurchaseCompleted:
                        (
                          CustomerInfo customerInfo,
                          StoreTransaction storeTransaction,
                        ) {
                          notifier.setProSubscription(true);
                          notifier.nextPage();
                        },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Fallback UI shown when the RevenueCat offering can't be loaded.
class _FallbackProContent extends StatelessWidget {
  const _FallbackProContent({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              size: 40,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'onboarding.unlock_full'.tr(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'onboarding.unlock_body'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onSkip,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F63),
                foregroundColor: Colors.white,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
