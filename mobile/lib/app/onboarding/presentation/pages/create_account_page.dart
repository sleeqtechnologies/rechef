import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/providers/auth_providers.dart';
import '../../data/onboarding_repository.dart';
import '../../providers/onboarding_provider.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  String? _loadingButton;
  String? _error;

  bool get _loading => _loadingButton != null;

  Future<void> _completeOnboarding() async {
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    final repo = ref.read(onboardingRepositoryProvider);
    final data = ref.read(onboardingProvider).data;

    try {
      // Save onboarding data locally first
      await repo.saveOnboardingDataLocally(data);

      // Sync onboarding responses to the API
      await repo.syncOnboardingData(data);

      // Sync pantry items via the existing pantry endpoint
      await repo.syncPantryItems(data.pantryItems);

      // Mark onboarding as complete
      await repo.markOnboardingComplete();

      // Invalidate the onboarding complete provider so router re-evaluates
      ref.invalidate(onboardingCompleteProvider);
    } catch (e) {
      debugPrint('[CreateAccountPage] Error completing onboarding: $e');
      // Still mark complete so user isn't stuck
      await repo.markOnboardingComplete();
      ref.invalidate(onboardingCompleteProvider);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loadingButton = 'google';
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      await _completeOnboarding();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Google sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingButton = null);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _loadingButton = 'apple';
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithApple();
      await _completeOnboarding();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              "Apple sign-in isn't available right now. Please try Google or continue without an account.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingButton = null);
      }
    }
  }

  Future<void> _continueWithoutAccount() async {
    setState(() {
      _loadingButton = 'guest';
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
      await _completeOnboarding();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = 'Could not continue without an account. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingButton = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProvider.notifier);
    final state = ref.watch(onboardingProvider);
    final pantryCount = state.data.pantryItems.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: IconButton(
                  onPressed: () => notifier.previousPage(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
              ),
            ),

            const Spacer(flex: 1),

            // Header
            const Text(
              'Create your account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _buildSubtitle(state),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Summary of what's ready
            if (pantryCount > 0 || state.data.goals.isNotEmpty)
              _ReadySummary(
                goalCount: state.data.goals.length,
                pantryCount: pantryCount,
                hasProPlan: state.data.subscribedToPro,
              ),

            const Spacer(flex: 2),

            // Error message
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Google sign-in
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  disabledBackgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 0,
                ),
                child: _loadingButton == 'google'
                    ? const CupertinoActivityIndicator(
                        radius: 12,
                        color: Colors.black54,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.google.com/favicon.ico',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Apple sign-in
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _signInWithApple,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.black.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _loadingButton == 'apple'
                    ? const CupertinoActivityIndicator(
                        radius: 12,
                        color: Colors.white70,
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Continue with Apple',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Continue without account
            TextButton(
              onPressed: _loading ? null : _continueWithoutAccount,
              child: _loadingButton == 'guest'
                  ? const CupertinoActivityIndicator(
                      radius: 10,
                      color: Colors.grey,
                    )
                  : Text(
                      'Continue without an account',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(OnboardingState state) {
    if (state.data.pantryItems.isNotEmpty) {
      return 'Your preferences and pantry are ready to go';
    }
    return 'Your preferences are saved and ready to go';
  }
}

class _ReadySummary extends StatelessWidget {
  const _ReadySummary({
    required this.goalCount,
    required this.pantryCount,
    required this.hasProPlan,
  });

  final int goalCount;
  final int pantryCount;
  final bool hasProPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (goalCount > 0)
            _SummaryItem(
              icon: Icons.flag_rounded,
              text: '$goalCount goal${goalCount == 1 ? '' : 's'} set',
            ),
          if (pantryCount > 0) ...[
            if (goalCount > 0) const SizedBox(height: 8),
            _SummaryItem(
              icon: Icons.kitchen_rounded,
              text: '$pantryCount pantry item${pantryCount == 1 ? '' : 's'} ready',
            ),
          ],
          if (hasProPlan) ...[
            const SizedBox(height: 8),
            const _SummaryItem(
              icon: Icons.star_rounded,
              text: 'Rechef Pro activated',
              color: Color(0xFF219653),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? const Color(0xFFFF4F63);

    return Row(
      children: [
        Icon(icon, size: 18, color: itemColor),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Icon(Icons.check_rounded, size: 18, color: itemColor),
      ],
    );
  }
}
