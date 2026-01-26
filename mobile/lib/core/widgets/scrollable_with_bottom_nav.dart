import 'package:flutter/material.dart';

/// A widget that wraps scrollable content.
/// Can be extended in the future to add scroll-to-minimize functionality
/// for the custom bottom navigation bar.
class ScrollableWithBottomNav extends StatelessWidget {
  final Widget child;

  const ScrollableWithBottomNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // For now, just return the child as-is
    // Can be extended later to add scroll-to-minimize functionality
    return child;
  }
}
