import 'package:flutter/material.dart';

/// A shared wrapper for onboarding pages that provides consistent layout
/// with a progress indicator, title, subtitle, content area, and bottom action.
class OnboardingPageWrapper extends StatelessWidget {
  const OnboardingPageWrapper({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.bottomAction,
    this.showBackButton = true,
    this.onBack,
    this.backgroundColor,
    this.titleColor,
    this.subtitleColor,
    this.useSafeArea = true,
    this.scrollable = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? bottomAction;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final bool useSafeArea;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBackButton && onBack != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: titleColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: titleColor ??
                    Theme.of(context).colorScheme.onSurface,
                height: 1.2,
              ),
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
                color: subtitleColor ??
                    (titleColor ??
                            Theme.of(context).colorScheme.onSurface)
                        .withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
        if (title != null || subtitle != null) const SizedBox(height: 24),
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
    );

    if (useSafeArea) {
      return SafeArea(child: content);
    }
    return content;
  }
}
