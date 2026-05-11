
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for managing workout-related toast notifications.
///
/// Provides overlay toasts for new records and rest completion,
/// matching iOS toast behavior with animations and haptic feedback.
class WorkoutToastService {
  static OverlayEntry? _currentRecordToast;
  static OverlayEntry? _currentRestToast;

  /// For testing purposes - exposes current record toast
  static OverlayEntry? get currentRecordToast => _currentRecordToast;

  /// For testing purposes - exposes current rest toast
  static OverlayEntry? get currentRestToast => _currentRestToast;

  /// Shows a new record toast with orange-to-red gradient.
  ///
  /// Displays a trophy icon and "New Record! {exerciseName}" text.
  /// Auto-dismisses after 5 seconds.
  static void showNewRecordToast(BuildContext context, String exerciseName) {
    // Remove existing toast if any
    _currentRecordToast?.remove();
    _currentRecordToast = null;

    // Don't show if widget tree is unmounting
    if (!context.mounted) return;

    // Trigger haptic feedback
    HapticFeedback.lightImpact();

    final overlay = Overlay.of(context);
    _currentRecordToast = OverlayEntry(
      builder: (_) => _NewRecordToast(
        exerciseName: exerciseName,
        onDismiss: () {
          _currentRecordToast?.remove();
          _currentRecordToast = null;
        },
      ),
    );

    overlay.insert(_currentRecordToast!);

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _currentRecordToast?.remove();
      _currentRecordToast = null;
    });
  }

  /// Shows a rest finished toast with green background.
  ///
  /// Displays a checkmark icon and "Rest Complete!" text.
  /// Auto-dismisses after 3 seconds.
  static void showRestFinishedToast(BuildContext context) {
    // Remove existing toast if any
    _currentRestToast?.remove();
    _currentRestToast = null;

    // Don't show if widget tree is unmounting
    if (!context.mounted) return;

    // Trigger haptic feedback
    HapticFeedback.mediumImpact();

    final overlay = Overlay.of(context);
    _currentRestToast = OverlayEntry(
      builder: (_) => _RestFinishedToast(
        onDismiss: () {
          _currentRestToast?.remove();
          _currentRestToast = null;
        },
      ),
    );

    overlay.insert(_currentRestToast!);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _currentRestToast?.remove();
      _currentRestToast = null;
    });
  }
}

/// Widget for new record toast with orange-to-red gradient animation.
class _NewRecordToast extends StatelessWidget {
  const _NewRecordToast({
    required this.exerciseName,
    required this.onDismiss,
  });

  final String exerciseName;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return _ToastAnimator(
      onDismiss: onDismiss,
      child: Container(
        margin: const EdgeInsets.only(top: 48, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFDC2626)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'New Record! $exerciseName',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for rest finished toast with green background animation.
class _RestFinishedToast extends StatelessWidget {
  const _RestFinishedToast({
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return _ToastAnimator(
      onDismiss: onDismiss,
      child: Container(
        margin: const EdgeInsets.only(top: 48, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF22C55E),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Rest Complete!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated toast widget with slide, fade, and scale transitions.
class _ToastAnimator extends StatefulWidget {
  const _ToastAnimator({
    required this.child,
    required this.onDismiss,
  });

  final Widget child;
  final VoidCallback onDismiss;

  @override
  State<_ToastAnimator> createState() => _ToastAnimatorState();
}

class _ToastAnimatorState extends State<_ToastAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, _slideAnimation.value),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}