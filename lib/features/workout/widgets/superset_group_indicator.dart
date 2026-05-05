import 'package:flutter/material.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';

// ---------------------------------------------------------------------------
// Colour palette for superset groups
// ---------------------------------------------------------------------------

/// Pre-defined colours for superset group badges A–Z.
const List<Color> _kGroupColors = [
  Color(0xFFE53935), // Red
  Color(0xFF1565C0), // Blue
  Color(0xFFFDD835), // Yellow
  Color(0xFF43A047), // Green
  Color(0xFF8E24AA), // Purple
  Color(0xFFFF6F00), // Orange
  Color(0xFF00ACC1), // Cyan
  Color(0xFFD81B60), // Pink
];

Color _colorForKey(String key) {
  if (key.isEmpty) return Colors.grey;
  final index = key.codeUnitAt(0) % _kGroupColors.length;
  return _kGroupColors[index];
}

// ---------------------------------------------------------------------------
// SupersetGroupIndicator
// ---------------------------------------------------------------------------

/// A compact circular badge that displays a superset group letter alongside
/// completion progress (e.g. "2/3 sets complete").
///
/// Use inside exercise rows to visually group supersetted exercises.
class SupersetGroupIndicator extends StatelessWidget {
  const SupersetGroupIndicator({
    super.key,
    required this.group,
    this.size = 40,
  });

  /// The superset group data to display.
  final SupersetGroup group;

  /// Diameter of the circular badge (default 40).
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForKey(group.key);
    final isComplete = group.totalSets > 0 &&
        group.completedSets >= group.totalSets;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular badge
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isComplete
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: isComplete ? color : color.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            group.key,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isComplete ? color : color,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Completion label
        if (group.totalSets > 0)
          Flexible(
            child: Text(
              '${group.completedSets}/${group.totalSets} set${group.totalSets == 1 ? '' : 's'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isComplete
                    ? color
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isComplete ? FontWeight.w600 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SupersetGroupDot (compact variant – just the dot)
// ---------------------------------------------------------------------------

/// An even more compact variant that shows only the coloured dot with group
/// letter, without the completion text.  Useful when space is tight.
class SupersetGroupDot extends StatelessWidget {
  const SupersetGroupDot({
    super.key,
    required this.groupKey,
    this.size = 24,
  });

  final String groupKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForKey(groupKey);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        groupKey,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
