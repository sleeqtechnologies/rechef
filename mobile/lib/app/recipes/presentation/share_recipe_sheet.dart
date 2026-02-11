import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/share_utils.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';

/// Bottom sheet for sharing a recipe: copy link, share via system, and analytics.
/// Styled like the settings (AccountSheet) UI.
class ShareRecipeSheet extends ConsumerStatefulWidget {
  const ShareRecipeSheet({
    super.key,
    required this.recipe,
    required this.shareUrl,
    required this.shareCode,
  });

  final Recipe recipe;
  final String shareUrl;
  final String shareCode;

  /// Creates share link via API, then shows the sheet. On failure, returns false.
  static Future<bool> show(
    BuildContext context, {
    required Recipe recipe,
  }) async {
    try {
      final client = ApiClient();
      final response = await client.post(ApiEndpoints.shareRecipe(recipe.id));
      if (response.statusCode != 200) return false;
      final data = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map<String, dynamic>)
          : <String, dynamic>{};
      final url =
          (data['url'] as String?) ??
          'https://rechef-ten.vercel.app/recipe/${data['shareCode']}';
      final code = data['shareCode'] as String? ?? '';
      if (!context.mounted) return true;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        useRootNavigator: true,
        builder: (_) =>
            ShareRecipeSheet(recipe: recipe, shareUrl: url, shareCode: code),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  ConsumerState<ShareRecipeSheet> createState() => _ShareRecipeSheetState();
}

class _ShareRecipeSheetState extends ConsumerState<ShareRecipeSheet> {
  Map<String, dynamic>? _stats;
  bool _statsLoading = true;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final repo = RecipeRepository(apiClient: ApiClient());
      final stats = await repo.fetchShareStats(widget.recipe.id);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _statsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  int _getInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.shareUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareViaSystem() async {
    await ShareUtils.shareText(widget.shareUrl, subject: widget.recipe.name);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Actions
                  _ActionTile(
                    icon: Icons.link_rounded,
                    label: _copied ? 'Copied!' : 'Copy link',
                    onTap: _copyLink,
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.share_outlined,
                    label: 'Share via…',
                    onTap: _shareViaSystem,
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  if (_statsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.visibility_outlined,
                            label: 'Views',
                            value: '${_getInt(_stats?['webViews'])}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.bookmark_outline,
                            label: 'Saves',
                            value: '${_getInt(_stats?['recipeSaves'])}',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F5F0),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Colors.grey.shade700),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
