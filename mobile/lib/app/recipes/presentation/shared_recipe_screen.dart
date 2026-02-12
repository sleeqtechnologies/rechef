import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/recipe_repository.dart';
import '../data/share_event_service.dart';
import '../domain/recipe.dart';
import '../recipe_provider.dart';
import '../../../core/network/api_client.dart';

const _kHasLaunchedBeforeKey = 'share_has_launched_before';

class SharedRecipeScreen extends ConsumerStatefulWidget {
  const SharedRecipeScreen({super.key, required this.shareCode});

  final String shareCode;

  @override
  ConsumerState<SharedRecipeScreen> createState() => _SharedRecipeScreenState();
}

class _SharedRecipeScreenState extends ConsumerState<SharedRecipeScreen> {
  Recipe? _recipe;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRecipe();
  }

  Future<void> _fetchRecipe() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repo = RecipeRepository(apiClient: ApiClient());
      final recipe = await repo.fetchSharedRecipe(widget.shareCode);

      // Record app_open event
      ShareEventService.recordEvent(
        shareCode: widget.shareCode,
        eventType: 'app_open',
      );

      final prefs = await SharedPreferences.getInstance();
      final hasLaunchedBefore = prefs.getBool(_kHasLaunchedBeforeKey) ?? false;
      if (!hasLaunchedBefore) {
        await prefs.setBool(_kHasLaunchedBeforeKey, true);
        ShareEventService.recordEvent(
          shareCode: widget.shareCode,
          eventType: 'app_install',
        );
      }

      if (!mounted) return;

      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRecipe() async {
    if (_recipe == null) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final repo = RecipeRepository(apiClient: ApiClient());
      final saved = await repo.saveSharedRecipe(widget.shareCode);

      // Event is already recorded by the API endpoint, but we can also record here
      // for redundancy

      // Refresh recipes list
      ref.invalidate(recipesProvider);

      if (!mounted) return;

      // Navigate to the saved recipe
      context.go('/recipes/${saved.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      await AdaptiveAlertDialog.show(
        context: context,
        title: 'Failed to save recipe',
        message: e.toString(),
        actions: [
          AlertAction(
            title: 'OK',
            style: AlertActionStyle.defaultAction,
            onPressed: () {},
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_error != null || _recipe == null) {
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
        ),
        body: Center(
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
                _error?.contains('not found') == true
                    ? 'Recipe not found'
                    : 'Could not load recipe',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppBar(
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
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shared Recipe',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save this recipe to your library to access it anytime and get live updates from the creator.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Show recipe preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _recipe!.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (_recipe!.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _recipe!.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveRecipe,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CupertinoActivityIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save to My Recipes',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to recipe detail without saving
                        // This will show read-only view
                        context.go('/recipes/${_recipe!.id}');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Recipe',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
