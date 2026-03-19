import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Holds the source rect for the expand-from-card page transition.
class ExpandPageTransition {
  static Rect? sourceRect;

  static CustomTransitionPage<void> page({
    required LocalKey key,
    required Widget child,
  }) {
    final rect = sourceRect;
    sourceRect = null;

    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (rect == null || animation.status == AnimationStatus.reverse) {
          return child;
        }

        final screen = MediaQuery.of(context).size;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        final beginScale = rect.width / screen.width;
        final cardCenter = rect.center;
        final screenCenter = Offset(screen.width / 2, screen.height / 2);

        return AnimatedBuilder(
          animation: curved,
          builder: (context, _) {
            final t = curved.value;
            final scale = lerpDouble(beginScale, 1.0, t)!;
            final dx = lerpDouble(cardCenter.dx - screenCenter.dx, 0.0, t)!;
            final dy = lerpDouble(cardCenter.dy - screenCenter.dy, 0.0, t)!;
            final radius = lerpDouble(24.0, 0.0, t)!;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translateByDouble(dx, dy, 0, 1)
                ..scaleByDouble(scale, scale, 1, 1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
