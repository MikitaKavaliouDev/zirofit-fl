import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_timer_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';

// ---------------------------------------------------------------------------
// WorkoutMiniPlayer
// ---------------------------------------------------------------------------

/// A compact horizontal bar pinned at the bottom of the screen while a workout
/// is active. Matches iOS WorkoutMiniPlayer design with rest ring overlay,
/// expand chevron, pause/resume, and swipe gestures.
///
/// Tapping expand or swiping up expands to full session.
/// Tap anywhere else also expands.
class WorkoutMiniPlayer extends ConsumerStatefulWidget {
  const WorkoutMiniPlayer({
    super.key,
    this.onTap,
    this.onClose,
    this.onExpand,
    this.expanded = false,
  });

  /// Called when the user taps the mini player.
  final VoidCallback? onTap;

  /// Called when the user taps the close (X) button.
  final VoidCallback? onClose;

  /// Called when the user taps the expand chevron or swipes up.
  final VoidCallback? onExpand;

  /// If true, shows expanded state (used when this is the primary view).
  final bool expanded;

  @override
  ConsumerState<WorkoutMiniPlayer> createState() => _WorkoutMiniPlayerState();
}

class _WorkoutMiniPlayerState extends ConsumerState<WorkoutMiniPlayer>
    with SingleTickerProviderStateMixin {
  Timer? _elapsedTimer;
  DateTime? _workoutStartTime;
  int _elapsedSeconds = 0;
  double _dragAccumulator = 0;
  bool _isDragging = false;

  late AnimationController _springController;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _startElapsedTimer();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _springController.dispose();
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

  void _handleDragStart(DragStartDetails details) {
    _dragAccumulator = 0;
    _isDragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    // Only respond to upward drags (negative dy = up)
    if (details.delta.dy < 0) {
      // Apply 1/3 resistance for drag-up to expand
      _dragAccumulator += details.delta.dy.abs() / 3;
    } else {
      // Drag down with 1/3 resistance
      _dragAccumulator -= details.delta.dy / 3;
    }

    if (_dragAccumulator >= 80) {
      // Threshold reached: expand with haptic feedback
      HapticFeedback.mediumImpact();
      _dragAccumulator = 0;
      _isDragging = false;
      widget.onExpand?.call();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragAccumulator = 0;
    _isDragging = false;
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      ref.read(sessionOverlayProvider.notifier).hide();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutState = ref.watch(activeWorkoutProvider);
    final timerState = ref.watch(workoutTimerProvider);
    final enhancementState = ref.watch(workoutEnhancementProvider);

    // Don't render if there's no active session
    if (!workoutState.hasActiveSession) {
      return const SizedBox.shrink();
    }

    final session = workoutState.session!;
    final restSeconds = workoutState.restSeconds;
    final isRestRunning = workoutState.isRestRunning;
    final isPaused = timerState == WorkoutTimerState.paused;

    // Find the most recent exercise name
    final lastLog =
        workoutState.logs.isNotEmpty ? workoutState.logs.last : null;
    final exerciseName = lastLog != null
        ? (workoutState.exerciseNames[lastLog.exerciseId] ?? lastLog.exerciseName ?? 'Exercise')
        : session.name ?? 'Workout';

    // Rest progress for ring overlay (0.0 to 1.0)
    final restTotal = enhancementState.restTimerSettings.defaultSeconds;
    final restProgress = restTotal > 0
        ? (restSeconds / restTotal).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: widget.onTap,
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Rest ring indicator (left of icon)
                    if (isRestRunning && restSeconds > 0) ...[
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background ring
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 2,
                              backgroundColor: Colors.transparent,
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                            // Progress ring (orange)
                            CircularProgressIndicator(
                              value: restProgress,
                              strokeWidth: 2,
                              backgroundColor: Colors.transparent,
                              color: const Color(0xFFFF6B00),
                            ),
                            // "REST" label inside ring
                            Text(
                              'REST',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFFFF6B00),
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
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
                    ],
                    const SizedBox(width: 12),

                    // Exercise name + elapsed
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
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatElapsed(_elapsedSeconds),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              if (isRestRunning && restSeconds > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Rest ${restSeconds}s',
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

                    // Pause/Resume button (iOS style)
                    IconButton(
                      icon: Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () {
                        ref.read(workoutTimerProvider.notifier).togglePause();
                      },
                    ),

                    // Expand chevron button (iOS style)
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_up,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: widget.onExpand,
                    ),
                  ],
                ),
              ),
              // Close button (top-right corner)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _handleClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  tooltip: 'Close mini player',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}