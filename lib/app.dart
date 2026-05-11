import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/router/app_router.dart';
import 'package:zirofit_fl/core/theme/app_theme.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/finish_workout_dialog.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_header_widget.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_controls_bar.dart';
import 'package:zirofit_fl/features/workout/widgets/exercise_list_builder.dart';

/// Wraps the entire app with a workout session overlay layer.
/// When a workout is active (full state), shows a full-screen overlay above the shell.
/// When minimized, shows the mini-player via the shells.
class WorkoutSessionOverlay extends ConsumerWidget {
  final Widget child;

  const WorkoutSessionOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayState = ref.watch(sessionOverlayProvider);

    if (overlayState == SessionOverlayState.hidden) {
      return child;
    }

    if (overlayState == SessionOverlayState.full) {
      return _buildFullOverlay(context, ref);
    }

    // mini state: shells handle the mini-player rendering
    return child;
  }

  Widget _buildFullOverlay(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // Dimmed background
        GestureDetector(
          onTap: () {
            // Minimize on tap outside (matching iOS drag-to-minimize conceptually)
            // Or do nothing - only drag or explicit actions minimize
          },
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        // Full screen workout session
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header with timer and rest bar
              WorkoutHeaderWidget(
                sessionName: _getSessionName(ref),
                onMinimize: () {
                  ref.read(sessionOverlayProvider.notifier).state = SessionOverlayState.mini;
                },
                onTapTimer: () {
                  // Open rest timer sheet
                  _openRestTimerSheet(context);
                },
              ),
              // Exercise list
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: ExerciseListBuilder(
                    onAddExercise: () {
                      _openExerciseSelection(context);
                    },
                  ),
                ),
              ),
              // Floating controls bar
              FloatingControlsBar(
                onVoiceStart: () => _startVoiceInput(context),
                onVoiceEnd: () => _stopVoiceInput(context),
                onFinish: () => _handleFinish(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSessionName(WidgetRef ref) {
    // This will be populated when the session is active
    return 'Workout Session';
  }

  void _openRestTimerSheet(BuildContext context) {
    // Delegates to the existing RestTimerSheet implementation
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _RestTimerSheetPlaceholder(),
    );
  }

  void _openExerciseSelection(BuildContext context) {
    // This would open the ExerciseSelectionView - handled by existing screen
  }

  void _startVoiceInput(BuildContext context) {
    // Voice input handled by VoiceInputOverlay
  }

  void _stopVoiceInput(BuildContext context) {
    // Voice input stop
  }

  void _handleFinish(BuildContext context, WidgetRef ref) async {
    final option = await FinishWorkoutAlert.show(context);
    if (option == null) return;

    final notifier = ref.read(activeWorkoutProvider.notifier);

    if (option == FinishOption.completeUnfinished) {
      notifier.completeUnfinishedSets();
    }

    // Discard option: just finish without completing
    final finishedSession = await notifier.finishWorkout();

    if (finishedSession != null) {
      ref.read(sessionOverlayProvider.notifier).state = SessionOverlayState.hidden;
      if (context.mounted) {
        // Navigate to summary screen
        Navigator.of(context).pushReplacementNamed('/workout/summary');
      }
    }
  }
}

/// Placeholder - actual rest timer sheet is in rest_timer_sheet.dart
class _RestTimerSheetPlaceholder extends StatelessWidget {
  const _RestTimerSheetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Text('Rest Timer'),
    );
  }
}

class ZiroFitApp extends ConsumerWidget {
  const ZiroFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ziro Fit',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return WorkoutSessionOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}