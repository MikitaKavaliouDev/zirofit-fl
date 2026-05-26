import 'package:flutter/material.dart';

/// A reusable metric card widget for displaying KPIs, stats, and analytics.
///
/// Provides a consistent visual pattern across the app for showing
/// labeled values with optional icons, units, and trend indicators.
///
/// Example usage:
/// ```dart
/// MetricCard(
///   title: 'Total Volume',
///   value: '12.5k',
///   unit: 'kg',
///   icon: Icons.monitor_weight_outlined,
///   iconColor: Colors.blue,
///   trend: '+12%',
///   isPositiveTrend: true,
/// )
/// ```
class MetricCard extends StatelessWidget {
  /// The label displayed above the value.
  final String title;

  /// The formatted value (e.g., "12.5k", "85", "4.2").
  final String value;

  /// Optional unit displayed after the value (e.g., "kg", "%", "sessions").
  final String? unit;

  /// Optional leading icon.
  final IconData? icon;

  /// Color for the leading icon. Defaults to [Colors.blue].
  final Color? iconColor;

  /// Optional trend text (e.g., "+12%", "-5%").
  final String? trend;

  /// Whether the trend is positive. Defaults to true.
  /// Determines trend badge color (green if true, red if false).
  final bool isPositiveTrend;

  /// Optional fixed height for the card. If null, height is auto.
  final double? height;

  /// Optional tap handler. When provided, the card is wrapped in [InkWell].
  final VoidCallback? onTap;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Padding around the card content. Defaults to 12 on all sides.
  final EdgeInsets padding;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.icon,
    this.iconColor,
    this.trend,
    this.isPositiveTrend = true,
    this.height,
    this.onTap,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final trendColor = isPositiveTrend ? Colors.green : Colors.red;

    final card = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ??
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: effectiveIconColor),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositiveTrend
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 12,
                    color: trendColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      );
    }

    return card;
  }
}
