import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/widgets/exercise_detail_view.dart';

// =============================================================================
// ExerciseInfoSheet — Bottom sheet showing exercise details
//
// Matches the iOS exercise info sheet with:
//   - Video / image placeholder
//   - Muscle group, equipment, category pills
//   - Description / instructions text
//   - "View Full Details" link to the tabbed detail view
// =============================================================================

/// Shows a modal bottom sheet with exercise details matching iOS behavior.
class ExerciseInfoSheet extends StatelessWidget {
  final Exercise exercise;

  const ExerciseInfoSheet({super.key, required this.exercise});

  /// Convenience: show the sheet from any context.
  static Future<void> show(BuildContext context, Exercise exercise) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseInfoSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Grabber ──
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // ── Scrollable content ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + close button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Media placeholder ──
                  _MediaCard(
                    imageUrl: exercise.imageUrl,
                    videoUrl: exercise.videoUrl,
                  ),
                  const SizedBox(height: 20),

                  // ── Info pills ──
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (exercise.muscleGroup != null)
                        _InfoPill(
                          icon: Icons.fitness_center_outlined,
                          label: exercise.muscleGroup!,
                          color: colors.accent,
                        ),
                      if (exercise.equipment != null)
                        _InfoPill(
                          icon: Icons.handyman_outlined,
                          label: exercise.equipment!,
                          color: theme.colorScheme.secondary,
                        ),
                      if (exercise.category != null)
                        _InfoPill(
                          icon: Icons.category_outlined,
                          label: exercise.category!,
                          color: theme.colorScheme.tertiary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Instructions ──
                  Text(
                    'Instructions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise.description ??
                        'No instructions provided for this exercise.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── View Full Details link ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ExerciseDetailView.show(context, exercise);
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('View Full Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

/// Media card showing exercise image/video or a fallback icon.
class _MediaCard extends StatelessWidget {
  final String? imageUrl;
  final String? videoUrl;

  const _MediaCard({this.imageUrl, this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMedia = (imageUrl != null && imageUrl!.isNotEmpty) ||
        (videoUrl != null && videoUrl!.isNotEmpty);

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasMedia
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Image if available
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackIcon(theme),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : _fallbackIcon(theme),
                  )
                else
                  _fallbackIcon(theme),
                // Play button overlay for video
                if (videoUrl != null && videoUrl!.isNotEmpty)
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            )
          : _fallbackIcon(theme),
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return Container(
      alignment: Alignment.center,
      child: Icon(
        Icons.fitness_center,
        size: 60,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
      ),
    );
  }
}

/// Coloured info pill for muscle group / equipment / category.
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
