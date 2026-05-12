import 'package:flutter/material.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';

/// Container for analytics widgets with title, optional trend badge,
/// and a popup menu for actions.
///
/// Mirrors iOS [AnalyticsWidgetContainer].
class AnalyticsWidgetContainer extends StatelessWidget {
  /// The title displayed at the top of the container.
  final String title;

  /// Optional subtitle shown below the title.
  final String? subtitle;

  /// Optional trend text (e.g. "+12%") shown as a badge next to the title.
  final String? trend;

  /// Color of the trend badge text and background tint.
  final Color trendColor;

  /// The content widget rendered inside the container.
  final Widget child;

  /// Called when the container is tapped (e.g. navigate to detail).
  final VoidCallback? onTap;

  /// Called when "Remove Widget" is selected from the menu.
  final VoidCallback? onDelete;

  const AnalyticsWidgetContainer({
    super.key,
    required this.title,
    this.subtitle,
    this.trend,
    this.trendColor = Colors.green,
    required this.child,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title + trend badge + menu
            _buildHeader(context),
            const SizedBox(height: 16),
            // Content slot
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trend != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trend!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: trendColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onDelete != null)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz,
              color: Colors.grey.shade500,
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'delete') {
                onDelete?.call();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove Widget'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
