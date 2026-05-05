import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/body_measurement.dart';

/// A single row in the measurements list displaying a measurement type.
///
/// Shows an icon (or empty space for body parts), the type name,
/// the last recorded value (or "Add" if none), and a plus button
/// to open the add-measurement sheet.
class MeasurementTypeRow extends StatelessWidget {
  const MeasurementTypeRow({
    super.key,
    required this.type,
    this.lastValue,
    required this.onAdd,
    this.icon,
  });

  /// The measurement type descriptor (name, id, category, unit).
  final MeasurementType type;

  /// The last recorded value formatted for display, or `null` to show "Add".
  final String? lastValue;

  /// Called when the user taps the plus button or the "Add" label.
  final VoidCallback onAdd;

  /// Optional icon to display before the name.
  /// When `null` and [type.icon] is also `null`, an empty space is used.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIcon = icon ?? _iconForType(type.id);

    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // Icon or placeholder
            if (effectiveIcon != null)
              Icon(effectiveIcon, size: 22, color: theme.colorScheme.primary)
            else
              const SizedBox(width: 22),
            const SizedBox(width: 12),
            // Type name
            Expanded(
              child: Text(
                type.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Last value or "Add" label
            if (lastValue != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  lastValue!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'Add',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            // Plus button
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 22,
                icon: const Icon(Icons.add_circle_outline),
                color: theme.colorScheme.primary,
                onPressed: onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns an appropriate Material icon for known core measurement types.
  static IconData? _iconForType(String typeId) {
    switch (typeId) {
      case 'weight':
        return Icons.monitor_weight_outlined;
      case 'height':
        return Icons.straighten;
      case 'body_fat':
        return Icons.percent;
      case 'caloric_intake':
        return Icons.local_fire_department_outlined;
      default:
        return null;
    }
  }
}
