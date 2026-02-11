import 'dart:ui';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/app_snack_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../subscription/subscription_provider.dart';
import '../providers/auth_providers.dart';

class AccountSheet extends ConsumerWidget {
  const AccountSheet({super.key});

  static const _accentColor = Color(0xFFFF4F63);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (_) => const AccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        'Settings',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      FakeGlass(
                        shape: LiquidRoundedSuperellipse(borderRadius: 999),
                        settings: const LiquidGlassSettings(
                          blur: 10,
                          glassColor: Color(0x18000000),
                        ),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/x.svg',
                              width: 18,
                              height: 18,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // User avatar and name
                        if (user != null) ...[
                          Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      user.photoUrl != null &&
                                              user.photoUrl!.trim().isNotEmpty
                                          ? NetworkImage(user.photoUrl!)
                                          : null,
                                  backgroundColor: _accentColor,
                                  child: user.photoUrl == null ||
                                          user.photoUrl!.trim().isEmpty
                                      ? Text(
                                          user.initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 24,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  user.displayName ?? user.email ?? 'Account',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (user.email != null)
                                  Text(
                                    user.email!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Account section – subscription
                        _SubscriptionSection(),
                        const SizedBox(height: 16),

                        // Other section
                        _SectionCard(
                          label: 'Other',
                          children: [
                            _SettingsRow(
                              title: 'Privacy Notice',
                              onTap: () => _openUrl('https://rechef.app/privacy'),
                            ),
                            _SettingsRow(
                              title: 'Terms of Service',
                              onTap: () => _openUrl('https://rechef.app/terms'),
                            ),
                            _SettingsRow(
                              title: 'App version',
                              trailing: Text(
                                '1.0.0',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              showChevron: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Delete account
                        _SectionCard(
                          children: [
                            _SettingsRow(
                              title: 'Delete my account',
                              titleColor: _accentColor,
                              onTap: () => _confirmDeleteAccount(context, ref),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Sign out button
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () async {
                              await ref.read(authRepositoryProvider).signOut();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Sign out',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        // User ID
                        if (user != null) ...[
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              'ID: ${user.id}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _SubscriptionSection extends ConsumerWidget {
  const _SubscriptionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProUserProvider);

    return _SectionCard(
      label: 'Account',
      children: [
        if (!isPro)
          _SettingsRow(
            title: 'Upgrade to Rechef Pro',
            onTap: () async {
              await ref.read(subscriptionProvider.notifier).showPaywall();
            },
          ),
        if (isPro)
          _SettingsRow(
            title: 'Manage subscription',
            onTap: () async {
              await ref.read(subscriptionProvider.notifier).showCustomerCenter();
            },
          ),
        _SettingsRow(
          title: 'Restore purchases',
          onTap: () async {
            await ref.read(subscriptionProvider.notifier).restorePurchases();
            if (!context.mounted) return;
            final restored = ref.read(isProUserProvider);
            AppSnackBar.show(
              context,
              message: restored
                  ? 'Purchases restored successfully.'
                  : 'No previous purchases found.',
              type: restored
                  ? SnackBarType.success
                  : SnackBarType.info,
            );
          },
        ),
      ],
    );
  }
}

extension _AccountSheetExtension on AccountSheet {
  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'Delete account',
      message:
          'Are you sure? This will permanently delete your account and all your data. This action cannot be undone.',
      actions: [
        AlertAction(
          title: 'Cancel',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'Delete',
          style: AlertActionStyle.destructive,
          onPressed: () async {
            try {
              await ref.read(authRepositoryProvider).deleteAccount();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            } catch (e) {
              if (context.mounted) {
                AppSnackBar.show(
                  context,
                  message: 'Failed to delete account: $e',
                  type: SnackBarType.error,
                );
              }
            }
          },
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.label, required this.children});

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                label!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.grey.shade100,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    this.titleColor,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (showChevron && onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}
