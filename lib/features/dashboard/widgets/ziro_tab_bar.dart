import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zirofit_fl/features/auth/providers/mode_switch_provider.dart';
import 'package:zirofit_fl/features/dashboard/widgets/mode_selector_overlay.dart';

// ---------------------------------------------------------------------------
// Tab model
// ---------------------------------------------------------------------------

/// A single tab definition for [ZiroTabBar].
class ZiroTab {
  /// Display label.
  final String label;

  /// Unselected icon (typically outlined variant).
  final IconData icon;

  /// Selected icon (typically filled/solid variant).
  final IconData selectedIcon;

  /// GoRoute path this tab navigates to.
  final String route;

  const ZiroTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

// ---------------------------------------------------------------------------
// ZiroTabBar
// ---------------------------------------------------------------------------

/// iOS‑style custom tab bar with:
///
/// * Ultra‑thin material/blur background, 40 px top‑corner radius.
/// * Animated capsule background for the selected tab.
/// * Expandable mode‑selector overlay with two large tappable cards.
/// * Horizontal swipe gesture (40 % screen width) to toggle mode with haptic.
/// * Vertical swipe to expand / collapse the selector (40 px threshold).
/// * Animated border glow on mode change.
class ZiroTabBar extends StatefulWidget {
  /// Index of the currently selected tab (0‑based).
  final int selectedIndex;

  /// Called when a tab is tapped.
  final ValueChanged<int> onTap;

  /// Tab definitions for the current shell + mode combination.
  final List<ZiroTab> tabs;

  // ---------------------------------------------------------------------------
  // Mode selector
  // ---------------------------------------------------------------------------

  /// Whether the mode‑selector overlay is expanded.
  final bool isModeExpanded;

  /// Toggle the mode‑selector expanded state.
  final VoidCallback onToggleModeExpanded;

  /// Current UI display mode.
  final AppMode currentMode;

  /// Called when the user explicitly changes the display mode.
  final ValueChanged<AppMode> onModeChanged;

  /// Called when the user double‑taps the already‑selected tab
  /// (pop‑to‑root / navigation reset).
  final VoidCallback? onDoubleTapTab;

  // ---------------------------------------------------------------------------
  // Colours (defaults to theme if omitted)
  // ---------------------------------------------------------------------------

  /// Colour for the selected indicator capsule and selected icon/label.
  final Color? selectedColor;

  /// Colour for unselected icons/labels.
  final Color? unselectedColor;

  /// Background colour of the tab bar.
  final Color? backgroundColor;

  const ZiroTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.tabs,
    required this.isModeExpanded,
    required this.onToggleModeExpanded,
    required this.currentMode,
    required this.onModeChanged,
    this.onDoubleTapTab,
    this.selectedColor,
    this.unselectedColor,
    this.backgroundColor,
  });

  @override
  State<ZiroTabBar> createState() => _ZiroTabBarState();
}

class _ZiroTabBarState extends State<ZiroTabBar>
    with TickerProviderStateMixin {
  // -------------------------------------------------------------------------
  // Capsule animation
  // -------------------------------------------------------------------------

  /// Drives the capsule indicator position.
  late final AnimationController _capsuleController;
  late final Animation<double> _capsuleAnimation;

  int _previousIndex = 0;

  // -------------------------------------------------------------------------
  // Horizontal swipe, glow, and double‑tap state
  // -------------------------------------------------------------------------

  /// Cumulative horizontal drag offset for mode‑toggle gesture.
  double _horizontalDragOffset = 0;

  /// Drives the animated border glow on mode change.
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  /// Last tapped tab index (for double‑tap detection).
  int? _lastTapIndex;

  /// Timestamp of the last tab tap.
  DateTime? _lastTapTime;

  // -------------------------------------------------------------------------
  // Constants
  // -------------------------------------------------------------------------

  static const double _tabBarHeight = 64.0;
  static const double _expandedOverlayHeight = 160.0;
  static const double _modeButtonSize = 36.0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _capsuleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _capsuleAnimation = CurvedAnimation(
      parent: _capsuleController,
      curve: Curves.easeInOut,
    );
    // Jump to the starting position immediately.
    _capsuleController.value = 1.0;

    // Glow animation: 0.1s fade‑in, 0.7s hold, 0.8s fade‑out = 1.6s total
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1, // 0.1 / 1.6
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 7, // 0.7 / 1.6
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8, // 0.8 / 1.6
      ),
    ]).animate(_glowController);
  }

  @override
  void didUpdateWidget(ZiroTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _capsuleController.forward(from: 0.0);
    }
    // Trigger animated border glow when mode changes.
    if (oldWidget.currentMode != widget.currentMode) {
      _glowController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _capsuleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Gesture callbacks
  // -------------------------------------------------------------------------

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! < -40) {
      // Swiped up → expand
      if (!widget.isModeExpanded) {
        HapticFeedback.lightImpact();
        widget.onToggleModeExpanded();
      }
    } else if (details.primaryVelocity! > 40) {
      // Swiped down → collapse
      if (widget.isModeExpanded) {
        widget.onToggleModeExpanded();
      }
    }
  }

  // -------------------------------------------------------------------------
  // Horizontal swipe → toggle mode
  // -------------------------------------------------------------------------

  void _onHorizontalDragStart(DragStartDetails details) {
    _horizontalDragOffset = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragOffset += details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.4;

    if (_horizontalDragOffset.abs() > threshold) {
      HapticFeedback.lightImpact();
      final newMode = widget.currentMode == AppMode.trainer
          ? AppMode.personal
          : AppMode.trainer;
      widget.onModeChanged(newMode);
    }

    _horizontalDragOffset = 0;
  }

  // -------------------------------------------------------------------------
  // Tab tap with double‑tap detection
  // -------------------------------------------------------------------------

  void _onTabTap(int index) {
    final now = DateTime.now();

    // Double‑tap: same tab within 500 ms
    if (_lastTapIndex == index &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      widget.onDoubleTapTab?.call();
    }

    _lastTapIndex = index;
    _lastTapTime = now;

    widget.onTap(index);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = widget.selectedColor ?? theme.colorScheme.primary;
    final surfaceColor =
        widget.backgroundColor ?? (isDark ? const Color(0xFF1E1E2C) : Colors.white);
    final unselected =
        widget.unselectedColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final totalHeight = _tabBarHeight +
        (widget.isModeExpanded ? _expandedOverlayHeight : 0.0);

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // ---- Main tab bar body ----
        Container(
          height: totalHeight + bottomInset,
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragEnd: _onVerticalDragEnd,
                onHorizontalDragStart: _onHorizontalDragStart,
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---- Mode selector overlay ----
                    ModeSelectorOverlay(
                      isExpanded: widget.isModeExpanded,
                      currentMode: widget.currentMode,
                      onModeChanged: widget.onModeChanged,
                      onCollapse: widget.onToggleModeExpanded,
                    ),

                    // ---- Tab row ----
                    SizedBox(
                      height: _tabBarHeight,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Animated capsule indicator
                          AnimatedBuilder(
                            animation: _capsuleAnimation,
                            builder: (context, _) {
                              return Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor:
                                          1.0 / (widget.tabs.length + 1),
                                      heightFactor: 1.0,
                                      child: _AnimatedCapsule(
                                        animation: _capsuleAnimation,
                                        previousIndex: _previousIndex,
                                        currentIndex: widget.selectedIndex,
                                        tabCount: widget.tabs.length + 1,
                                        primaryColor: primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Tab items + mode button
                          Row(
                            children: [
                              // Tab items
                              ...List.generate(widget.tabs.length, (i) {
                                final tab = widget.tabs[i];
                                final isSelected = i == widget.selectedIndex;
                                return Expanded(
                                  child: _TabItem(
                                    tab: tab,
                                    isSelected: isSelected,
                                    selectedColor: primaryColor,
                                    unselectedColor: unselected,
                                    onTap: () => _onTabTap(i),
                                  ),
                                );
                              }),

                              // Mode switch button
                              _ModeButton(
                                currentMode: widget.currentMode,
                                isExpanded: widget.isModeExpanded,
                                selectedColor: primaryColor,
                                unselectedColor: unselected,
                                onTap: widget.onToggleModeExpanded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ---- Animated border glow overlay on mode change ----
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) {
                return Opacity(
                  opacity: _glowAnimation.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(40)),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF10B981), // emerald
                          Color(0xFF3B82F6), // blue
                          Color(0xFF8B5CF6), // purple
                          Color(0xFFEC4899), // pink
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(1.5),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(38.5)),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab item
// ---------------------------------------------------------------------------

class _TabItem extends StatelessWidget {
  final ZiroTab tab;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? tab.selectedIcon : tab.icon,
              size: 22,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode button (icon on the tab bar that opens the mode selector)
// ---------------------------------------------------------------------------

class _ModeButton extends StatelessWidget {
  final AppMode currentMode;
  final bool isExpanded;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _ModeButton({
    required this.currentMode,
    required this.isExpanded,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpanded ? selectedColor : unselectedColor;
    final icon = currentMode == AppMode.trainer
        ? Icons.fitness_center
        : Icons.person;

    return SizedBox(
      width: 48,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey('mode_$currentMode'),
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
                child: Text(
                  currentMode == AppMode.trainer ? 'Trainer' : 'Personal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated capsule indicator
// ---------------------------------------------------------------------------

class _AnimatedCapsule extends StatelessWidget {
  final Animation<double> animation;
  final int previousIndex;
  final int currentIndex;
  final int tabCount;
  final Color primaryColor;

  const _AnimatedCapsule({
    required this.animation,
    required this.previousIndex,
    required this.currentIndex,
    required this.tabCount,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final lerpedIndex = _lerpIndex();
        final left = lerpedIndex / tabCount;
        final right = (lerpedIndex + 1) / tabCount;

        return FractionallySizedBox(
          widthFactor: right - left,
          child: Align(
            alignment: Alignment(2.0 * left + (right - left) - 1.0, 0),
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  double _lerpIndex() {
    final t = animation.value;
    return previousIndex + (currentIndex - previousIndex) * t;
  }
}
