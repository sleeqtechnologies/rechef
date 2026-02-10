import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/pantry/presentation/add_item_sheet.dart';
import '../app/pantry/pantry_provider.dart';
import '../app/grocery/grocery_provider.dart';
import '../app/recipes/data/share_event_service.dart';
import '../app/recipes/recipe_provider.dart';
import '../app/recipe_import/presentation/import_url_sheet.dart';
import '../app/recipe_import/data/import_repository.dart';
import '../app/recipe_import/import_provider.dart';
import '../app/recipe_import/pending_jobs_provider.dart';
import '../app/recipe_import/monthly_import_usage_provider.dart';
import '../app/subscription/subscription_provider.dart';
import '../core/routing/app_router.dart';
import '../core/widgets/custom_bottom_nav_bar.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String location;

  const MainLayout({super.key, required this.child, required this.location});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  static const Color _accentColor = Color(0xFFFF4F63);
  final GlobalKey<CustomBottomNavBarState> _navBarKey =
      GlobalKey<CustomBottomNavBarState>();
  bool _isMenuExpanded = false;
  bool _pendingImportSheet = false;

  int _getCurrentIndex(String location) {
    if (location.startsWith('/recipes')) {
      return 0;
    } else if (location.startsWith('/pantry')) {
      return 1;
    } else if (location.startsWith('/grocery')) {
      return 2;
    }
    return 0;
  }

  void _onTabTapped(int index) {
    final router = ref.read(routerProvider);
    switch (index) {
      case 0:
        router.go('/recipes');
        break;
      case 1:
        router.go('/pantry');
        break;
      case 2:
        router.go('/grocery');
        break;
    }
  }

  void _onSocialMediaTap() {
    debugPrint('[MainLayout] _onSocialMediaTap called');
    setState(() {
      _pendingImportSheet = true;
    });
  }

  void _showImportUrlSheet() {
    debugPrint('[MainLayout] _showImportUrlSheet called, mounted=$mounted');
    if (!mounted) {
      debugPrint('[MainLayout] _showImportUrlSheet skipped: not mounted');
      return;
    }
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final keyboardHeight = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ImportUrlSheet(),
              Container(
                height: keyboardHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.80),
                ),
              ),
            ],
          ),
        );
      },
    ).then((url) {
      debugPrint('[MainLayout] Import sheet closed with url=$url');
      if (url != null && url.isNotEmpty) {
        _submitRecipeUrl(url);
      }
    });
    debugPrint('[MainLayout] showModalBottomSheet invoked');
  }

  Future<void> _submitRecipeUrl(String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return;

    // Enforce free-tier limit (5 imports per calendar month) using the cached
    // monthlyImportUsageProvider value when available.
    final isPro = ref.read(isProUserProvider);
    if (!isPro) {
      final usageAsync = ref.read(monthlyImportUsageProvider);
      final usage = usageAsync.maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );

      if (usage != null && usage.used >= usage.limit) {
        await ref.read(subscriptionProvider.notifier).showPaywall();
        return;
      }
    }

    try {
      final repo = ref.read(importRepositoryProvider);
      final result = await repo.submitContent(trimmedUrl);

      ref
          .read(pendingJobsProvider.notifier)
          .addJob(
            ContentJob(
              id: result.jobId,
              status: 'pending',
              savedContentId: result.savedContentId,
            ),
          );

      // Refresh monthly usage after a successful import so UI stays in sync.
      ref.invalidate(monthlyImportUsageProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recipe is being generated in the background'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      final router = ref.read(routerProvider);
      router.go('/recipes');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red.shade400,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _onCameraTap() {
    final router = ref.read(routerProvider);
    router.go('/camera');
  }

  Future<void> _onOrderOnlineTap(BuildContext context) async {
    // Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CupertinoActivityIndicator(
              radius: 9,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Text('Creating your shopping list...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final url = await ref.read(groceryProvider.notifier).createOrder();

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Fire grocery_purchase for shared recipes that have items in this order
      final groceryList = ref.read(groceryProvider).value ?? [];
      final recipes = ref.read(recipesProvider).value ?? [];
      final sharedRecipeCodes = <String, String>{};
      for (final r in recipes) {
        if (r.isShared && r.shareCode != null) {
          sharedRecipeCodes[r.id] = r.shareCode!;
        }
      }
      final uncheckedRecipeIds = groceryList
          .where((i) => !i.checked && i.recipeId != null)
          .map((i) => i.recipeId!)
          .toSet();
      for (final recipeId in uncheckedRecipeIds) {
        final shareCode = sharedRecipeCodes[recipeId];
        if (shareCode != null) {
          ShareEventService.recordEvent(
            shareCode: shareCode,
            eventType: 'grocery_purchase',
          );
        }
      }

      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _onPantryAddTap(BuildContext context) {
    showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AddItemSheet(),
              Container(
                height: keyboardHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.80),
                ),
              ),
            ],
          ),
        );
      },
    ).then((ingredients) {
      if (ingredients != null && ingredients.isNotEmpty) {
        ref.read(pantryProvider.notifier).addItems(ingredients);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(widget.location);

    // If the import sheet was requested, show it after this frame completes.
    if (_pendingImportSheet) {
      debugPrint(
        '[MainLayout] build: _pendingImportSheet=true, scheduling postFrameCallback',
      );
      _pendingImportSheet = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[MainLayout] postFrameCallback fired, mounted=$mounted');
        if (mounted) _showImportUrlSheet();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: _isMenuExpanded
          ? Listener(
              onPointerDown: (_) {
                _navBarKey.currentState?.closeMenu();
              },
              behavior: HitTestBehavior.translucent,
              child: widget.child,
            )
          : widget.child,
      bottomNavigationBar: CustomBottomNavBar(
        key: _navBarKey,
        currentIndex: currentIndex,
        onTap: _onTabTapped,
        onSocialMediaTap: _onSocialMediaTap,
        onCameraTap: _onCameraTap,
        onPlusPrimaryAction: widget.location.startsWith('/pantry')
            ? () => _onPantryAddTap(context)
            : widget.location.startsWith('/grocery')
                ? () => _onOrderOnlineTap(context)
                : null,
        accentColor: _accentColor,
        onMenuStateChanged: (isExpanded) {
          setState(() {
            _isMenuExpanded = isExpanded;
          });
        },
        actionLabel: widget.location.startsWith('/grocery')
            ? 'Order Online'
            : null,
        actionColor: widget.location.startsWith('/grocery')
            ? const Color(0xFF2E7D32)
            : null,
      ),
    );
  }
}

