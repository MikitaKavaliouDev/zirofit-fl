import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/data/models/exercise.dart';

/// A detail view for an [Exercise], typically shown in a modal bottom sheet.
///
/// Displays a header image (16:9), exercise name, tags, description,
/// optional video demo link, and additional details like rest time and
/// unilateral flag.
class ExerciseDetailView extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailView({
    super.key,
    required this.exercise,
  });

  /// Shows this view as a modal bottom sheet.
  static Future<void> show(BuildContext context, Exercise exercise) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExerciseDetailView(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailUrl = exercise.imageUrl ?? exercise.videoUrl;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Grab handle ──
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Header image (16:9) ──
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _imagePlaceholder(theme),
                      errorWidget: (_, _, _) => _imagePlaceholder(theme),
                    )
                  : _imagePlaceholder(theme),
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise name
                Text(
                  exercise.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Tags row
                if (exercise.muscleGroup != null ||
                    exercise.category != null ||
                    exercise.equipment != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (exercise.muscleGroup != null)
                        _buildTag(theme, exercise.muscleGroup!),
                      if (exercise.category != null)
                        _buildTag(theme, exercise.category!),
                      if (exercise.equipment != null)
                        _buildTag(theme, exercise.equipment!),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Description section ──
                Text(
                  'Description',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.description ?? 'No description available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Video demo ──
                if (exercise.videoUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextButton.icon(
                      onPressed: () =>
                          launchUrl(Uri.parse(exercise.videoUrl!)),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch Demo'),
                    ),
                  ),

                // ── Details section ──
                Text(
                  'Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  theme,
                  Icons.timer_outlined,
                  'Recommended Rest',
                  exercise.recommendedRestSeconds != null
                      ? '${exercise.recommendedRestSeconds} seconds'
                      : 'Not specified',
                ),
                const SizedBox(height: 6),
                _buildDetailRow(
                  theme,
                  Icons.alt_route,
                  'Unilateral',
                  exercise.isUnilateral ? 'Yes' : 'No',
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a styled tag chip for muscle group / category / equipment.
  Widget _buildTag(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Builds a detail row with icon, label, and value.
  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Placeholder shown when image is loading, errored, or absent.
  Widget _imagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.fitness_center,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
