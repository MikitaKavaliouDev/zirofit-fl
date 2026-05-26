import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/voice_coach/voice_coach_provider.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';

class WorkoutSessionControls extends ConsumerWidget {
  final VoidCallback onRecordingStart;
  final VoidCallback onRecordingEnd;
  final VoidCallback onCoachRecordingStart;
  final VoidCallback onCoachRecordingEnd;
  final VoidCallback onFinishPressed;
  final VoidCallback onCancelPressed;
  final VoidCallback? onOpenVoiceSettings;
  final bool isRecording;

  const WorkoutSessionControls({
    super.key,
    required this.onRecordingStart,
    required this.onRecordingEnd,
    this.onCoachRecordingStart = _noop,
    this.onCoachRecordingEnd = _noop,
    required this.onFinishPressed,
    required this.onCancelPressed,
    this.onOpenVoiceSettings,
    this.isRecording = false,
  });

  static void _noop() {}

  static const Color _indigo = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    final coachState = ref.watch(voiceCoachProvider);
    final theme = Theme.of(context);
    final isCoachMode = coachState.voiceMode == VoiceMode.coach;

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
              // Voice Button (iOS-aligned: left side, push-to-talk)
              // Color: blue for dictation, indigo for coach, red when recording
              _VoiceControlButton(
                isRecording: isCoachMode
                    ? coachState.isRecording
                    : isRecording,
                color: isCoachMode ? _indigo : Colors.blue,
                onRecordingStart: isCoachMode
                    ? onCoachRecordingStart
                    : onRecordingStart,
                onRecordingEnd: isCoachMode
                    ? onCoachRecordingEnd
                    : onRecordingEnd,
              ),
              if (isCoachMode) ...[
                const SizedBox(width: 4),
                // Settings gear for coach mode
                GestureDetector(
                  onTap: onOpenVoiceSettings,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _indigo.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      size: 18,
                      color: _indigo,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              
              // Finish/Cancel Button (iOS-aligned: right side, no pause button)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
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
  final Color color;
  final VoidCallback onRecordingStart;
  final VoidCallback onRecordingEnd;

  const _VoiceControlButton({
    required this.isRecording,
    this.color = Colors.blue,
    required this.onRecordingStart,
    required this.onRecordingEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        onRecordingStart();
      },
      onTapUp: (_) {
        onRecordingEnd();
      },
      onTapCancel: () {
        onRecordingEnd();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? Colors.red : color,
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


