import 'package:flutter/material.dart';

import 'package:zirofit_fl/core/theme/theme_colors.dart';

/// An empty-state view shown when no workout sessions are available,
/// mirroring iOS [SafeEmptySessionView].
///
/// Displays a large centered icon, a descriptive message, and an optional
/// call-to-action button. When [isSafe] is `true`, a green border or visual
/// indicator reassures the user that the trainer has marked the session as safe.
///
/// {@tool dartpad}
/// ```dart
/// SafeEmptySessionView(
///   isSafe: true,
///   message: 'All clear — no active sessions.',
///   ctaLabel: 'Start New Session',
///   onCtaTap: () => print('Start session'),
/// )
/// ```
/// {@end-tool}
class SafeEmptySessionView extends StatelessWidget {
  /// Whether the trainer has marked the session zone as safe.
  ///
  /// When `true`, a green visual indicator (border + icon tint) is shown.
  final bool isSafe;

  /// The main message displayed below the icon.
  ///
  /// Defaults to 'No active workout sessions'.
  final String message;

  /// Optional label for the call-to-action button.
  ///
  /// When `null`, no CTA button is shown.
  final String? ctaLabel;

  /// Called when the CTA button is tapped.
  final VoidCallback? onCtaTap;

  /// An optional subtitle displayed below [message].
  final String? subtitle;

  const SafeEmptySessionView({
    super.key,
    this.isSafe = false,
    this.message = 'No active workout sessions',
    this.ctaLabel,
    this.onCtaTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final theme = Theme.of(context);
    final safeColor = themeColors.accent; // green accent

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Safe zone indicator + icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSafe
                    ? safeColor.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                border: isSafe
                    ? Border.all(color: safeColor.withValues(alpha: 0.4), width: 2)
                    : null,
              ),
              child: Icon(
                isSafe ? Icons.shield_outlined : Icons.fitness_center_outlined,
                size: 44,
                color: isSafe ? safeColor : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Main message
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: themeColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Optional subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Safe label
            if (isSafe) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: safeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: safeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: safeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Session marked as safe',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: safeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // CTA button
            if (ctaLabel != null && onCtaTap != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onCtaTap,
                  child: Text(ctaLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
