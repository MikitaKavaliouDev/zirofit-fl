import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zirofit_fl/features/auth/providers/mode_switch_provider.dart';

/// A card in the mode selector showing one [AppMode].
class _ModeCard extends StatelessWidget {
  final AppMode mode;
  final bool isSelected;
  final double glowOpacity;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.isSelected,
    required this.glowOpacity,
    required this.onTap,
  });

  IconData get _icon =>
      mode == AppMode.trainer ? Icons.fitness_center : Icons.person;

  String get _label =>
      mode == AppMode.trainer ? 'Trainer' : 'Personal';

  String get _subtitle =>
      mode == AppMode.trainer
          ? 'Manage clients &\nbusiness'
          : 'Your personal\nfitness journey';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.5 + glowOpacity * 0.5)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected && glowOpacity > 0
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3 * glowOpacity),
                      blurRadius: 12 * glowOpacity,
                      spreadRadius: 2 * glowOpacity,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with selected state
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _icon,
                  size: 28,
                  color: isSelected ? primaryColor : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              // Label
              Text(
                _label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? primaryColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Expandable mode selector overlay showing two large tappable cards
/// (trainer / personal) side-by-side.
///
/// Behaviour matches iOS CustomTabBar:
/// - Two cards displayed with selected state highlighting
/// - Horizontal swipe (40% screen width threshold) toggles mode with haptic
/// - Animated border glow on mode change (0.1s in, 0.8s out)
class ModeSelectorOverlay extends StatefulWidget {
  final bool isExpanded;
  final AppMode currentMode;
  final ValueChanged<AppMode> onModeChanged;
  final VoidCallback onCollapse;

  const ModeSelectorOverlay({
    super.key,
    required this.isExpanded,
    required this.currentMode,
    required this.onModeChanged,
    required this.onCollapse,
  });

  @override
  State<ModeSelectorOverlay> createState() => _ModeSelectorOverlayState();
}

class _ModeSelectorOverlayState extends State<ModeSelectorOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900), // 0.1s in + 0.8s out
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        // Quick rise (0→1 in first 11%), slow fall (1→0 remaining 89%)
        curve: const Interval(0.0, 0.111, curve: Curves.easeOut),
        reverseCurve: const Interval(0.111, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(ModeSelectorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMode != widget.currentMode) {
      // Trigger glow animation
      _glowController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handleModeChange(AppMode mode) {
    if (mode == widget.currentMode) {
      widget.onCollapse();
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onModeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        // Horizontal swipe to toggle mode
        onHorizontalDragEnd: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final threshold = screenWidth * 0.4;

          if (details.primaryVelocity != null &&
              details.primaryVelocity!.abs() > threshold) {
            final newMode = details.primaryVelocity! > 0
                ? AppMode.trainer
                : AppMode.personal;
            _handleModeChange(newMode);
          }
        },
        // Vertical swipe down to collapse
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 40) {
            widget.onCollapse();
          }
        },
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: 8,
              ),
              child: Row(
                children: [
                  _ModeCard(
                    mode: AppMode.trainer,
                    isSelected: widget.currentMode == AppMode.trainer,
                    glowOpacity: widget.currentMode == AppMode.trainer
                        ? _glowAnimation.value
                        : 0.0,
                    onTap: () => _handleModeChange(AppMode.trainer),
                  ),
                  _ModeCard(
                    mode: AppMode.personal,
                    isSelected: widget.currentMode == AppMode.personal,
                    glowOpacity: widget.currentMode == AppMode.personal
                        ? _glowAnimation.value
                        : 0.0,
                    onTap: () => _handleModeChange(AppMode.personal),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
