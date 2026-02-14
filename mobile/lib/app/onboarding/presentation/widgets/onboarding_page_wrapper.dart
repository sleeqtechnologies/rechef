import 'package:flutter/material.dart';

/// A shared wrapper for onboarding pages that provides consistent layout
/// with title, subtitle, content area, and bottom action.
///
/// The back button and progress bar are handled by [OnboardingScreen],
/// so this wrapper only manages the content area below them.
class OnboardingPageWrapper extends StatelessWidget {
  const OnboardingPageWrapper({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.bottomAction,
    this.backgroundColor,
    this.scrollable = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? bottomAction;
  final Color? backgroundColor;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 68),

            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (title != null || subtitle != null) const SizedBox(height: 16),

            if (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: child,
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: child,
                ),
              ),

            if (bottomAction != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: bottomAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
