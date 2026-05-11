import 'package:flutter/material.dart';

/// A blinking cursor widget that indicates active text input focus.
/// Mirrors iOS BlinkingCursor() in WorkoutSetRow.
class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({
    super.key,
    this.color,
    this.width = 2,
    this.height = 16,
  });

  final Color? color;
  final double width;
  final double height;

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Start blinking loop
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cursorColor = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: cursorColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}