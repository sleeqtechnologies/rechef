import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/recipe_repository.dart';
import '../recipe_provider.dart';
import '../../../core/network/api_client.dart';

class ShareStatsScreen extends ConsumerStatefulWidget {
  const ShareStatsScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<ShareStatsScreen> createState() => _ShareStatsScreenState();
}

class _ShareStatsScreenState extends ConsumerState<ShareStatsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;
  String? _recipeName;

  @override
  void initState() {
    super.initState();
    _recipeName = ref.read(recipeByIdProvider(widget.recipeId)).value?.name;
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = RecipeRepository(apiClient: ApiClient());
      final stats = await repo.fetchShareStats(widget.recipeId);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _getInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/recipes');
            }
          },
        ),
        title: Text(
          'Share analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load stats',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: _loadStats,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_recipeName != null) ...[
                          Text(
                            _recipeName!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          'Engagement',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          icon: Icons.visibility_outlined,
                          label: 'Web views',
                          value: '${_getInt(_stats?['webViews'])}',
                        ),
                        _StatCard(
                          icon: Icons.open_in_new,
                          label: 'App opens',
                          value: '${_getInt(_stats?['appOpens'])}',
                        ),
                        _StatCard(
                          icon: Icons.get_app,
                          label: 'New installs',
                          value: '${_getInt(_stats?['appInstalls'])}',
                        ),
                        _StatCard(
                          icon: Icons.bookmark_outline,
                          label: 'Saves',
                          value: '${_getInt(_stats?['recipeSaves'])}',
                        ),
                        _StatCard(
                          icon: Icons.shopping_cart_outlined,
                          label: 'Grocery adds',
                          value: '${_getInt(_stats?['groceryAdds'])}',
                        ),
                        _StatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Grocery purchases',
                          value: '${_getInt(_stats?['groceryPurchases'])}',
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Audience',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          icon: Icons.people_outline,
                          label: 'Subscribers',
                          value: '${_getInt(_stats?['subscriberCount'])}',
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
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
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
