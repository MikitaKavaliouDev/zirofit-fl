import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';

// ---------------------------------------------------------------------------
// WorkoutMiniPlayer
// ---------------------------------------------------------------------------

/// A compact horizontal bar pinned at the bottom of the screen while a workout
/// is active.  Shows the current exercise name, elapsed workout time, and a
/// rest countdown.
///
/// Tapping the bar expands to the full [ActiveWorkoutScreen].
/// A close (X) button dismisses / minimises it.
///
/// Uses a blurred glassmorphism background and is safe-area aware.
class WorkoutMiniPlayer extends ConsumerStatefulWidget {
  const WorkoutMiniPlayer({
    super.key,
    this.onTap,
    this.onClose,
    this.expanded = false,
  });

  /// Called when the user taps the mini player to expand.
  final VoidCallback? onTap;

  /// Called when the user taps the close button.
  final VoidCallback? onClose;

  /// If true, shows a more detailed state (used when this is the primary view).
  final bool expanded;

  @override
  ConsumerState<WorkoutMiniPlayer> createState() => _WorkoutMiniPlayerState();
}

class _WorkoutMiniPlayerState extends ConsumerState<WorkoutMiniPlayer>
    with SingleTickerProviderStateMixin {
  Timer? _elapsedTimer;
  DateTime? _workoutStartTime;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startElapsedTimer();
  }

  @override
  void didUpdateWidget(WorkoutMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final session = ref.read(activeWorkoutProvider).session;
    _syncStartTime(session);
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer() {
    final session = ref.read(activeWorkoutProvider).session;
    _syncStartTime(session);

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_workoutStartTime != null) {
        setState(() {
          _elapsedSeconds =
              DateTime.now().difference(_workoutStartTime!).inSeconds;
        });
      }
    });
  }

  void _syncStartTime(WorkoutSession? session) {
    if (session != null && _workoutStartTime == null) {
      _workoutStartTime = session.startTime;
      _elapsedSeconds =
          DateTime.now().difference(session.startTime).inSeconds;
    }
  }

  String _formatElapsed(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutState = ref.watch(activeWorkoutProvider);

    // Don't render if there's no active session
    if (!workoutState.hasActiveSession) {
      return const SizedBox.shrink();
    }

    final session = workoutState.session!;
    final restSeconds = workoutState.restSeconds;
    final isRestRunning = workoutState.isRestRunning;

    // Find the most recent exercise name
    final lastLog =
        workoutState.logs.isNotEmpty ? workoutState.logs.last : null;
    final exerciseName = lastLog != null
        ? (workoutState.exerciseNames[lastLog.exerciseId] ?? lastLog.exerciseName ?? 'Exercise')
        : session.name ?? 'Workout';

    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              // ── Play icon ──
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),

              // ── Exercise name + elapsed ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exerciseName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatElapsed(_elapsedSeconds),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isRestRunning && restSeconds > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${restSeconds}s',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Rest countdown badge ──
              if (isRestRunning && restSeconds > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: restSeconds <= 10
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(restSeconds ~/ 60).toString().padLeft(2, '0')}:${(restSeconds % 60).toString().padLeft(2, '0')}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: restSeconds <= 10
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // ── Close button ──
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: widget.onClose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

