import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/onboarding_repository.dart';
import '../providers/auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  String? _loadingButton;
  String? _error;

  bool get _loading => _loadingButton != null;

  /// After authentication, sync any locally saved onboarding data to the backend.
  Future<void> _syncOnboardingData() async {
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final data = await repo.loadOnboardingDataLocally();
      if (data != null) {
        await repo.syncOnboardingData(data);
        if (data.pantryItems.isNotEmpty) {
          await repo.syncPantryItems(data.pantryItems);
        }
      }
    } catch (e) {
      debugPrint('[SignInScreen] Error syncing onboarding data: $e');
      // Non-blocking -- user can still proceed
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loadingButton = 'google';
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      await _syncOnboardingData();
    } catch (e) {
      setState(() => _error = 'Google sign-in failed: $e');
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
      await _syncOnboardingData();
    } catch (e) {
      setState(() => _error = 'Could not continue without an account: $e');
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
      await _syncOnboardingData();
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      setState(
        () => _error =
            'Apple sign-in isn\'t available right now. Please try again later, use Google, or continue without an account.',
      );
    } finally {
      if (mounted) {
        setState(() => _loadingButton = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF4F6C), Color(0xFFFF4F4F)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset('assets/rechef-logo.png', height: 90, width: 90),
                const SizedBox(height: 64),
                Text(
                  'auth.tagline'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 3),
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Always show buttons, just disable when loading
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      disabledBackgroundColor: Colors.white.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
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
                              Text(
                                'auth.continue_with_google'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.apple, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'auth.continue_with_apple'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading ? null : _continueWithoutAccount,
                  child: _loadingButton == 'guest'
                      ? const CupertinoActivityIndicator(
                          radius: 10,
                          color: Colors.white70,
                        )
                      : Text(
                          'auth.continue_without_account'.tr(),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
