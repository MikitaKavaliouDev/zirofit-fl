import 'package:flutter/material.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';

/// A horizontal rest timer progress bar matching iOS [RestTimerProgressBar].
///
/// Displays a capsule-shaped progress bar with a timer icon and formatted time
/// text. The bar color transitions from accent green (normal) → yellow (warning,
/// <10s remaining) → red (over/expired).
///
/// {@tool dartpad}
/// ```dart
/// RestTimerProgressBar(
///   remainingSeconds: 45,
///   totalSeconds: 90,
/// )
/// ```
/// {@end-tool}
class RestTimerProgressBar extends StatelessWidget {
  /// The number of seconds remaining in the rest period.
  final int remainingSeconds;

  /// The total duration of the rest period in seconds.
  final int totalSeconds;

  /// Height of the progress bar. Defaults to 40.
  final double height;

  /// Width of the progress bar. Defaults to 140.
  final double width;

  const RestTimerProgressBar({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.height = 40,
    this.width = 140,
  });

  /// Returns the progress color based on remaining time:
  /// - [accent] green for normal (>10s)
  /// - orange/yellow for warning (1–10s)
  /// - red for expired (≤0s)
  Color _progressColor(BuildContext context) {
    if (remainingSeconds <= 0) return Colors.red;
    if (remainingSeconds <= 10) return Colors.orange;
    return context.themeColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        totalSeconds > 0
            ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0)
            : 0.0;
    final color = _progressColor(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: color.withAlpha(38), // ~15% opacity
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Progress fill
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),

          // Overlay text: timer icon + formatted time
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: context.themeColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formattedTime,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: context.themeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formats the remaining time as "Rest: M:SS" or "Rest: Xs".
  String get _formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    if (minutes > 0) {
      return 'Rest: $minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return 'Rest: ${seconds}s';
  }
}
