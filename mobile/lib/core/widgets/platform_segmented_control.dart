import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatformSegmentedControl extends StatelessWidget {
  const PlatformSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onValueChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onValueChanged;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _AndroidGlassSegmentedControl(
        labels: labels,
        selectedIndex: selectedIndex,
        onValueChanged: onValueChanged,
      );
    }

    return AdaptiveSegmentedControl(
      labels: labels,
      selectedIndex: selectedIndex,
      onValueChanged: onValueChanged,
    );
  }
}

class _AndroidGlassSegmentedControl extends StatelessWidget {
  const _AndroidGlassSegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onValueChanged,
  });

  static const _outerPadding = 4.0;

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onValueChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const trackColor = Color(0xFFF1F2F4);
    const trackBorderColor = Color(0xFFD7D9DE);
    const selectedPillColor = Colors.white;
    const selectedTextColor = Color(0xFF1F1F1F);
    const unselectedTextColor = Color(0xFF6B7280);

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth =
            (constraints.maxWidth - (_outerPadding * 2)) / labels.length;

        return Semantics(
          container: true,
          label: 'Segment selector',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.all(_outerPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: trackColor,
                border: Border.all(color: trackBorderColor),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: segmentWidth * selectedIndex,
                    top: 0,
                    bottom: 0,
                    width: segmentWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: selectedPillColor,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(labels.length, (index) {
                      final selected = index == selectedIndex;
                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: labels[index],
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onValueChanged(index);
                            },
                            child: SizedBox(
                              height: 40,
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 150),
                                  style:
                                      theme.textTheme.labelLarge?.copyWith(
                                        color: selected
                                            ? selectedTextColor
                                            : unselectedTextColor,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ) ??
                                      TextStyle(
                                        color: selected
                                            ? selectedTextColor
                                            : unselectedTextColor,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                  child: Text(
                                    labels[index],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
