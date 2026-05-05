import 'package:flutter/material.dart';

/// An animated linear progress bar that changes colour based on progress.
///
/// Colours transition from red (0%) → amber (50%) → green (100%).
class GoalProgressBar extends StatefulWidget {
  final double progress;
  final double height;
  final bool showLabel;

  const GoalProgressBar({
    super.key,
    required this.progress,
    this.height = 12,
    this.showLabel = true,
  });

  @override
  State<GoalProgressBar> createState() => _GoalProgressBarState();
}

class _GoalProgressBarState extends State<GoalProgressBar>
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
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(GoalProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.progress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final display = clamped * _animation.value;
              return LinearProgressIndicator(
                value: display,
                minHeight: widget.height,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progressColor(display),
                ),
              );
            },
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(clamped * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _progressColor(clamped),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  /// Returns a colour along the red → amber → green gradient.
  Color _progressColor(double value) {
    if (value < 0.5) {
      return Color.lerp(
        Colors.red.shade400,
        Colors.amber.shade600,
        value / 0.5,
      )!;
    }
    return Color.lerp(
      Colors.amber.shade600,
      Colors.green.shade600,
      (value - 0.5) / 0.5,
    )!;
  }
}
