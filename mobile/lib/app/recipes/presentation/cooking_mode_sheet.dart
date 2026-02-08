import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../domain/recipe.dart';
import 'cooking_help_sheet.dart';

/// Full-screen bottom sheet for step-by-step cooking mode.
class CookingModeSheet extends StatefulWidget {
  const CookingModeSheet({super.key, required this.recipe});

  final Recipe recipe;

  /// Show as a full-screen modal bottom sheet (non-dismissible by drag).
  static Future<void> show(BuildContext context, Recipe recipe) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      enableDrag: false,
      builder: (_) => CookingModeSheet(recipe: recipe),
    );
  }

  @override
  State<CookingModeSheet> createState() => _CookingModeSheetState();
}

class _CookingModeSheetState extends State<CookingModeSheet> {
  late final PageController _pageController;
  int _currentStep = 0;

  int get _totalSteps => widget.recipe.instructions.length;
  bool get _isLastStep => _currentStep == _totalSteps - 1;

  static const _accentColor = Color(0xFFFF4F63);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _markComplete() {
    Navigator.of(context).pop();
  }

  void _openHelp() {
    CookingHelpSheet.show(
      context,
      recipeId: widget.recipe.id,
      currentStep: _currentStep,
    );
  }

  // ── Highlighted text ────────────────────────────────────────────────

  /// Builds a TextSpan tree with ingredient names and time patterns
  /// highlighted in the accent color.
  TextSpan _buildHighlightedText(String text, BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              height: 1.7,
              color: Colors.black87,
            ) ??
        const TextStyle(fontSize: 20, height: 1.7);

    final highlightStyle = baseStyle.copyWith(
      color: _accentColor,
      fontWeight: FontWeight.w600,
    );

    // Collect all highlight ranges
    final ranges = <_HighlightRange>[];

    // 1. Time patterns
    final timeRegex = RegExp(
      r'\d+\s*[-–]\s*\d+\s*(?:hours?|minutes?|mins?|seconds?|secs?|hrs?)'
      r'|\d+\.?\d*\s*(?:hours?|minutes?|mins?|seconds?|secs?|hrs?)',
      caseSensitive: false,
    );
    for (final match in timeRegex.allMatches(text)) {
      ranges.add(_HighlightRange(match.start, match.end));
    }

    // 2. Ingredient names (sorted longest first to avoid partial matches)
    final ingredientNames = widget.recipe.ingredients
        .map((i) => i.name.trim())
        .where((n) => n.length > 2)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final name in ingredientNames) {
      final escaped = RegExp.escape(name);
      final regex = RegExp(escaped, caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        // Only add if not already covered by an existing range
        final overlaps = ranges.any(
          (r) => match.start < r.end && match.end > r.start,
        );
        if (!overlaps) {
          ranges.add(_HighlightRange(match.start, match.end));
        }
      }
    }

    if (ranges.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    // Sort by start position
    ranges.sort((a, b) => a.start.compareTo(b.start));

    // Build spans
    final spans = <TextSpan>[];
    var lastEnd = 0;
    for (final range in ranges) {
      if (range.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, range.start)));
      }
      spans.add(TextSpan(
        text: text.substring(range.start, range.end),
        style: highlightStyle,
      ));
      lastEnd = range.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildProgressBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalSteps,
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                itemBuilder: (context, index) {
                  return _buildStepPage(index);
                },
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              widget.recipe.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          FakeGlass(
            shape: LiquidRoundedSuperellipse(borderRadius: 999),
            settings: const LiquidGlassSettings(
              blur: 10,
              glassColor: Color(0x18000000),
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/x.svg',
                  width: 18,
                  height: 18,
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isFilled = index <= _currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: () => _goToStep(index),
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index < _totalSteps - 1 ? 4 : 0,
                ),
                decoration: BoxDecoration(
                  color: isFilled ? _accentColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepPage(int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          // Instruction text with highlights
          RichText(
            text: _buildHighlightedText(
              widget.recipe.instructions[index],
              context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          FakeGlass(
            shape: LiquidRoundedSuperellipse(borderRadius: 999),
            settings: const LiquidGlassSettings(
              blur: 10,
              glassColor: Color(0x18000000),
            ),
            child: SizedBox(
              height: 44,
              child: TextButton.icon(
                onPressed: _openHelp,
                icon: SvgPicture.asset(
                  'assets/icons/ai.svg',
                  width: 20,
                  height: 20,
                ),
                label: const Text(
                  'Help',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _isLastStep
                ? _markComplete
                : () => _goToStep(_currentStep + 1),
            style: FilledButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              _isLastStep ? 'Complete cooking' : 'Next',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightRange {
  const _HighlightRange(this.start, this.end);
  final int start;
  final int end;
}
