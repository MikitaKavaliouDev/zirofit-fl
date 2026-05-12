import 'package:flutter/material.dart';

import 'package:zirofit_fl/core/theme/theme_colors.dart';

/// A placeholder card shown when no fitness goal has been set.
///
/// Displays a goal icon with "Set your fitness goal" text and an arrow
/// indicator. Tapping navigates to the goal-setting flow.
///
/// Mirrors iOS [FitnessGoalPlaceholder].
///
/// {@tool dartpad}
/// ```dart
/// FitnessGoalPlaceholder(
///   onTap: () => print('Navigate to goal setting'),
/// )
/// ```
/// {@end-tool}
class FitnessGoalPlaceholder extends StatelessWidget {
  /// Called when the placeholder is tapped to navigate to goal setting.
  final VoidCallback? onTap;

  const FitnessGoalPlaceholder({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              // Goal icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flag_outlined,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set your fitness goal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: themeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define what you want to achieve',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing arrow
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
