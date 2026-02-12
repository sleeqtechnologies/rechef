import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../subscription/domain/subscription_status.dart';
import '../../../subscription/subscription_provider.dart';
import '../../data/onboarding_repository.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';

const _kBrandRed = Color(0xFFFF4F63);
const _kBrandOrange = Color(0xFFFF7854);
const _kChartOrange = Color(0xFFF0A04B);
const _kChartBlue = Color(0xFF6E8BEA);

class BetterCookPage extends ConsumerStatefulWidget {
  const BetterCookPage({super.key});

  @override
  ConsumerState<BetterCookPage> createState() => _BetterCookPageState();
}

class _BetterCookPageState extends ConsumerState<BetterCookPage>
    with TickerProviderStateMixin {
  bool _finishing = false;

  late final AnimationController _entranceController;
  late final AnimationController _chartDrawController;

  late final Animation<double> _chartFade;
  late final Animation<Offset> _chartSlide;
  late final Animation<double> _descFade;
  late final Animation<Offset> _descSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _chartProgress;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartDrawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _chartFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _chartSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
          ),
        );

    _descFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    );
    _descSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    _buttonFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    _chartProgress = CurvedAnimation(
      parent: _chartDrawController,
      curve: Curves.easeInOutCubic,
    );

    _entranceController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _chartDrawController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _chartDrawController.dispose();
    super.dispose();
  }

  // ── Business logic ──────────────────────────────────────

  Future<void> _finishOnboarding() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final data = ref.read(onboardingProvider).data;
      await repo.saveOnboardingDataLocally(data);
      await repo.markOnboardingComplete();
      ref.invalidate(onboardingCompleteProvider);
    } catch (e) {
      debugPrint('[BetterCookPage] Error finishing onboarding: $e');
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.markOnboardingComplete();
      ref.invalidate(onboardingCompleteProvider);
    }
  }

  Future<void> _tryPro() async {
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final offering = await repo.getOffering(SubscriptionConstants.offeringId);

      if (!mounted || offering == null) {
        await _finishOnboarding();
        return;
      }

      final result = await RevenueCatUI.presentPaywallIfNeeded(
        offering.identifier,
      );

      if (mounted) {
        if (result == PaywallResult.purchased ||
            result == PaywallResult.restored) {
          ref.read(onboardingProvider.notifier).setProSubscription(true);
          await _finishOnboarding();
        }
      }
    } catch (e) {
      debugPrint('[BetterCookPage] Error showing paywall: $e');
      if (mounted) await _finishOnboarding();
    }
  }

  // ── UI ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      title: 'onboarding.better_cook_title'.tr(),
      bottomAction: FadeTransition(
        opacity: _buttonFade,
        child: SlideTransition(position: _buttonSlide, child: _buildButtons()),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Animated chart
          FadeTransition(
            opacity: _chartFade,
            child: SlideTransition(
              position: _chartSlide,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth == double.infinity
                      ? MediaQuery.of(context).size.width -
                            48 // 24 * 2 padding
                      : constraints.maxWidth;
                  const height = 220.0;

                  return SizedBox(
                    width: width,
                    height: height,
                    child: AnimatedBuilder(
                      animation: _chartProgress,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(width, height),
                          painter: _ChartPainter(
                            progress: _chartProgress.value,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Description
          FadeTransition(
            opacity: _descFade,
            child: SlideTransition(
              position: _descSlide,
              child: Text(
                'onboarding.better_cook_body'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kBrandRed, _kBrandOrange],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _kBrandRed.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _finishing ? null : _tryPro,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: _finishing
                  ? const CupertinoActivityIndicator(
                      radius: 12,
                      color: Colors.white,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'onboarding.try_pro'.tr(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: _finishing ? null : _finishOnboarding,
            child: Text(
              'onboarding.continue_without_pro'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Chart Painter ─────────────────────────────────────────

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Chart area with room for badges (top) and labels (bottom)
    final chartArea = Rect.fromLTRB(
      size.width * 0.06,
      40,
      size.width * 0.94,
      size.height - 35,
    );

    _drawGrid(canvas, chartArea);

    // Helper to place a point using normalized coordinates where
    // x = 0..1 across the width and y = 0..1 from bottom -> top.
    Offset pt(double nx, double nyFromBottom) {
      return Offset(
        chartArea.left + chartArea.width * nx,
        chartArea.bottom - chartArea.height * nyFromBottom,
      );
    }

    // Two clearly diagonal, curved lines:
    // - orange: recipes organized (higher at the end)
    // - blue:   meals cooked (slightly lower, but same diagonal trend)
    final recipesPoints = <Offset>[
      pt(0.08, 0.10),
      pt(0.32, 0.18),
      pt(0.60, 0.42),
      pt(0.90, 0.88),
    ];
    final mealsPoints = <Offset>[
      pt(0.08, 0.06),
      pt(0.32, 0.14),
      pt(0.60, 0.32),
      pt(0.90, 0.74),
    ];

    final recipesStart = recipesPoints.first;
    final recipesEnd = recipesPoints.last;
    // We still compute mealsStart/mealsEnd to make the intent of the blue line
    // clear, even if they're not directly used in the painter logic.
    // ignore: unused_local_variable
    final mealsStart = mealsPoints.first;
    // ignore: unused_local_variable
    final mealsEnd = mealsPoints.last;

    if (progress > 0) {
      _drawCurveSeries(
        canvas: canvas,
        chartArea: chartArea,
        points: recipesPoints,
        color: _kChartOrange,
        strokeWidth: 3.0,
      );
      _drawCurveSeries(
        canvas: canvas,
        chartArea: chartArea,
        points: mealsPoints,
        color: _kChartBlue,
        strokeWidth: 3.0,
      );
    }

    // ── Start elements (fade in early, anchored to recipes line) ──
    final startOpacity = (progress * 8).clamp(0.0, 1.0);
    _drawDashedVerticalLine(
      canvas,
      recipesStart.dx,
      recipesStart.dy,
      chartArea.bottom,
      _kChartOrange.withOpacity(startOpacity * 0.35),
    );
    _drawDot(canvas, recipesStart, _kChartOrange, startOpacity);
    _drawBadge(
      canvas,
      'Scattered recipes',
      Offset(recipesStart.dx + 78, recipesStart.dy - 22),
      _kChartOrange,
      startOpacity,
    );
    _drawLabel(
      canvas,
      'Now',
      Offset(recipesStart.dx, chartArea.bottom + 18),
      _kChartOrange,
      startOpacity,
    );

    // ── End elements (fade in late, anchored to recipes line end) ──
    final endOpacity = ((progress - 0.75) * 5.5).clamp(0.0, 1.0);
    _drawDashedVerticalLine(
      canvas,
      recipesEnd.dx,
      recipesEnd.dy,
      chartArea.bottom,
      _kChartBlue.withOpacity(endOpacity * 0.35),
    );
    _drawDot(canvas, recipesEnd, _kChartBlue, endOpacity);
    _drawBadge(
      canvas,
      'More meals cooked',
      Offset(recipesEnd.dx - 12, recipesEnd.dy - 24),
      _kChartBlue,
      endOpacity,
    );
    _drawLabel(
      canvas,
      'Later',
      Offset(recipesEnd.dx, chartArea.bottom + 18),
      _kChartBlue,
      endOpacity,
    );

    // Extra tags so each line has two:
    // - recipes line: Scattered (start) + Organized (end)
    // - meals line:   Cook less (start) + More meals cooked (end)

    // Blue start tag: Cook less (stacked under \"Scattered recipes\")
    final blueStartOpacity = (progress * 6).clamp(0.0, 1.0);
    _drawBadge(
      canvas,
      'Cook less',
      Offset(recipesStart.dx + 4, recipesStart.dy + 32),
      _kChartBlue,
      blueStartOpacity,
    );

    // Orange end tag: Organized recipes (above the end of recipes line)
    final orangeEndOpacity = ((progress - 0.6) * 4.0).clamp(0.0, 1.0);
    _drawBadge(
      canvas,
      'Organized recipes',
      Offset(recipesEnd.dx - 8, recipesEnd.dy - 52),
      _kChartOrange,
      orangeEndOpacity,
    );

    // Blue end tag is already \"More meals cooked\" just above recipesEnd.
  }

  // ── Grid ──

  void _drawGrid(Canvas canvas, Rect area) {
    final paint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = area.top + area.height * (i / 4);
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), paint);
    }
  }

  // ── Curve with gradient stroke ──

  void _drawCurveSeries({
    required Canvas canvas,
    required Rect chartArea,
    required List<Offset> points,
    required Color color,
    required double strokeWidth,
  }) {
    if (points.length < 2) return;

    // Build a clearly diagonal, curved path from first -> last using a
    // parameterized curve (x grows linearly, y eases upward).
    final start = points.first;
    final end = points.last;
    final segments = 40;

    double xForT(double t) => start.dx + (end.dx - start.dx) * t;

    // Easing for J‑curve: mostly flat at the beginning, steeper near the end.
    double yForT(double t) {
      final eased = t * t * t; // cubic ease for visible curve
      return start.dy + (end.dy - start.dy) * eased;
    }

    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 1; i <= segments; i++) {
      final t = i / segments;
      path.lineTo(xForT(t), yForT(t));
    }

    final metrics = path.computeMetrics().first;
    final currentLen = metrics.length * progress;
    final partialPath = metrics.extractPath(0, currentLen);

    canvas.drawPath(
      partialPath,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Moving tip dot for this series
    final tangent = metrics.getTangentForOffset(currentLen);
    if (tangent != null && progress > 0.03) {
      final tipOpacity = progress.clamp(0.0, 1.0);
      final pos = tangent.position;
      canvas.drawCircle(
        pos,
        5,
        Paint()..color = color.withOpacity(0.15 * tipOpacity),
      );
      canvas.drawCircle(
        pos,
        3,
        Paint()..color = Colors.white.withOpacity(tipOpacity),
      );
      canvas.drawCircle(
        pos,
        2.5,
        Paint()..color = color.withOpacity(tipOpacity),
      );
    }
  }

  // ── Helpers ──

  void _drawDot(Canvas canvas, Offset center, Color color, double opacity) {
    if (opacity <= 0) return;
    canvas.drawCircle(
      center,
      5.5,
      Paint()..color = Colors.white.withOpacity(opacity),
    );
    canvas.drawCircle(center, 4.5, Paint()..color = color.withOpacity(opacity));
  }

  void _drawDashedVerticalLine(
    Canvas canvas,
    double x,
    double y1,
    double y2,
    Color color,
  ) {
    if (color.opacity <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashLen = 5.0;
    const gapLen = 4.0;
    var y = y1;
    while (y < y2) {
      final end = (y + dashLen) < y2 ? y + dashLen : y2;
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dashLen + gapLen;
    }
  }

  void _drawBadge(
    Canvas canvas,
    String text,
    Offset center,
    Color bgColor,
    double opacity,
  ) {
    if (opacity <= 0) return;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withOpacity(opacity),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padH = 12.0;
    const padV = 6.0;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: tp.width + padH * 2,
        height: tp.height + padV * 2,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(bgRect, Paint()..color = bgColor.withOpacity(opacity));
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double opacity,
  ) {
    if (opacity <= 0) return;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(opacity),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => progress != old.progress;
}
