import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_timer_provider.dart';

/// Header bar for the full-screen workout session view.
class WorkoutHeaderWidget extends ConsumerStatefulWidget {
  const WorkoutHeaderWidget({
    super.key,
    this.clientName,
    required this.sessionName,
    required this.onMinimize,
    required this.onTapTimer,
  });

  final String? clientName;
  final String sessionName;
  final VoidCallback onMinimize;
  final VoidCallback onTapTimer;

  @override
  ConsumerState<WorkoutHeaderWidget> createState() => _WorkoutHeaderWidgetState();
}

class _WorkoutHeaderWidgetState extends ConsumerState<WorkoutHeaderWidget> {
  Timer? _elapsedTimer;
  double _dragStartY = 0;
  double _totalDragY = 0;
  String _formattedTime = '0:00';

  @override
  void initState() {
    super.initState();
    _startElapsedTimer();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _updateTimer();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimer();
    });
  }

  void _updateTimer() {
    final notifier = ref.read(workoutTimerProvider.notifier);
    if (mounted) {
      setState(() {
        _formattedTime = notifier.formattedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutState = ref.watch(activeWorkoutProvider);

    final isTrainerLed = widget.clientName != null;
    final clientName = widget.clientName;

    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.localPosition.dy;
        _totalDragY = 0;
      },
      onVerticalDragUpdate: (details) {
        final delta = details.localPosition.dy - _dragStartY;
        setState(() {
          _totalDragY = _totalDragY + delta;
          _dragStartY = details.localPosition.dy;
        });

        // Check if we should minimize (120px threshold)
        if (_totalDragY >= 120) {
          widget.onMinimize();
          _totalDragY = 0;
        }
      },
      onVerticalDragEnd: (details) {
        _dragStartY = 0;
        _totalDragY = 0;
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainer,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section: Session label and name
              Row(
                children: [
                  // Session label
                  Expanded(
                    child: Text(
                      isTrainerLed && clientName != null
                          ? 'LIVE SESSION WITH ${clientName.toUpperCase()}'
                          : 'PERSONAL SESSION',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  // Client avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      isTrainerLed && clientName != null
                          ? clientName[0].toUpperCase()
                          : 'Y',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Session name
              Text(
                widget.sessionName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Middle section: Elapsed timer
              GestureDetector(
                onTap: widget.onTapTimer,
                child: Text(
                  _formattedTime,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bottom section: Rest timer bar
              if (workoutState.isRestRunning && workoutState.restSeconds > 0) ...[
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Text(
                        'REST',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final restSeconds = workoutState.restSeconds;
                            const initialRest = 90;
                            final progress = initialRest > 0 ? (restSeconds / initialRest).clamp(0.0, 1.0) : 0.0;

                            return Stack(
                              children: [
                                // Background track
                                Container(
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Progress bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: constraints.maxWidth * progress,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'REST ${_formatRestTime(workoutState.restSeconds)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatRestTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${remainingSeconds}s';
    }
  }
}