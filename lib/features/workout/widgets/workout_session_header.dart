import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_timer_provider.dart';

class WorkoutSessionHeader extends ConsumerWidget {
  final VoidCallback onShowRestTimer;
  final VoidCallback? onMinimize;

  const WorkoutSessionHeader({
    super.key,
    required this.onShowRestTimer,
    this.onMinimize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    final timerState = ref.watch(workoutTimerProvider);
    final timerNotifier = ref.watch(workoutTimerProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grabber handle
        Container(
          width: 40,
          height: 5,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 20, 20),
          child: Row(
            children: [
              // Minimize button
              if (onMinimize != null)
                IconButton(
                  onPressed: onMinimize,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              
              if (onMinimize == null && state.isTrainerLed) const SizedBox(width: 8),

              // Client/Session Info
              if (state.isTrainerLed) ...[
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 15),
              ],
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!state.isTrainerLed) ...[
                      Text(
                        'PERSONAL SESSION',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'WORKOUT',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'LIVE SESSION WITH',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        state.session?.name?.toUpperCase() ?? 'ACTIVE WORKOUT',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        (state.clientName ?? 'Client').toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Timer Capsule
              GestureDetector(
                onTap: onShowRestTimer,
                child: _WorkoutTimerDisplay(
                  formattedTime: timerNotifier.formattedTime,
                  isRunning: timerState == WorkoutTimerState.running,
                  isResting: state.isRestRunning,
                  restSeconds: state.restSeconds,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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

class _WorkoutTimerDisplay extends StatelessWidget {
  final String formattedTime;
  final bool isRunning;
  final bool isResting;
  final int restSeconds;

  const _WorkoutTimerDisplay({
    required this.formattedTime,
    required this.isRunning,
    required this.isResting,
    required this.restSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // If resting, show a simplified rest progress or just the rest timer
    if (isResting) {
      return Container(
        width: 140,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'REST: ${_formatRestTime(restSeconds)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 140,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            formattedTime,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
