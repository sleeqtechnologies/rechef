import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_spacing.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onSocialMediaTap;
  final VoidCallback? onCameraTap;

  /// When set, tapping the plus button runs this instead of expanding the menu.
  final VoidCallback? onPlusPrimaryAction;
  final Color accentColor;
  final ValueChanged<bool>? onMenuStateChanged;

  /// When set, the action button morphs from a circle into a pill with this label.
  final String? actionLabel;

  /// Override color for the action button (used with actionLabel).
  final Color? actionColor;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onSocialMediaTap,
    this.onCameraTap,
    this.onPlusPrimaryAction,
    this.accentColor = const Color(0xFFFF4F63),
    this.onMenuStateChanged,
    this.actionLabel,
    this.actionColor,
  });

  @override
  State<CustomBottomNavBar> createState() => CustomBottomNavBarState();
}

class CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  static const double _expandedWidth = 220.0;
  static const double _expandedHeight = 140.0;
  static const double _collapsedSize = 56.0;
  static const double _labelButtonWidth = 136.0;
  static const double _pillOuterPadding = 8.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      widget.onMenuStateChanged?.call(_isExpanded);
    });
  }

  void closeMenu() {
    if (_isExpanded) {
      _toggleExpanded();
    }
  }

  void _handleOptionTap(VoidCallback? callback) {
    debugPrint(
      '[CustomBottomNavBar] _handleOptionTap callback=${callback != null}',
    );
    HapticFeedback.selectionClick();
    _toggleExpanded();
    callback?.call();
    debugPrint('[CustomBottomNavBar] _handleOptionTap callback invoked');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unselectedColor = theme.colorScheme.onSurface.withOpacity(0.6);
    final selectedColor = theme.colorScheme.onSurface;

    return SafeArea(
      child: Padding(
        padding: AppSpacing.bottomNavPadding,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Invisible widget to force the stack size to accommodate the expanded menu
            // This ensures hit testing works for the expanded menu items
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                final menuHeight =
                    _collapsedSize +
                    (_expandedHeight - _collapsedSize) *
                        _expandAnimation.value +
                    _pillOuterPadding * _expandAnimation.value;
                // Ensure we don't shrink below the row height (approx 72)
                return SizedBox(
                  height: menuHeight > 72 ? menuHeight : 72,
                  width: double.infinity,
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(_pillOuterPadding),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: _getIndicatorPosition(widget.currentIndex),
                        top: 0,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIconContainer(
                            context: context,
                            index: 0,
                            iconPath: 'assets/icons/recipe.svg',
                            isSelected: widget.currentIndex == 0,
                            selectedColor: selectedColor,
                            unselectedColor: unselectedColor,
                          ),
                          const SizedBox(width: 16),
                          _buildIconContainer(
                            context: context,
                            index: 1,
                            iconPath: 'assets/icons/pantry.svg',
                            isSelected: widget.currentIndex == 1,
                            selectedColor: selectedColor,
                            unselectedColor: unselectedColor,
                          ),
                          const SizedBox(width: 16),
                          _buildIconContainer(
                            context: context,
                            index: 2,
                            iconPath: 'assets/icons/cart.svg',
                            isSelected: widget.currentIndex == 2,
                            selectedColor: selectedColor,
                            unselectedColor: unselectedColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Placeholder to maintain layout space for the action button
                SizedBox(width: _collapsedSize, height: _collapsedSize),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final hasLabel = widget.actionLabel != null;
                  final buttonColor = hasLabel
                      ? (widget.actionColor ?? const Color(0xFF2E7D32))
                      : widget.accentColor;

                  // Animate bottom padding: starts at _pillOuterPadding (centered), ends at 0 (aligned to nav bottom)
                  final bottomPadding =
                      _pillOuterPadding * (1 - _expandAnimation.value);
                  final baseWidth = hasLabel
                      ? _labelButtonWidth
                      : _collapsedSize;
                  final width =
                      baseWidth +
                      (_expandedWidth - baseWidth) * _expandAnimation.value;
                  final height =
                      _collapsedSize +
                      (_expandedHeight - _collapsedSize) *
                          _expandAnimation.value +
                      _pillOuterPadding * _expandAnimation.value;

                  final fabContent = AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    width: width,
                    height: height,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(
                        _collapsedSize / 2 +
                            (35 - _collapsedSize / 2) * _expandAnimation.value,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Plus icon -- always in tree, fades out when label appears or menu expands
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: _expandAnimation.value > 0 || hasLabel,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              opacity: hasLabel
                                  ? 0.0
                                  : (1 - _expandAnimation.value),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/icons/plus.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Label text -- always in tree, fades in when actionLabel is set
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !hasLabel || _expandAnimation.value > 0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              opacity: hasLabel
                                  ? (1 - _expandAnimation.value)
                                  : 0.0,
                              child: Center(
                                child: Text(
                                  widget.actionLabel ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Expanded menu content (scrollable so it doesn't overflow during animation)
                        if (_expandAnimation.value > 0)
                          Positioned.fill(
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildMenuOption(
                                      title: 'Social Media / Blog',
                                      subtitle: 'Enter URL Of Recipe',
                                      iconPath: 'assets/icons/keyboard.svg',
                                      onTap: () => _handleOptionTap(
                                        widget.onSocialMediaTap,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildMenuOption(
                                      title: 'Camera',
                                      subtitle: 'Take Picture Of Recipe',
                                      iconPath: 'assets/icons/camera.svg',
                                      onTap: () =>
                                          _handleOptionTap(widget.onCameraTap),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );

                  return Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: _isExpanded
                        ? fabContent
                        : GestureDetector(
                            onTap: () {
                              if (widget.onPlusPrimaryAction != null) {
                                widget.onPlusPrimaryAction!();
                              } else if (!hasLabel) {
                                _toggleExpanded();
                              } else {
                                widget.onPlusPrimaryAction?.call();
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: fabContent,
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required String title,
    required String subtitle,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  iconPath,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.9),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer({
    required BuildContext context,
    required int index,
    required String iconPath,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    final targetColor = isSelected ? selectedColor : unselectedColor;
    final startColor = isSelected ? unselectedColor : selectedColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          tween:
              ColorTween(begin: startColor, end: targetColor) as Tween<Color?>,
          builder: (context, color, child) {
            return SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                color ?? targetColor,
                BlendMode.srcIn,
              ),
            );
          },
        ),
      ),
    );
  }

  double _getIndicatorPosition(int index) {
    return index * (56 + 16).toDouble();
  }
}
