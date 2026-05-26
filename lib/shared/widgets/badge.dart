import 'package:flutter/material.dart';

/// Visual variant for the [Badge] widget.
enum BadgeVariant {
  success,
  warning,
  error,
  info,
  neutral,
}

/// A compact, pill-like badge/pill widget for labels, status indicators,
/// and trend markers.
///
/// Two visual modes:
/// - **Filled** (default): colored background with white text.
/// - **Outlined**: transparent background with colored border and text.
///
/// Usage:
/// ```dart
/// Badge(label: '+12%', variant: BadgeVariant.success)
/// Badge(label: 'Pending', variant: BadgeVariant.warning, outlined: true)
/// Badge(label: 'New', variant: BadgeVariant.info, fontSize: 8)
/// ```
class Badge extends StatelessWidget {
  const Badge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.fontSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.outlined = false,
  });

  /// The text displayed inside the badge.
  final String label;

  /// The color variant of the badge.
  final BadgeVariant variant;

  /// Optional font size for the label text. Defaults to 10.
  final double? fontSize;

  /// Padding around the label. Defaults to horizontal: 6, vertical: 2.
  final EdgeInsets padding;

  /// When `true`, renders with a transparent background, colored border,
  /// and colored text instead of a filled background.
  final bool outlined;

  Color _color(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    switch (variant) {
      case BadgeVariant.success:
        return Colors.green;
      case BadgeVariant.warning:
        return Colors.amber;
      case BadgeVariant.error:
        return Colors.red;
      case BadgeVariant.info:
        return Theme.of(context).colorScheme.primary;
      case BadgeVariant.neutral:
        return brightness == Brightness.dark
            ? Colors.grey.shade400
            : Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final effectiveFontSize = fontSize ?? 10.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        border: outlined ? Border.all(color: color) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: outlined ? color : Colors.white,
          fontSize: effectiveFontSize,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }
}
