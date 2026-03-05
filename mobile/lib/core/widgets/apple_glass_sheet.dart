import 'dart:ui';

import 'package:flutter/material.dart';

class AppleGlassSheet extends StatelessWidget {
  const AppleGlassSheet({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    ),
    this.blurSigma = 22,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xE6FFFFFF),
                const Color(0xD9F5F7FB),
                const Color(0xCCECEFF5),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.62),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
