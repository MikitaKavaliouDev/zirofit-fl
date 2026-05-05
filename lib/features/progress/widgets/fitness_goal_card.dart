import 'package:flutter/material.dart';

/// Goal progress bar with current/target value display.
///
/// Shows a single fitness goal with progress bar.
/// Mirrors iOS FitnessGoalPlaceholder.
class FitnessGoalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double currentValue;
  final double targetValue;
  final double progress;
  final String unitLabel;

  const FitnessGoalCard({
    super.key,
    required this.title,
    this.subtitle = 'Weekly Tracking',
    required this.currentValue,
    required this.targetValue,
    required this.progress,
    required this.unitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Values
        Row(
          children: [
            Text(
              currentValue.toInt().toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '/ ${targetValue.toInt()} $unitLabel',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const Spacer(),
            Text(
              '${(clampedProgress * 100).toInt()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      width: constraints.maxWidth * clampedProgress,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.cyan],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Progress message
        Text(
          _progressMessage(clampedProgress),
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  String _progressMessage(double progress) {
    if (progress >= 1.0) {
      return 'Goal achieved! Great work.';
    }
    final remaining = targetValue - currentValue;
    return '${remaining.toInt()} more $unitLabel to reach your goal.';
  }
}
