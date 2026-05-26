import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_timer_provider.dart';

/// Floating bottom control bar for active workout session
/// Matches iOS WorkoutSessionControls design with capsule shape and blur effect
class FloatingControlsBar extends ConsumerWidget {
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceEnd;
  final VoidCallback onFinish;

  const FloatingControlsBar({
    super.key,
    required this.onVoiceStart,
    required this.onVoiceEnd,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mic Button - Left side
                    GestureDetector(
                      onLongPressStart: (_) => onVoiceStart(),
                      onLongPressEnd: (_) => onVoiceEnd(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        transform: Matrix4.identity()
                          ..scale(1.0),
                        child: const Icon(
                          Icons.mic,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    // Sync indicator (shown briefly during save operations)
                    Consumer(
                      builder: (context, ref, child) {
                        final state = ref.watch(activeWorkoutProvider);
                        if (!state.isSyncingWorkout && !state.isSyncingLibrary) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Pause/Resume Button - Center
                    Consumer(
                      builder: (context, ref, child) {
                        final timerData = ref.watch(workoutTimerProvider);
                        final isPaused = timerData.isPaused;
                        
                        return GestureDetector(
                          onTap: () {
                            ref.read(workoutTimerProvider.notifier).togglePause();
                          },
                          child: Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            size: 28,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    
                    // Finish Button - Right side
                    FilledButton(
                      onPressed: onFinish,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Finish',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}