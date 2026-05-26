import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/clients/providers/client_list_provider.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/exercise_library_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_timer_provider.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/screens/workout_summary_screen.dart';
import 'package:zirofit_fl/core/services/apple_calendar_service.dart';
import 'package:zirofit_fl/features/workout/services/voice_feedback_service.dart';
import 'package:zirofit_fl/features/workout/services/voice_log_service.dart';
import 'package:zirofit_fl/features/workout/services/workout_toast_service.dart';
import 'package:zirofit_fl/features/workout/models/workout_focus_state.dart';
import 'package:zirofit_fl/features/programs/widgets/template_picker_sheet.dart';
import 'package:zirofit_fl/features/workout/widgets/exercise_selection_view.dart';
import 'package:zirofit_fl/features/workout/widgets/enhanced_exercise_list_builder.dart';
import 'package:zirofit_fl/features/workout/widgets/voice_correction_picker.dart';
import 'package:zirofit_fl/features/workout/widgets/voice_input_overlay.dart';
import 'package:zirofit_fl/features/workout/widgets/voice_log_overlay.dart';
import 'package:zirofit_fl/features/workout/widgets/youtube_sheet_view.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_numeric_keyboard.dart';
import 'package:zirofit_fl/features/workout/widgets/rpe_picker_overlay.dart';
import 'package:zirofit_fl/features/workout/widgets/rest_timer_sheet.dart';
import 'package:zirofit_fl/features/workout/widgets/interactive_plate_calculator.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_session_header.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_session_controls.dart';
import 'package:zirofit_fl/features/workout/widgets/finish_workout_dialog.dart'
    as finish_dialog;
import 'package:zirofit_fl/features/voice_coach/voice_coach_provider.dart';
import 'package:zirofit_fl/features/voice_coach/voice_coach_settings_screen.dart';
import 'package:zirofit_fl/features/voice_coach/widgets/voice_coach_overlay.dart';

// =============================================================================
// WorkoutConflictAction — used by the ongoing session dialog
// =============================================================================
enum WorkoutConflictAction { resume, endAndStart, cancel }

// =============================================================================
// EnhancedActiveWorkoutScreen
//
// iOS-aligned live workout session screen matching WorkoutSessionView.swift.
//
// Architecture (ZStack equivalent):
//   1. Background (tap dismisses input overlay)
//   2. Column: Header (with drag gesture) + Content (expanded)
//   3. Controls bar (animated opacity — hidden when input is active)
//   4. Input overlay system (keyboard / plate calculator / RPE picker)
//   5. Finish alert overlay (FinishWorkoutAlert)
//   6. Voice log overlay
// =============================================================================

class EnhancedActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String? templateId;
  final bool isOverlay;
  final VoidCallback? onMinimize;
  final void Function(WorkoutSession, List<ClientExerciseLog>)? onFinish;
  final VoidCallback? onCancel;

  const EnhancedActiveWorkoutScreen({
    super.key,
    this.templateId,
    this.isOverlay = false,
    this.onMinimize,
    this.onFinish,
    this.onCancel,
  });

  @override
  ConsumerState<EnhancedActiveWorkoutScreen> createState() =>
      _EnhancedActiveWorkoutScreenState();
}

class _EnhancedActiveWorkoutScreenState
    extends ConsumerState<EnhancedActiveWorkoutScreen>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Services
  // ---------------------------------------------------------------------------
  final VoiceFeedbackService _voiceService = VoiceFeedbackService();
  final VoiceLogService _voiceLogService = VoiceLogService();

  // ---------------------------------------------------------------------------
  // Input System State (iOS: WorkoutInputState)
  // ---------------------------------------------------------------------------
  WorkoutInputState _inputState = const WorkoutInputState();

  // ---------------------------------------------------------------------------
  // Sheet / Dialog flags (iOS: @State bools)
  // ---------------------------------------------------------------------------
  final bool _showExercisePicker = false;
  final bool _showTemplatePicker = false;
  final bool _showRestTimer = false;
  final bool _showFinishAlert = false;
  bool _showEmptyDataAlert = false;
  final bool _showCancelAlert = false;
  bool _showHighDurationAlert = false;
  bool _showingSaveTemplateAlert = false;
  final String _saveTemplateName = '';
  final TextEditingController _saveTemplateController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Voice Overlay state (iOS voiceLogOverlay)
  // ---------------------------------------------------------------------------
  bool _voiceOverlayVisible = false;
  bool _voiceCommandPending = false;

  /// Tracks the last exercise that was announced by the voice coach,
  /// preventing duplicate "next up" announcements for the same exercise.
  String? _lastAnnouncedExerciseId;

  // ---------------------------------------------------------------------------
  // Drag to dismiss state
  // ---------------------------------------------------------------------------
  final ValueNotifier<double> _dragOffset = ValueNotifier<double>(0.0);
  late AnimationController _minimizeController;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _minimizeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    Future.microtask(() => _initWorkout());
    Future.microtask(() => _voiceService.initialize());
  }

  @override
  void dispose() {
    _voiceService.stop();
    _voiceLogService.stopListening();
    _minimizeController.dispose();
    _dragOffset.dispose();
    _saveTemplateController.dispose();
    super.dispose();
  }

  Future<void> _initWorkout() async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    if (widget.templateId != null) {
      await notifier.startWorkout(templateId: widget.templateId);
    } else {
      await notifier.loadActiveSession();
    }
  }

  // ===========================================================================
  // iOS Input System
  // ===========================================================================

  /// Maps iOS triggerInput(for: SessionFocusField)
  void _triggerInput(SessionFocusField field) {
    // Save current before switching
    _syncActiveInput();

    final currentValue = _getCurrentValue(field);
    setState(() {
      _inputState = _inputState.copyWith(
        focusedField: field,
        activeSetId: field.setId,
        activeText: currentValue,
        isInputSelected: false,
        overlay: field.isRpe
            ? WorkoutInputOverlay.rpePicker
            : WorkoutInputOverlay.keyboard,
      );
    });
  }

  /// Maps iOS syncActiveInput() — saves current text to provider
  void _syncActiveInput() {
    if (!_inputState.isActive || _inputState.activeSetId == null) return;

    final value = _inputState.activeText.replaceAll(',', '.');
    final numericValue = double.tryParse(value) ?? 0;
    final intValue = int.tryParse(value) ?? 0;

    if (_inputState.focusedField?.isWeight == true) {
      ref.read(activeWorkoutProvider.notifier).updateSetWeight(
            _inputState.activeSetId!,
            numericValue,
          );
    } else if (_inputState.focusedField?.isReps == true) {
      ref.read(activeWorkoutProvider.notifier).updateSetReps(
            _inputState.activeSetId!,
            intValue,
          );
    } else if (_inputState.focusedField?.isTempo == true) {
      ref.read(activeWorkoutProvider.notifier).updateSetTempo(
            _inputState.activeSetId!,
            _inputState.activeText,
          );
    }
  }

  /// Maps iOS handleInputNext() — weight → reps → tempo → rpe → next set weight (or close)
  void _handleInputNext() {
    _syncActiveInput();

    final current = _inputState.focusedField;
    if (current != null) {
      if (current.isWeight) {
        setState(() {
          _inputState = _inputState.copyWith(
            focusedField: SessionFocusField.reps(current.setId),
            activeText: _getCurrentValue(SessionFocusField.reps(current.setId)),
          );
        });
      } else if (current.isReps) {
        setState(() {
          _inputState = _inputState.copyWith(
            focusedField: SessionFocusField.tempo(current.setId),
            activeText: _getCurrentValue(SessionFocusField.tempo(current.setId)),
          );
        });
      } else if (current.isTempo) {
        setState(() {
          _inputState = _inputState.copyWith(
            focusedField: SessionFocusField.rpe(current.setId),
            overlay: WorkoutInputOverlay.rpePicker,
            activeText: '',
          );
        });
      } else if (current.isRpe) {
        // RPE is last field → move to next set's weight
        final nextSetId = _findNextSetId(current.setId);
        if (nextSetId != null) {
          setState(() {
            _inputState = _inputState.copyWith(
              focusedField: SessionFocusField.weight(nextSetId),
              activeSetId: nextSetId,
              overlay: WorkoutInputOverlay.keyboard,
              activeText:
                  _getCurrentValue(SessionFocusField.weight(nextSetId)),
            );
          });
        } else {
          _closeInput();
        }
      } else {
        _closeInput();
      }
    }
  }

  /// Maps iOS triggerInput field value extraction
  String _getCurrentValue(SessionFocusField field) {
    final state = ref.read(activeWorkoutProvider);
    for (final log in state.logs) {
      if (log.id == field.setId) {
        if (field.isWeight) {
          return (log.weight ?? 0) == 0
              ? ''
              : ((log.weight!) == (log.weight!.floorToDouble())
                  ? log.weight!.toStringAsFixed(0)
                  : log.weight!.toStringAsFixed(1));
        } else if (field.isReps) {
          return (log.reps ?? 0) == 0 ? '' : log.reps!.toString();
        } else if (field.isTempo) {
          return log.tempo ?? '';
        }
      }
    }
    return '';
  }

  String? _findNextSetId(String currentSetId) {
    final allLogs = ref.read(activeWorkoutProvider).logs;
    final index = allLogs.indexWhere((log) => log.id == currentSetId);
    if (index >= 0 && index + 1 < allLogs.length) {
      return allLogs[index + 1].id;
    }
    return null;
  }

  void _closeInput() {
    _syncActiveInput();
    setState(() {
      _inputState = const WorkoutInputState();
    });
  }

  /// Maps iOS inputOverlay = .plateCalculator
  void _switchToPlateCalculator() {
    setState(() {
      _inputState = _inputState.copyWith(
        overlay: WorkoutInputOverlay.plateCalculator,
      );
    });
  }

  /// Maps iOS inputOverlay = .rpePicker
  void _switchToRpePicker() {
    setState(() {
      _inputState = _inputState.copyWith(
        overlay: WorkoutInputOverlay.rpePicker,
      );
    });
  }

  /// Maps iOS inputOverlay = .keyboard (plate/RPE → keyboard)
  void _switchToKeyboard() {
    setState(() {
      _inputState = _inputState.copyWith(
        overlay: WorkoutInputOverlay.keyboard,
      );
    });
  }

  /// Called by plate calculator when weight changes
  void _onPlateWeightChanged(double weight) {
    setState(() {
      _inputState = _inputState.copyWith(
        activeText: weight == weight.floorToDouble()
            ? weight.toStringAsFixed(0)
            : weight.toStringAsFixed(1),
      );
    });
  }

  // ===========================================================================
  // iOS Handlers: Finish / Cancel / Save Template
  // ===========================================================================

  /// Maps iOS _onFinishWorkout + Flow
  Future<void> _onFinishWorkout(BuildContext context) async {
    final currentState = ref.read(activeWorkoutProvider);

    // Check if any sets completed → if none, show empty data alert
    if (currentState.completedSets == 0) {
      _showEmptyDataAlert = true;
      setState(() {});
      return;
    }

    // iOS-aligned: Show FinishWorkoutAlert
    final option = await finish_dialog.FinishWorkoutAlert.show(context);
    if (option == null) return; // User cancelled

    final notifier = ref.read(activeWorkoutProvider.notifier);
    WorkoutSession? finishedSession;

    switch (option) {
      case finish_dialog.FinishOption.completeUnfinished:
        finishedSession =
            await notifier.finishWorkoutWithOption(FinishOption.completeUnfinished);
      case finish_dialog.FinishOption.discardUnfinished:
        finishedSession =
            await notifier.finishWorkoutWithOption(FinishOption.discardUnfinished);
    }

    if (finishedSession != null && mounted) {
      _onWorkoutFinished(finishedSession);
    }
  }

  /// Maps iOS WorkoutSessionControls finish flow + Complete Session? alert
  void _onFinishButtonPressed() {
    final currentState = ref.read(activeWorkoutProvider);

    if (currentState.logs.isEmpty) {
      // Blank session → cancel
      _showCancelWorkoutAlert();
      return;
    }

    // Has data but none completed → show empty data alert
    if (currentState.completedSets == 0) {
      setState(() => _showEmptyDataAlert = true);
      return;
    }

    // Has incomplete valid sets → show FinishWorkoutAlert (Complete/Discard)
    if (currentState.hasIncompleteSets) {
      _onFinishWorkout(context);
      return;
    }

    // All completed → finish directly
    _finishWorkoutDirectly();
  }

  Future<void> _finishWorkoutDirectly() async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final finishedSession = await notifier.finishWorkout();
    if (finishedSession != null && mounted) {
      _onWorkoutFinished(finishedSession);
    }
  }

  void _onWorkoutFinished(WorkoutSession finishedSession) {
    final currentState = ref.read(activeWorkoutProvider);
    final currentLogs = currentState.logs.toList();
    final exerciseNames = currentState.exerciseNames;

    final enrichedLogs = currentLogs.map((log) {
      if (log.exerciseName == null &&
          exerciseNames.containsKey(log.exerciseId)) {
        return ClientExerciseLog(
          id: log.id,
          clientId: log.clientId,
          exerciseId: log.exerciseId,
          reps: log.reps,
          weight: log.weight,
          isCompleted: log.isCompleted,
          order: log.order,
          tempo: log.tempo,
          side: log.side,
          workoutSessionId: log.workoutSessionId,
          supersetKey: log.supersetKey,
          orderInSuperset: log.orderInSuperset,
          sets: log.sets,
          rpe: log.rpe,
          rir: log.rir,
          exerciseName: exerciseNames[log.exerciseId],
          createdAt: log.createdAt,
          updatedAt: log.updatedAt,
          deletedAt: log.deletedAt,
        );
      }
      return log;
    }).toList();

    ref.read(sessionOverlayProvider.notifier).hide();
    _voiceService.announceWorkoutComplete();
    _syncWorkoutToCalendar(finishedSession); // fire-and-forget

    if (widget.onFinish != null) {
      widget.onFinish!(finishedSession, enrichedLogs);
    } else if (mounted) {
      _navigateToSummary(context, finishedSession, enrichedLogs);
    }
  }

  /// Syncs the finished workout to Apple Calendar if the user has sync
  /// enabled. This is fire-and-forget and will never block navigation.
  Future<void> _syncWorkoutToCalendar(WorkoutSession finishedSession) async {
    try {
      final service = ref.read(appleCalendarServiceProvider);
      if (!await service.isSyncEnabled()) return;

      if (!await service.hasPermission()) {
        if (!await service.requestPermission()) return;
      }

      final result = await service.createEvent(
        title: 'Workout: ${finishedSession.name ?? "Workout"}',
        start: finishedSession.startTime,
        end: finishedSession.endTime ??
            finishedSession.startTime.add(const Duration(hours: 1)),
        notes: 'Completed workout session',
      );

      if (result != null) {
        await service.storeEventMapping(
          bookingId: finishedSession.id,
          eventId: result.eventId,
          calendarId: result.calendarId,
        );
      }
    } catch (e) {
      debugPrint('Calendar sync error: $e');
    }
  }

  /// Maps iOS Cancel Workout alert
  void _showCancelWorkoutAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Workout?'),
        content: const Text('End this workout? All progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End Workout'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        _cancelWorkout();
      }
    });
  }

  /// Maps iOS WorkoutSessionControls onCancel
  void _onCancelWorkout(BuildContext context) {
    _showCancelWorkoutAlert();
  }

  Future<void> _cancelWorkout() async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    await notifier.cancelWorkout();
    ref.read(sessionOverlayProvider.notifier).hide();
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Maps iOS Save as Template alert
  void _showSaveTemplateAlert() {
    final session = ref.read(activeWorkoutProvider).session;
    _saveTemplateController.text = session?.name ?? 'My Workout';
    setState(() => _showingSaveTemplateAlert = true);
  }

  Future<void> _confirmSaveTemplate() async {
    final name = _saveTemplateController.text.trim();
    if (name.isEmpty) return;

    setState(() => _showingSaveTemplateAlert = false);

    try {
      final notifier = ref.read(activeWorkoutProvider.notifier);
      await notifier.saveSessionAsTemplate(name: name, description: null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "$name" saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save template: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Shows a non-blocking toast at the 2-hour mark to warn the user
  /// about the workout duration. Matches iOS behavior where a banner/toast
  /// appears instead of a blocking dialog.
  void _showTwoHourWarningToast() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "You've been working out for 2 hours. Consider taking a break.",
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  // ===========================================================================
  // Voice Input (iOS voiceLogOverlay equivalent)
  // ===========================================================================

  Future<void> _onVoiceInput(BuildContext context) async {
    final knownExercises =
        ref.read(activeWorkoutProvider).exerciseNames.values.toList();

    // Full exercise library for 6-tier matching (tiers 3/5)
    final libraryExercises = ref
        .read(exerciseLibraryProvider)
        .allExercises
        .map((e) => e.name)
        .toList();

    final parsed = await VoiceInputOverlay.show(
      context,
      service: _voiceLogService,
      knownExercises: knownExercises,
      libraryExercises: libraryExercises,
    );

    if (parsed == null || !mounted) return;

    if (parsed.exerciseName != null) {
      final currentState = ref.read(activeWorkoutProvider);
      final sessionNames = currentState.exerciseNames.entries.toList();

      // Use same 6-tier resolution for post-parse matching
      final matchedName = VoiceLogService.matchSessionExercise(
        parsed.exerciseName!,
        sessionNames.map((e) => e.value).toList(),
      );

      if (matchedName != null) {
        final matchedEntry = sessionNames.firstWhere(
          (e) => e.value == matchedName,
          orElse: () => const MapEntry('', ''),
        );

        if (matchedEntry.key.isNotEmpty) {
          await ref.read(activeWorkoutProvider.notifier).logExercise(
                exerciseId: matchedEntry.key,
                reps: parsed.reps,
                weight: parsed.weight,
              );
          return;
        }
      }
    }
  }

  /// Opens the coach mode overlay (when voiceMode == coach).
  void _openCoachOverlay() {
    showVoiceCoachOverlay(context);
  }

  /// Called when VoiceLogOverlay auto-confirms or user taps "Confirm & Log".
  Future<void> _onVoiceConfirm(ParsedVoiceInput command) async {
    if (command.exerciseName != null) {
      final currentState = ref.read(activeWorkoutProvider);
      final sessionNames = currentState.exerciseNames.entries.toList();
      final sessionNameValues = sessionNames.map((e) => e.value).toList();

      // Use same 6-tier resolution for post-parse matching
      final matchedName = VoiceLogService.matchSessionExercise(
        command.exerciseName!,
        sessionNameValues,
      );

      if (matchedName != null) {
        final matchedEntry = sessionNames.firstWhere(
          (e) => e.value == matchedName,
          orElse: () => const MapEntry('', ''),
        );

        if (matchedEntry.key.isNotEmpty) {
          await ref.read(activeWorkoutProvider.notifier).logExercise(
                exerciseId: matchedEntry.key,
                reps: command.reps,
                weight: command.weight,
              );
        }
      }
    }

    if (mounted) {
      setState(() {
        _voiceOverlayVisible = false;
        _voiceCommandPending = false;
      });
    }
  }

  /// Called when user taps "Change" on the voice command card.
  void _onVoiceChangeExercise(String exerciseName) {
    final exercises =
        ref.read(activeWorkoutProvider).exerciseNames.values.toList();
    _showVoiceCorrectionPicker(exercises, (selected) {
      if (!mounted) return;
      setState(() {
        _voiceOverlayVisible = false;
        _voiceCommandPending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exercise changed to $selected')),
      );
    });
  }

  // ===========================================================================
  // Trainer-led session helpers
  // ===========================================================================

  Future<void> _onStartWorkout() async {
    final state = ref.read(activeWorkoutProvider);
    if (state.hasActiveSession) {
      await _showWorkoutConflictDialog();
    } else {
      await ref.read(activeWorkoutProvider.notifier).startWorkout();
    }
  }

  Future<void> _showWorkoutConflictDialog() async {
    final result = await showDialog<WorkoutConflictAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ongoing Session'),
        content: const Text(
          'You have an ongoing workout session. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, WorkoutConflictAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, WorkoutConflictAction.endAndStart),
            child: const Text('End & Start New'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, WorkoutConflictAction.resume),
            child: const Text('Resume Current'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    switch (result) {
      case WorkoutConflictAction.resume:
        ref.read(sessionOverlayProvider.notifier).showFull();
        break;
      case WorkoutConflictAction.endAndStart:
        await ref.read(activeWorkoutProvider.notifier).cancelWorkout();
        if (!mounted) return;
        await _onStartWorkout();
        break;
      case WorkoutConflictAction.cancel:
        break;
    }
  }

  /// Maps iOS .sheet TemplatePickerView: loads exercises from a template.
  Future<void> _onLoadTemplate() async {
    final template = await TemplatePickerSheet.show(context);
    if (template != null && mounted) {
      final notifier = ref.read(activeWorkoutProvider.notifier);
      await notifier.addExercisesFromTemplate(template.id);
    }
  }

  Future<void> _showClientSelector(BuildContext context) async {
    final notifier = ref.read(clientListProvider.notifier);
    await notifier.fetchClients();

    if (!mounted) return;

    final client = await showDialog<Client>(
      context: context,
      builder: (ctx) => _ClientSelectorDialog(),
    );

    if (client != null && mounted) {
      await _onStartTrainerSession(client);
    }
  }

  Future<void> _onStartTrainerSession(Client client) async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    await notifier.startSessionForClient(
      clientId: client.id,
      clientName: client.name,
    );
  }

  // ===========================================================================
  // Minimize / Drag (iOS dragGesture)
  // ===========================================================================

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0 || _dragOffset.value > 0) {
      _dragOffset.value += details.delta.dy;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset.value > 120 || details.primaryVelocity! > 500) {
      // Velocity-based dismissal (iOS: >500 velocity or >120 offset)
      HapticFeedback.mediumImpact();
      // Animate off-screen
      final screenHeight = MediaQuery.of(context).size.height;
      _dragOffset.value = screenHeight;
      Timer(const Duration(milliseconds: 150), () {
        if (mounted) _minimize();
      });
    } else {
      // Spring animation on snap-back (iOS: spring response 0.4, damping 0.8)
      _dragOffset.value = 0.0;
    }
  }

  void _minimize() {
    HapticFeedback.mediumImpact();
    _minimizeController.forward(
        from: _dragOffset.value / MediaQuery.of(context).size.height);

    // Set overlay state to mini so the mini-player shows up in the shells
    ref.read(sessionOverlayProvider.notifier).showMini();

    if (widget.onMinimize != null) {
      widget.onMinimize!();
      return;
    }

    // Delay navigation slightly to allow the slide-down animation to be visible
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        final auth = ref.read(authProvider);
        if (auth.isTrainer) {
          context.go('/trainer/dashboard');
        } else if (auth.isAdmin) {
          context.go('/admin/dashboard');
        } else {
          context.go('/client/dashboard');
        }
      }
    });
  }

  // ===========================================================================
  // Navigation
  // ===========================================================================

  void _navigateToSummary(
    BuildContext context,
    WorkoutSession session,
    List<ClientExerciseLog> logs,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          session: session,
          logs: logs,
        ),
      ),
    );
  }

  // ===========================================================================
  // Build (ZStack equivalent)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);
    final tc = context.themeColors;

    // ── Listeners (iOS onChange equivalents) ──

    // New record toast listener
    ref.listen<String?>(
      activeWorkoutProvider.select((s) => s.lastNewRecord),
      (previous, next) {
        if (next != null && next.isNotEmpty) {
          WorkoutToastService.showNewRecordToast(context, next);
        }
      },
    );

    // Rest finished toast listener
    ref.listen<bool>(
      activeWorkoutProvider.select((s) => s.showRestTimerFinishedToast),
      (previous, next) {
        if (next == true) {
          WorkoutToastService.showRestFinishedToast(context);
        }
      },
    );

    // Long session warning listener
    // At 2-hour mark: show a non-blocking toast (matching iOS behavior)
    // At 4-hour mark: show the "High Duration Detected" blocking dialog
    ref.listen<bool>(
      activeWorkoutProvider.select((s) => s.showLongSessionWarning),
      (previous, next) {
        if (next == true) {
          final elapsed = ref.read(workoutTimerProvider).elapsed;
          if (elapsed.inHours >= 3) {
            // 4-hour mark: show blocking dialog with "Still Active" / "End Workout"
            _showHighDurationAlert = true;
            setState(() {});
          } else {
            // 2-hour mark: show non-blocking toast
            _showTwoHourWarningToast();
            ref.read(activeWorkoutProvider.notifier).acknowledgeLongSessionWarning();
          }
        }
      },
    );

    // Active video URL → show YouTube sheet (iOS: .sheet(isPresented: Binding(get: { manager.activeVideoUrl != nil })))
    ref.listen<String?>(
      activeWorkoutProvider.select((s) => s.activeVideoUrl),
      (previous, next) {
        if (next != null && next.isNotEmpty && next != previous) {
          _showYouTubeSheet(next);
        }
      },
    );

    // Exercise transition audio cue (iOS VoiceCoachManager behavior):
    // When a new set is added for a different exercise, announce "Next up: [exercise]".
    ref.listen<int>(
      activeWorkoutProvider.select((s) => s.logs.length),
      (previous, next) {
        if (previous == null || next <= previous) return;
        if (next < 2) return; // need at least 2 logs to compare exercises
        final state = ref.read(activeWorkoutProvider);
        final logs = state.logs;
        final newSet = logs.last;
        final previousSet = logs[logs.length - 2];
        if (newSet.exerciseId != previousSet.exerciseId &&
            _lastAnnouncedExerciseId != newSet.exerciseId) {
          _lastAnnouncedExerciseId = newSet.exerciseId;
          final exerciseName =
              state.exerciseNames[newSet.exerciseId] ?? 'Exercise';
          _voiceService.announceNextExercise(
            exerciseName: exerciseName,
            targetWeight: newSet.weight,
            targetReps: newSet.reps,
          );
        }
      },
    );

    // ── ZStack equivalent: Stack ──
    final bodyWidget = ValueListenableBuilder<double>(
      valueListenable: _dragOffset,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: GestureDetector(
        // 1. Background tap dismisses input overlay (iOS: Color.theme.backgroundPrimary.onTapGesture)
        onTap: () {
          if (_inputState.isActive) {
            _syncActiveInput();
          }
          if (_inputState.focusedField != null) {
            setState(() {
              _inputState = _inputState.copyWith(
                focusedField: null,
                overlay: WorkoutInputOverlay.none,
                clearField: true,
              );
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: tc.backgroundPrimary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Main Column: Header + Content (iOS VStack) ──
              Column(
                children: [
                  const SizedBox(height: 12),
                  // Header with drag gesture (iOS: dragGesture on header only)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: Column(
                      children: [
                        // Grabber handle (iOS: Capsule grabberHandle)
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: tc.backgroundTertiary,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                        // Header row
                        Row(
                          children: [
                            // Load template button (iOS: .sheet TemplatePickerView)
                            if (state.hasActiveSession)
                              IconButton(
                                icon: const Icon(Icons.assignment_outlined),
                                iconSize: 20,
                                tooltip: 'Load Template',
                                onPressed: _onLoadTemplate,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            // Coach mode indicator
                            Consumer(
                              builder: (context, ref, _) {
                                final coachMode = ref.watch(
                                  voiceCoachProvider.select(
                                    (s) => s.voiceMode,
                                  ),
                                );
                                if (coachMode == VoiceMode.coach) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F46E5)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            size: 12,
                                            color: Color(0xFF4F46E5),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'AI Coach',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            Expanded(
                              child: WorkoutSessionHeader(
                                onShowRestTimer: () =>
                                    RestTimerSheet.show(context),
                                onMinimize: _minimize,
                                onSaveTemplate: _showSaveTemplateAlert,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content area (iOS WorkoutSessionContent)
                  Expanded(
                    child: Stack(
                      children: [
                        _buildMainContent(state, theme),
                        // Error banner overlay
                        if (state.error != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _buildErrorBanner(theme, state.error!),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Bottom Controls (iOS WorkoutSessionControls) ──
              // Animated opacity: hide when input overlay is active
              if (state.hasActiveSession)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _inputState.isActive ? 0 : 1,
                    child: WorkoutSessionControls(
                      isRecording: _voiceLogService.isListening,
                      onRecordingStart: () {
                        HapticFeedback.lightImpact();
                        _voiceLogService.startListening();
                        setState(() => _voiceOverlayVisible = true);
                      },
                      onRecordingEnd: () {
                        _voiceLogService.stopListening();
                        setState(() => _voiceOverlayVisible = false);
                      },
                      onCoachRecordingStart: () {
                        HapticFeedback.lightImpact();
                        _openCoachOverlay();
                      },
                      onCoachRecordingEnd: () {
                        // Coach overlay is dismissed independently
                      },
                      onFinishPressed: _onFinishButtonPressed,
                      onCancelPressed: () => _onCancelWorkout(context),
                      onOpenVoiceSettings: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const VoiceCoachSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // ── Input Overlay System (iOS inputSystemView) ──
              if (_inputState.isActive)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tappable area to dismiss (iOS: Spacer pushes keyboard)
                      GestureDetector(
                        onTap: _closeInput,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 100,
                          color: Colors.transparent,
                        ),
                      ),
                      // iOS-aligned: backgroundSecondary + shadow
                      Container(
                        decoration: BoxDecoration(
                          color: tc.backgroundSecondary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: _buildCurrentInputView(theme),
                      ),
                    ],
                  ),
                ),

              // ── Voice Log Overlay (iOS voiceLogOverlay, zIndex: 1000) ──
              // Only shown in dictation mode; coach mode uses a dialog overlay.
              if (_voiceOverlayVisible)
                Consumer(
                  builder: (context, ref, _) {
                    final voiceMode = ref.watch(
                      voiceCoachProvider.select((s) => s.voiceMode),
                    );
                    if (voiceMode == VoiceMode.coach) {
                      return const SizedBox.shrink();
                    }
                    return VoiceLogOverlay(
                      service: _voiceLogService,
                      knownExercises: ref
                          .read(activeWorkoutProvider)
                          .exerciseNames
                          .values
                          .toList(),
                      libraryExercises: ref
                          .read(exerciseLibraryProvider)
                          .allExercises
                          .map((e) => e.name)
                          .toList(),
                      onChangeExercise: _onVoiceChangeExercise,
                      onConfirm: _onVoiceConfirm,
                    );
                  },
                ),

              // ── Syncing Overlay (iOS: ProgressView + "Syncing workout..." at zIndex: 100) ──
              Consumer(
                builder: (context, ref, _) {
                  final isSyncing = ref.watch(
                    activeWorkoutProvider.select((s) => s.isSyncingWorkout),
                  );
                  if (!isSyncing) return const SizedBox.shrink();
                  return Stack(
                    children: [
                      // Semi-transparent barrier
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                      // Centered spinner + text
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Syncing workout...',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    // ── Sheets & Alerts (iOS .sheet / .alert modifiers) ──

    // Scaffold for non-overlay mode
    Widget screen;
    if (widget.isOverlay) {
      screen = bodyWidget;
    } else {
      screen = Scaffold(
        backgroundColor: Colors.transparent,
        body: bodyWidget,
      );
    }

    // Wrap with dialogs that are shown reactively
    return _DialogWrapper(
      showEmptyDataAlert: _showEmptyDataAlert,
      onDismissEmptyDataAlert: () =>
          setState(() => _showEmptyDataAlert = false),
      showHighDurationAlert: _showHighDurationAlert,
      onDismissHighDurationAlert: () =>
          setState(() => _showHighDurationAlert = false),
      showSaveTemplateAlert: _showingSaveTemplateAlert,
      saveTemplateController: _saveTemplateController,
      onDismissSaveTemplate: () =>
          setState(() => _showingSaveTemplateAlert = false),
      onConfirmSaveTemplate: _confirmSaveTemplate,
      onEndWorkoutFromHighDuration: () {
        setState(() => _showHighDurationAlert = false);
        ref.read(activeWorkoutProvider.notifier).acknowledgeLongSessionWarning();
        _finishWorkoutDirectly();
      },
      onDismissHighDuration: () {
        setState(() => _showHighDurationAlert = false);
        ref.read(activeWorkoutProvider.notifier).acknowledgeLongSessionWarning();
      },
      child: screen,
    );
  }

  Future<void> _handleFinishOption(
      finish_dialog.FinishOption option) async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    WorkoutSession? finishedSession;

    switch (option) {
      case finish_dialog.FinishOption.completeUnfinished:
        finishedSession =
            await notifier.finishWorkoutWithOption(FinishOption.completeUnfinished);
      case finish_dialog.FinishOption.discardUnfinished:
        finishedSession =
            await notifier.finishWorkoutWithOption(FinishOption.discardUnfinished);
    }

    if (finishedSession != null && mounted) {
      _onWorkoutFinished(finishedSession);
    }
  }

  // ===========================================================================
  // Build helpers
  // ===========================================================================

  Widget _buildMainContent(ActiveWorkoutState state, ThemeData theme) {
    if (state.isLoading && !state.hasActiveSession) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && !state.hasActiveSession) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _initWorkout(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isIdle) {
      return _buildIdleState(theme);
    }

    return EnhancedExerciseListBuilder(
      onAddExercise: () => _showExerciseSelection(context),
      inputState: _inputState,
      onFocus: _triggerInput,
      onWeightChanged: (weight) {
        if (_inputState.activeSetId != null) {
          ref.read(activeWorkoutProvider.notifier).logExercise(
                exerciseId: _inputState.focusedField!.setId,
                weight: weight,
              );
        }
      },
      onRepsChanged: (reps) {
        if (_inputState.activeSetId != null) {
          ref.read(activeWorkoutProvider.notifier).logExercise(
                exerciseId: _inputState.focusedField!.setId,
                reps: reps,
              );
        }
      },
      onRpeChanged: (rpe) {
        if (_inputState.activeSetId != null) {
          ref.read(activeWorkoutProvider.notifier).updateSetRpe(
                _inputState.activeSetId!,
                rpe,
              );
        }
      },
    );
  }

  Widget _buildIdleState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center_outlined,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No active workout', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Start a new workout to begin tracking.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _onStartWorkout(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Workout'),
            ),
            const SizedBox(height: 12),
            if (ref.watch(authProvider).isTrainer)
              OutlinedButton.icon(
                onPressed: () => _showClientSelector(context),
                icon: const Icon(Icons.group_add),
                label: const Text('Start Trainer-Led Session'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String error) {
    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: Text(error),
      leading: Icon(Icons.warning, color: theme.colorScheme.error),
      actions: [
        TextButton(
          onPressed: () =>
              ref.read(activeWorkoutProvider.notifier).clearError(),
          child: const Text('DISMISS'),
        ),
      ],
    );
  }

  /// Maps iOS inputSystemView — switches between keyboard/plate/RPE
  Widget _buildCurrentInputView(ThemeData theme) {
    switch (_inputState.overlay) {
      case WorkoutInputOverlay.keyboard:
        return WorkoutNumericKeyboard(
          key: const ValueKey('keyboard'),
          initialValue: _inputState.activeText,
          inputType: _inputState.focusedField?.isWeight == true
              ? NumericKeyboardInputType.weight
              : NumericKeyboardInputType.reps,
          onChanged: (value) {
            setState(() {
              _inputState = _inputState.copyWith(activeText: value);
            });
          },
          onNext: (_) => _handleInputNext(),
          onDismiss: _closeInput,
          onAction: _inputState.focusedField?.isWeight == true
              ? _switchToPlateCalculator
              : _switchToRpePicker,
        );
      case WorkoutInputOverlay.plateCalculator:
        return Stack(
          children: [
            InteractivePlateCalculator(
              key: const ValueKey('plate'),
              initialWeight:
                  double.tryParse(_inputState.activeText.replaceAll(',', '.')) ??
                      20.0,
              onWeightChanged: _onPlateWeightChanged,
              onDismiss: _switchToKeyboard,
            ),
            // iOS-aligned: keyboard switch button in top-right
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  Icons.keyboard,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _switchToKeyboard,
                tooltip: 'Switch to keyboard',
              ),
            ),
          ],
        );
      case WorkoutInputOverlay.rpePicker:
        return RPEPickerOverlay(
          onSelected: (rpe) {
            if (_inputState.activeSetId != null) {
              ref
                  .read(activeWorkoutProvider.notifier)
                  .updateSetRpe(_inputState.activeSetId!, rpe);
            }
            _closeInput();
          },
          onDismiss: _switchToKeyboard,
        );
      case WorkoutInputOverlay.none:
        return const SizedBox.shrink();
    }
  }

  /// Maps iOS .sheet ExerciseSelectionView
  void _showExerciseSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseSelectionView(
        onExerciseSelected: (exercise, isSelected) {
          if (isSelected) {
            final notifier = ref.read(activeWorkoutProvider.notifier);
            notifier.setExerciseName(exercise.id, exercise.name);
            notifier.logExercise(exerciseId: exercise.id, reps: 0, weight: 0);
            HapticFeedback.lightImpact();
          }
        },
        onDone: (_) {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Maps iOS .sheet manager.activeVideoUrl != nil → YouTubeSheetView
  /// Clears activeVideoUrl when dismissed (iOS parity).
  void _showYouTubeSheet(String videoUrl) {
    YouTubeSheetView.show(context, videoUrl).then((_) {
      if (mounted) {
        ref.read(activeWorkoutProvider.notifier).setActiveVideoUrl(null);
      }
    });
  }

  /// Maps iOS .sheet showVoiceCorrectionPicker → ExerciseSelectionView
  /// with title: "Change Exercise" and hideActionIcons: true.
  void _showVoiceCorrectionPicker(
    List<String> knownExercises,
    void Function(String exerciseName) onSelected,
  ) {
    VoiceCorrectionPicker.show(
      context,
      knownExercises: knownExercises,
      onExerciseSelected: onSelected,
    );
  }
}

// =============================================================================
// _DialogWrapper
//
// Wraps the screen with iOS-aligned alerts that are controlled reactively:
//   - "Complete Session?" (empty data alert)
//   - "High Duration Detected" (4+ hours)
//   - "Save as Template" (TextField alert)
// =============================================================================

class _DialogWrapper extends StatefulWidget {
  final Widget child;
  final bool showEmptyDataAlert;
  final VoidCallback onDismissEmptyDataAlert;
  final bool showHighDurationAlert;
  final VoidCallback onDismissHighDurationAlert;
  final bool showSaveTemplateAlert;
  final TextEditingController saveTemplateController;
  final VoidCallback onDismissSaveTemplate;
  final VoidCallback onConfirmSaveTemplate;
  final VoidCallback onEndWorkoutFromHighDuration;
  final VoidCallback onDismissHighDuration;

  const _DialogWrapper({
    required this.child,
    required this.showEmptyDataAlert,
    required this.onDismissEmptyDataAlert,
    required this.showHighDurationAlert,
    required this.onDismissHighDurationAlert,
    required this.showSaveTemplateAlert,
    required this.saveTemplateController,
    required this.onDismissSaveTemplate,
    required this.onConfirmSaveTemplate,
    required this.onEndWorkoutFromHighDuration,
    required this.onDismissHighDuration,
  });

  @override
  State<_DialogWrapper> createState() => _DialogWrapperState();
}

class _DialogWrapperState extends State<_DialogWrapper> {
  bool _emptyAlertShown = false;
  bool _highDurationShown = false;
  bool _saveTemplateShown = false;

  @override
  void didUpdateWidget(_DialogWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Show "Complete Session?" alert (iOS: showEmptyDataAlert)
    if (widget.showEmptyDataAlert && !_emptyAlertShown) {
      _emptyAlertShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEmptyDataAlert();
      });
    }
    if (!widget.showEmptyDataAlert) {
      _emptyAlertShown = false;
    }

    // Show "High Duration Detected" alert (iOS: manager.showLongSessionWarning)
    if (widget.showHighDurationAlert && !_highDurationShown) {
      _highDurationShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHighDurationAlert();
      });
    }
    if (!widget.showHighDurationAlert) {
      _highDurationShown = false;
    }

    // Show "Save as Template" alert (iOS: showingSaveTemplateAlert)
    if (widget.showSaveTemplateAlert && !_saveTemplateShown) {
      _saveTemplateShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSaveTemplateAlert();
      });
    }
    if (!widget.showSaveTemplateAlert) {
      _saveTemplateShown = false;
    }
  }

  void _showEmptyDataAlert() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Session?'),
        content: const Text(
          "You haven't completed any sets. Please complete at least one set "
          'to finish the workout.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onDismissEmptyDataAlert();
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showHighDurationAlert() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('High Duration Detected'),
        content: const Text(
          "You've been working out for over 4 hours. Is this session "
          'still active?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onDismissHighDuration();
              Navigator.of(ctx).pop();
            },
            child: const Text('Still Active'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              widget.onEndWorkoutFromHighDuration();
              Navigator.of(ctx).pop();
            },
            child: const Text('End Workout'),
          ),
        ],
      ),
    );
  }

  void _showSaveTemplateAlert() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for this workout template.'),
            const SizedBox(height: 16),
            TextField(
              controller: widget.saveTemplateController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onDismissSaveTemplate();
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onConfirmSaveTemplate();
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// =============================================================================
// _ClientSelectorDialog (unchanged — kept for backwards compatibility)
// =============================================================================

class _ClientSelectorDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ClientSelectorDialog> createState() =>
      _ClientSelectorDialogState();
}

class _ClientSelectorDialogState extends ConsumerState<_ClientSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientListProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Select Client'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                ref.read(clientListProvider.notifier).setSearch(value);
              },
            ),
            const SizedBox(height: 12),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (state.filteredClients.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.clients.isEmpty
                      ? 'No clients found.'
                      : 'No matching clients.',
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: state.filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = state.filteredClients[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          client.name.isNotEmpty
                              ? client.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(client.name),
                      subtitle:
                          client.email != null ? Text(client.email!) : null,
                      onTap: () => Navigator.of(context).pop(client),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
