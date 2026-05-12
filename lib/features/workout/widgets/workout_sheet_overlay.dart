import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/screens/enhanced_active_workout_screen.dart';

// ---------------------------------------------------------------------------
// WorkoutSheetOverlay
// ---------------------------------------------------------------------------

/// Renders [EnhancedActiveWorkoutScreen] as a bottom-sheet-style overlay that
/// slides up from the bottom of the screen.
///
/// Lives in the shell's [Stack] alongside the mini player.
/// Controlled by [sessionOverlayProvider]:
/// - [SessionOverlayState.full]  → sheet slides up (visible)
/// - [SessionOverlayState.mini]  → sheet slides down (hidden, mini player shows)
/// - [SessionOverlayState.hidden] → sheet slides down (hidden)
class WorkoutSheetOverlay extends ConsumerStatefulWidget {
  final VoidCallback? onFinishWorkout;
  final VoidCallback? onCancelWorkout;
  final String? templateId; // for deep links

  const WorkoutSheetOverlay({
    super.key,
    this.onFinishWorkout,
    this.onCancelWorkout,
    this.templateId,
  });

  @override
  ConsumerState<WorkoutSheetOverlay> createState() =>
      _WorkoutSheetOverlayState();
}

class _WorkoutSheetOverlayState extends ConsumerState<WorkoutSheetOverlay> {
  @override
  Widget build(BuildContext context) {
    final overlayState = ref.watch(sessionOverlayProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final isVisible = overlayState == SessionOverlayState.full;

    return Stack(
      children: [
        // Semi-transparent backdrop (tap to minimize) — fades in/out
        AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: isVisible ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: GestureDetector(
              onTap: () => ref.read(sessionOverlayProvider.notifier).showMini(),
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
        ),

        // Workout sheet — slides up from bottom
        // AnimatedPositioned (which extends Positioned) must be a direct child of Stack.
        // IgnorePointer is placed inside to avoid breaking parent-data chain.
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: 0,
          height: isVisible ? screenHeight * 0.9 : 0,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: EnhancedActiveWorkoutScreen(
                isOverlay: true,
                templateId: widget.templateId,
                onMinimize: () =>
                    ref.read(sessionOverlayProvider.notifier).showMini(),
                onFinish: (WorkoutSession session, List<ClientExerciseLog> logs) {
                  ref.read(sessionOverlayProvider.notifier).hide();
                  widget.onFinishWorkout?.call();
                },
                onCancel: () {
                  ref.read(sessionOverlayProvider.notifier).hide();
                  widget.onCancelWorkout?.call();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
