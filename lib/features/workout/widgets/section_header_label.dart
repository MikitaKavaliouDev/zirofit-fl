import 'package:flutter/material.dart';

// =============================================================================
// SectionHeaderLabel
// =============================================================================

/// A section header label used between exercise groups to display workout
/// section names (e.g., "PUSH", "PULL", "LEGS").
///
/// Matches iOS [WorkoutSessionContent] section header design:
/// - Uppercase bold text with a trailing divider line
/// - Font: 14px, black weight (w900), gray color
/// - Padding: horizontal 16, top 24, bottom 12
///
/// ```swift
/// HStack {
///     Text(section.uppercased())
///         .font(.system(size: 14, weight: .black, design: .rounded))
///         .foregroundColor(.gray)
///     Spacer()
///     Rectangle()
///         .fill(Color.gray.opacity(0.2))
///         .frame(height: 1)
/// }
/// .padding(.horizontal, 16)
/// .padding(.top, 24)
/// .padding(.bottom, 12)
/// ```
class SectionHeaderLabel extends StatelessWidget {
  /// The section title to display (e.g., "Push", "Pull", "Legs").
  /// Will be automatically uppercased.
  final String title;

  /// Optional color override for the label text.
  /// Defaults to [Colors.grey].
  final Color? color;

  const SectionHeaderLabel({
    super.key,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section label text
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: labelColor,
            ),
          ),
          const SizedBox(width: 12),
          // Divider line filling remaining horizontal space
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
