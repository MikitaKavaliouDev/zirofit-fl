import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';

class WorkoutSessionControls extends ConsumerWidget {
  final VoidCallback onVoicePressed;
  final VoidCallback onFinishPressed;
  final VoidCallback onCancelPressed;
  final bool isRecording;

  const WorkoutSessionControls({
    super.key,
    required this.onVoicePressed,
    required this.onFinishPressed,
    required this.onCancelPressed,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);

    final bool isBlank = state.logs.isEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Row(
            children: [
              // Voice Button (iOS-aligned: left side)
              _VoiceControlButton(
                isRecording: isRecording,
                onPressed: onVoicePressed,
              ),
              const SizedBox(width: 12),
              
              // Finish/Cancel Button (iOS-aligned: right side, no pause button)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    if (isBlank) {
                      onCancelPressed();
                    } else {
                      onFinishPressed();
                    }
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isBlank 
                          ? Colors.red.withValues(alpha: 0.8) 
                          : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isBlank ? 'Cancel' : 'Finish',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceControlButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const _VoiceControlButton({
    required this.isRecording,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? Colors.red : Colors.blue,
          boxShadow: isRecording ? [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ] : null,
        ),
        transform: Matrix4.identity()..scale(isRecording ? 1.15 : 1.0),
        child: Icon(
          isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}


