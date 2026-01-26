import 'package:flutter/material.dart';

/// Consistent spacing constants used throughout the app
class AppSpacing {
  AppSpacing._();

  /// Horizontal margin for scaffold content, app bar, and bottom nav bar
  static const double horizontalMargin = 16.0;

  /// Vertical padding for bottom nav bar
  static const double bottomNavVerticalPadding = 8.0;

  /// App bar horizontal padding
  static const double appBarHorizontalPadding = 16.0;

  /// Standard horizontal padding
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: horizontalMargin,
  );

  /// Bottom nav bar padding
  static const EdgeInsets bottomNavPadding = EdgeInsets.symmetric(
    horizontal: horizontalMargin,
    vertical: bottomNavVerticalPadding,
  );

  /// App bar padding
  static const EdgeInsets appBarPadding = EdgeInsets.symmetric(
    horizontal: appBarHorizontalPadding,
  );
}
