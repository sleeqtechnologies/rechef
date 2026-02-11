import 'package:flutter/material.dart';

/// An image displayed as a smaller centered mockup.
/// Used for feature showcase pages in onboarding.
class FadedImage extends StatelessWidget {
  const FadedImage({
    super.key,
    required this.assetPath,
    this.widthFraction = 0.6,
  });

  final String assetPath;

  /// Fraction of available width the image should occupy (0.0 - 1.0).
  final double widthFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * widthFraction;

        return Center(
          child: SizedBox(
            width: imageWidth,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  width: imageWidth,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
