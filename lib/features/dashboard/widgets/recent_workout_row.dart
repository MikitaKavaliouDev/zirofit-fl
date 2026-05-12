import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';

// ---------------------------------------------------------------------------
// Exercise highlight data
// ---------------------------------------------------------------------------

/// Lightweight summary of a single exercise used in the highlights section.
class _ExerciseHighlight {
  final String name;
  final bool hasMissingData;
  final String summary;

  const _ExerciseHighlight({
    required this.name,
    required this.hasMissingData,
    required this.summary,
  });
}

// ---------------------------------------------------------------------------
// RecentWorkoutRow
// ---------------------------------------------------------------------------

/// A list row for recent workout history on the client dashboard/home screen.
///
/// Displays:
/// - Date column with abbreviated month + day
/// - Session info (title, volume, duration, missing-data warning)
/// - Chevron for navigation
/// - Exercise highlights (up to 4, with "+N more" overflow)
///
/// Styling follows the app's design system: rounded corners match [CardTheme],
/// spacing follows the 8‑px grid, and colours are derived from [Theme].
class RecentWorkoutRow extends StatelessWidget {
  final WorkoutSession session;
  final List<ClientExerciseLog> exerciseLogs;
  final VoidCallback? onTap;

  const RecentWorkoutRow({
    super.key,
    required this.session,
    this.exerciseLogs = const [],
    this.onTap,
  });

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Total volume (kg) across all completed sets.
  double get _totalVolume {
    double total = 0;
    for (final log in exerciseLogs) {
      if (log.isCompleted == true) {
        total += (log.weight ?? 0) * (log.reps ?? 0);
      }
    }
    return total;
  }

  /// Whether any exercise log has missing or incomplete data.
  bool get _hasMissingData {
    return exerciseLogs.any((log) => log.isCompleted != true);
  }

  /// Session duration from [session.endTime] - [session.startTime].
  Duration get _duration {
    if (session.endTime == null) return Duration.zero;
    return session.endTime!.difference(session.startTime);
  }

  /// Human-readable duration string (e.g. "1h 15m" or "45m").
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Group logs by exercise name and build highlight summaries.
  List<_ExerciseHighlight> get _exerciseHighlights {
    // Group logs by exercise name
    final grouped = <String, List<ClientExerciseLog>>{};
    for (final log in exerciseLogs) {
      final name = log.exerciseName ?? 'Unknown';
      grouped.putIfAbsent(name, () => []).add(log);
    }

    return grouped.entries.map((entry) {
      final logs = entry.value;
      final completedLogs = logs.where((l) => l.isCompleted == true).toList();
      final hasMissing = logs.any((l) => l.isCompleted != true);
      final completedVolume = completedLogs.fold<double>(
        0,
        (sum, l) => sum + (l.weight ?? 0) * (l.reps ?? 0),
      );

      String summary;
      if (completedVolume > 0) {
        // Find the top set (max weight) among completed logs
        final topSet = completedLogs.fold<ClientExerciseLog?>(null, (best, l) {
          final w = l.weight ?? 0;
          if (best == null || w > (best.weight ?? 0)) return l;
          return best;
        });
        if (topSet != null && (topSet.weight ?? 0) > 0) {
          summary =
              'Vol: ${completedVolume.toInt()}kg | Top: ${topSet.weight!.toInt()}kg x ${topSet.reps ?? 0}';
        } else {
          summary = 'Vol: ${completedVolume.toInt()}kg';
        }
      } else {
        // Bodyweight or no weight recorded — show sets / reps
        final totalReps = completedLogs.fold<int>(
          0,
          (sum, l) => sum + (l.reps ?? 0),
        );
        final setCount = completedLogs.length;
        if (setCount > 0 && totalReps > 0) {
          summary = '$setCount sets | $totalReps reps';
        } else {
          summary = '${logs.length} sets';
        }
      }

      return _ExerciseHighlight(
        name: entry.key,
        hasMissingData: hasMissing,
        summary: summary,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM');
    final dayFormat = DateFormat('d');
    final isZeroVolume = _totalVolume == 0;
    final highlights = _exerciseHighlights;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Main row: Date | Info | Chevron --------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date column
                  SizedBox(
                    width: 45,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dateFormat.format(session.startTime).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          dayFormat.format(session.startTime),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Session info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          session.name ?? 'Workout Session',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Volume
                            _InfoChip(
                              icon: Icons.monitor_weight_outlined,
                              label: '${_totalVolume.toInt()} kg',
                              color: isZeroVolume
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            // Duration
                            _InfoChip(
                              icon: Icons.access_time,
                              label: _formatDuration(_duration),
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            // Warning icon for missing data
                            if (_hasMissingData) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: theme.colorScheme.error,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chevron
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),

              // ---- Exercise highlights ------------------------------------
              if (highlights.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildExerciseHighlights(context, highlights),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseHighlights(
    BuildContext context,
    List<_ExerciseHighlight> highlights,
  ) {
    final theme = Theme.of(context);
    final displayed = highlights.take(4).toList();
    final overflowCount = highlights.length - 4;

    return Padding(
      padding: const EdgeInsets.only(left: 59), // aligns with text, not date
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayed.map((ex) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ex.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: ex.hasMissingData
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: ex.hasMissingData
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ex.summary,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: ex.hasMissingData
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )),
          if (overflowCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ $overflowCount more exercises',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info chip — small icon + label for volume / duration
// ---------------------------------------------------------------------------

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}
