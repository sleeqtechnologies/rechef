import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final router = ref.read(routerProvider);
    // TODO: Navigate to social media/URL import screen
    router.go('/recipes/import');
  }

  void _onCameraTap() {
    final router = ref.read(routerProvider);
    router.go('/camera');
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(widget.location);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: _isMenuExpanded
          ? GestureDetector(
              onTap: () {
                // Close menu when tapping outside
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
        accentColor: _accentColor,
        onMenuStateChanged: (isExpanded) {
          setState(() {
            _isMenuExpanded = isExpanded;
          });
        },
      ),
    );
  }
}
