import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/services/cooking_timer_notifications.dart';
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

  // Timer state
  int _timerRemaining = 0;
  bool _timerRunning = false;
  bool _timerDone = false;
  Timer? _timer;
  int get _totalSteps => widget.recipe.instructions.length;
  bool get _isLastStep => _currentStep == _totalSteps - 1;
  bool get _hasActiveTimer => _timerRunning || _timerDone;

  static const _accentColor = Color(0xFFFF4F63);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _timer?.cancel();
    _cancelScheduledNotification();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(int seconds, String label) {
    _timer?.cancel();
    _cancelScheduledNotification();
    setState(() {
      _timerRemaining = seconds;
      _timerRunning = true;
      _timerDone = false;
    });
    _scheduleNotification(seconds, label);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timerRemaining--;
        if (_timerRemaining <= 0) {
          _timer?.cancel();
          _timerRunning = false;
          _timerDone = true;
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _timerRemaining = 0;
                _timerDone = false;
              });
            }
          });
        }
      });
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _cancelScheduledNotification();
    setState(() {
      _timerRemaining = 0;
      _timerRunning = false;
      _timerDone = false;
    });
  }

  Future<void> _scheduleNotification(int seconds, String label) async {
    try {
      final plugin = CookingTimerNotifications.instance;
      await plugin.scheduleTimerDone(seconds, label);
    } catch (_) {}
  }

  Future<void> _cancelScheduledNotification() async {
    try {
      final plugin = CookingTimerNotifications.instance;
      await plugin.cancelTimerDone();
    } catch (_) {}
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

  // ── Parse time text ─────────────────────────────────────────────────

  /// Parses a time string (e.g. "5-10 minutes", "30 seconds") and returns
  /// total seconds. For ranges, uses the upper bound.
  static int _parseSeconds(String timeText) {
    final s = timeText.trim().toLowerCase();
    // Match range: "5-10 minutes" or "5 – 10 mins"
    final rangeMatch = RegExp(
      r'(\d+\.?\d*)\s*[-–]\s*(\d+\.?\d*)\s*(hours?|minutes?|mins?|seconds?|secs?|hrs?)',
      caseSensitive: false,
    ).firstMatch(s);
    if (rangeMatch != null) {
      final upper = double.tryParse(rangeMatch.group(2) ?? '0') ?? 0;
      return _applyUnit(upper, rangeMatch.group(3) ?? '');
    }
    // Match single: "30 seconds", "2.5 hours"
    final singleMatch = RegExp(
      r'(\d+\.?\d*)\s*(hours?|minutes?|mins?|seconds?|secs?|hrs?)',
      caseSensitive: false,
    ).firstMatch(s);
    if (singleMatch != null) {
      final value = double.tryParse(singleMatch.group(1) ?? '0') ?? 0;
      return _applyUnit(value, singleMatch.group(2) ?? '');
    }
    return 0;
  }

  static int _applyUnit(double value, String unit) {
    final u = unit.toLowerCase();
    if (u.startsWith('hour') || u.startsWith('hr'))
      return (value * 3600).round();
    if (u.startsWith('min')) return (value * 60).round();
    return value.round(); // seconds
  }

  // ── Highlighted text ────────────────────────────────────────────────

  /// Builds a TextSpan tree with ingredient names and time patterns
  /// highlighted in the accent color.
  TextSpan _buildHighlightedText(String text, BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
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

    // 1. Time patterns (tappable timers)
    final timeRegex = RegExp(
      r'\d+\s*[-–]\s*\d+\s*(?:hours?|minutes?|mins?|seconds?|secs?|hrs?)'
      r'|\d+\.?\d*\s*(?:hours?|minutes?|mins?|seconds?|secs?|hrs?)',
      caseSensitive: false,
    );
    for (final match in timeRegex.allMatches(text)) {
      final label = text.substring(match.start, match.end);
      final seconds = _parseSeconds(label);
      if (seconds > 0) {
        ranges.add(
          _HighlightRange(
            match.start,
            match.end,
            isTimer: true,
            durationSeconds: seconds,
            label: label,
          ),
        );
      } else {
        ranges.add(_HighlightRange(match.start, match.end));
      }
    }

    // 2. Ingredient names – extract full name + core word(s), handle plurals
    final searchTerms = <String>{};
    for (final i in widget.recipe.ingredients) {
      final name = i.name.trim();
      if (name.length <= 2) continue;
      searchTerms.add(name);
      // Add last word for compound names (e.g. "olive oil" -> "oil")
      final words = name.split(RegExp(r'\s+'));
      if (words.length > 1) {
        final lastWord = words.last.toLowerCase();
        if (lastWord.length > 2 && lastWord != name.toLowerCase()) {
          searchTerms.add(words.last);
        }
      }
    }
    // Sort longest first to avoid partial matches
    final sortedTerms = searchTerms.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final name in sortedTerms) {
      final escaped = RegExp.escape(name);
      // Word boundary + optional plural s/es
      final pattern = r'(?<!\w)' + escaped + r'(?:s|es)?(?!\w)';
      final regex = RegExp(pattern, caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        final overlaps = ranges.any(
          (r) => match.start < r.end && match.end > r.start,
        );
        if (!overlaps) {
          ranges.add(_HighlightRange(match.start, match.end, isTimer: false));
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
      final spanText = text.substring(range.start, range.end);
      final isTimer =
          range.isTimer && range.durationSeconds != null && range.label != null;
      final spanStyle = isTimer
          ? highlightStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: _accentColor,
            )
          : highlightStyle;
      final recognizer = isTimer
          ? (TapGestureRecognizer()
              ..onTap = () {
                _startTimer(range.durationSeconds!, range.label!);
              })
          : null;
      spans.add(
        TextSpan(text: spanText, style: spanStyle, recognizer: recognizer),
      );
      lastEnd = range.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return TextSpan(style: baseStyle, children: spans);
  }

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
                margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 4 : 0),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: isFilled ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
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
    final mins = _timerRemaining ~/ 60;
    final secs = _timerRemaining % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                label: Text(
                  'cooking_mode.help'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
          if (_hasActiveTimer) ...[
            const SizedBox(width: 12),
            FakeGlass(
              shape: LiquidRoundedSuperellipse(borderRadius: 999),
              settings: const LiquidGlassSettings(
                blur: 10,
                glassColor: Color(0x18000000),
              ),
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/timer.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          _timerDone ? Colors.green.shade700 : Colors.black87,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timerDone ? 'cooking_mode.timer_done'.tr() : timeStr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _timerDone
                              ? Colors.green.shade800
                              : _accentColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (!_timerDone) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _cancelTimer,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: SvgPicture.asset(
                              'assets/icons/x.svg',
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _isLastStep
                  ? _markComplete
                  : () => _goToStep(_currentStep + 1),
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                minimumSize: const Size(0, 44),
                maximumSize: const Size(double.infinity, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                _isLastStep ? 'cooking_mode.complete_cooking'.tr() : 'common.next'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightRange {
  const _HighlightRange(
    this.start,
    this.end, {
    this.isTimer = false,
    this.durationSeconds,
    this.label,
  });
  final int start;
  final int end;
  final bool isTimer;
  final int? durationSeconds;
  final String? label;
}
