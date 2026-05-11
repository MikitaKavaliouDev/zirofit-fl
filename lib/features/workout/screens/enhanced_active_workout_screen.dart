import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/clients/providers/client_list_provider.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/screens/workout_summary_screen.dart';
import 'package:zirofit_fl/features/workout/services/voice_feedback_service.dart';
import 'package:zirofit_fl/features/workout/services/voice_log_service.dart';
import 'package:zirofit_fl/features/workout/models/workout_focus_state.dart';
import 'package:zirofit_fl/features/workout/widgets/exercise_selection_view.dart';
import 'package:zirofit_fl/features/workout/widgets/enhanced_exercise_list_builder.dart';
import 'package:zirofit_fl/features/workout/widgets/voice_input_overlay.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_numeric_keyboard.dart';
import 'package:zirofit_fl/features/workout/widgets/rpe_picker_overlay.dart';
import 'package:zirofit_fl/features/workout/widgets/interactive_plate_calculator.dart';

/// Enhanced ActiveWorkoutScreen with advanced input system
/// matching iOS WorkoutSessionView.swift
///
/// Features:
/// - Advanced input system (keyboard/plate/RPE overlay)
/// - Focus-based field navigation
/// - Inline set editing with EnhancedExerciseListBuilder
/// - Rest timer card matching iOS header
/// - Trainer-led session header
/// - Voice input integration
class EnhancedActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String? templateId;

  const EnhancedActiveWorkoutScreen({super.key, this.templateId});

  @override
  ConsumerState<EnhancedActiveWorkoutScreen> createState() =>
      _EnhancedActiveWorkoutScreenState();
}

class _EnhancedActiveWorkoutScreenState
    extends ConsumerState<EnhancedActiveWorkoutScreen> {
  final VoiceFeedbackService _voiceService = VoiceFeedbackService();
  final VoiceLogService _voiceLogService = VoiceLogService();

  // Advanced input system state
  WorkoutInputState _inputState = const WorkoutInputState();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initWorkout());
    Future.microtask(() => _voiceService.initialize());
  }

  @override
  void dispose() {
    _voiceService.stop();
    _voiceLogService.stopListening();
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

  // ---------------------------------------------------------------------------
  // Input System Handlers
  // ---------------------------------------------------------------------------

  void _triggerInput(SessionFocusField field) {
    setState(() {
      _inputState = _inputState.copyWith(
        overlay: WorkoutInputOverlay.keyboard,
        focusedField: field,
        activeSetId: field.setId,
        activeText: _getCurrentValue(field),
        isInputSelected: false,
      );
    });
  }

  String _getCurrentValue(SessionFocusField field) {
    final state = ref.read(activeWorkoutProvider);
    // Find the set value
    for (final log in state.logs) {
      if (log.id == field.setId) {
        if (field.isWeight) {
          return log.weight?.toStringAsFixed(1) ?? '';
        } else if (field.isReps) {
          return log.reps?.toString() ?? '';
        }
      }
    }
    return '';
  }

  void _syncActiveInput() {
    if (!_inputState.isActive || _inputState.activeSetId == null) return;

    final value = _inputState.activeText.replaceAll(',', '.');
    final numericValue = double.tryParse(value) ?? 0;

    if (_inputState.focusedField?.isWeight == true) {
      ref.read(activeWorkoutProvider.notifier).updateSetRpe(
            _inputState.activeSetId!,
            numericValue,
          );
      // Update weight in the log
      _updateLogField(_inputState.activeSetId!, weight: numericValue);
    } else if (_inputState.focusedField?.isReps == true) {
      _updateLogField(_inputState.activeSetId!, reps: numericValue.toInt());
    }
  }

  void _updateLogField(String logId, {double? weight, int? reps}) {
    final state = ref.read(activeWorkoutProvider);
    final updatedLogs = state.logs.map((log) {
      if (log.id == logId) {
        return ClientExerciseLog(
          id: log.id,
          clientId: log.clientId,
          exerciseId: log.exerciseId,
          reps: reps ?? log.reps,
          weight: weight ?? log.weight,
          isCompleted: log.isCompleted,
          order: log.order,
          side: log.side,
          workoutSessionId: log.workoutSessionId,
          supersetKey: log.supersetKey,
          orderInSuperset: log.orderInSuperset,
          sets: log.sets,
          rpe: log.rpe,
          rir: log.rir,
          exerciseName: log.exerciseName,
          createdAt: log.createdAt,
          updatedAt: DateTime.now(),
          deletedAt: log.deletedAt,
        );
      }
      return log;
    }).toList();
    // Note: This is a local update only. In production, use proper provider methods.
  }

  void _handleInputNext() {
    _syncActiveInput();

    final current = _inputState.focusedField;
    if (current != null) {
      if (current.isWeight) {
        // Move to reps
        setState(() {
          _inputState = _inputState.copyWith(
            focusedField: SessionFocusField.reps(current.setId),
            activeText: _getCurrentValue(SessionFocusField.reps(current.setId)),
          );
        });
      } else if (current.isReps) {
        // Find next set or close
        final nextSetId = _findNextSetId(current.setId);
        if (nextSetId != null) {
          setState(() {
            _inputState = _inputState.copyWith(
              focusedField: SessionFocusField.weight(nextSetId),
              activeSetId: nextSetId,
              activeText: _getCurrentValue(SessionFocusField.weight(nextSetId)),
            );
          });
        } else {
          _closeInput();
        }
      }
    }
  }

  String? _findNextSetId(String currentSetId) {
    final state = ref.read(activeWorkoutProvider);
    final allLogs = state.logs;
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

  void _switchToPlateCalculator() {
    setState(() {
      _inputState = _inputState.copyWith(
        overlay: WorkoutInputOverlay.plateCalculator,
      );
    });
  }

  void _switchToRpePicker() {
    setState(() {
      _inputState = _inputState.copyWith(
        overlay: WorkoutInputOverlay.rpePicker,
      );
    });
  }

  void _switchToKeyboard() {
    setState(() {
      _inputState = _inputState.copyWith(
        overlay: WorkoutInputOverlay.keyboard,
      );
    });
  }

  void _onPlateWeightChanged(double weight) {
    _syncActiveInput();
    setState(() {
      _inputState = _inputState.copyWith(
        activeText: weight.toStringAsFixed(1),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme, state),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Error banner
              if (state.error != null)
                _buildErrorBanner(theme, state.error!),

              // Rest timer card
              if (state.isRestRunning || state.restSeconds > 0)
                _RestTimerCard(
                  restSeconds: state.restSeconds,
                  isRunning: state.isRestRunning,
                  onStartRest: () =>
                      ref.read(activeWorkoutProvider.notifier).startRest(),
                  onEndRest: () =>
                      ref.read(activeWorkoutProvider.notifier).endRest(),
                ),

              // Trainer-led header
              if (state.isTrainerLed)
                _TrainerLedHeader(clientName: state.clientName ?? 'Client'),

              // Main exercise list
              Expanded(
                child: _buildMainContent(state, theme),
              ),

              // Bottom action bar
              if (state.hasActiveSession) _buildBottomBar(theme),
            ],
          ),

          // Input overlay (keyboard/plate/RPE)
          if (_inputState.isActive) _buildInputOverlay(theme),

          // Rest timer toast
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ActiveWorkoutState state) {
    return AppBar(
      title: Text(
        state.session?.name ?? 'Active Workout',
        style: theme.textTheme.titleMedium,
      ),
      actions: [
        if (state.hasActiveSession)
          IconButton(
            icon: Icon(
              _voiceService.isEnabled
                  ? Icons.volume_up
                  : Icons.volume_off,
            ),
            tooltip: _voiceService.isEnabled
                ? 'Mute voice feedback'
                : 'Enable voice feedback',
            onPressed: () {
              setState(() {
                _voiceService.setEnabled(!_voiceService.isEnabled);
              });
            },
          ),
        if (state.hasActiveSession)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel workout',
            onPressed: () => _onCancelWorkout(context),
          ),
      ],
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
          _updateLogField(_inputState.activeSetId!, weight: weight);
        }
      },
      onRepsChanged: (reps) {
        if (_inputState.activeSetId != null) {
          _updateLogField(_inputState.activeSetId!, reps: reps);
        }
      },
      onRpeChanged: (rpe) {
        if (_inputState.activeSetId != null) {
          ref.read(activeWorkoutProvider.notifier).updateSetRpe(_inputState.activeSetId!, rpe);
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
            Icon(Icons.fitness_center_outlined, size: 64, color: theme.colorScheme.primary),
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

  Widget _buildInputOverlay(ThemeData theme) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dismiss area
          GestureDetector(
            onTap: _closeInput,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 100,
              color: Colors.transparent,
            ),
          ),
          // Input view
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildCurrentInputView(theme),
          ),
        ],
      ),
    );
  }

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
        return InteractivePlateCalculator(
          key: const ValueKey('plate'),
          initialWeight: double.tryParse(_inputState.activeText) ?? 20.0,
          onWeightChanged: _onPlateWeightChanged,
          onDismiss: _switchToKeyboard,
        );
      case WorkoutInputOverlay.rpePicker:
        return _RpePickerWrapper(
          key: const ValueKey('rpe'),
          onSelected: (rpe) {
            if (_inputState.activeSetId != null) {
              ref.read(activeWorkoutProvider.notifier).updateSetRpe(_inputState.activeSetId!, rpe);
            }
            _closeInput();
          },
          onDismiss: _switchToKeyboard,
        );
      case WorkoutInputOverlay.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            // Mic button
            SizedBox(
              width: 56,
              height: 56,
              child: FilledButton.tonal(
                onPressed: () => _onVoiceInput(context),
                style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                child: const Icon(Icons.mic),
              ),
            ),
            const SizedBox(width: 12),
            // Add set button
            Expanded(
              child: SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => _showExerciseSelection(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Set'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showExerciseSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExerciseSelectionView(
        onDone: (selectedExercises) {
          _handleSelectedExercises(selectedExercises, context);
        },
      ),
    );
  }

  void _handleSelectedExercises(List<Exercise> exercises, BuildContext context) {
    if (exercises.isEmpty) return;
    final notifier = ref.read(activeWorkoutProvider.notifier);
    for (final exercise in exercises) {
      notifier.setExerciseName(exercise.id, exercise.name);
      notifier.logExercise(exerciseId: exercise.id);
    }
  }

  Future<void> _onFinishWorkout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout'),
        content: const Text('Are you sure you want to finish this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final currentLogs = ref.read(activeWorkoutProvider).logs.toList();
      final notifier = ref.read(activeWorkoutProvider.notifier);
      final finishedSession = await notifier.finishWorkout();
      if (finishedSession != null && mounted) {
        _voiceService.announceWorkoutComplete();
        _navigateToSummary(context, finishedSession, currentLogs);
      }
    }
  }

  Future<void> _onCancelWorkout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Workout'),
        content: const Text(
          'Are you sure you want to cancel this workout? All progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Working'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel Workout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(activeWorkoutProvider.notifier);
      await notifier.cancelWorkout();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _onStartWorkout() async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    await notifier.startWorkout();
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

  Future<void> _onVoiceInput(BuildContext context) async {
    final knownExercises =
        ref.read(activeWorkoutProvider).exerciseNames.values.toList();

    final parsed = await VoiceInputOverlay.show(
      context,
      service: _voiceLogService,
      knownExercises: knownExercises,
    );

    if (parsed == null || !mounted) return;

    if (parsed.exerciseName != null) {
      final state = ref.read(activeWorkoutProvider);
      final matchedEntry = state.exerciseNames.entries.firstWhere(
        (e) => e.value.toLowerCase() == parsed.exerciseName!.toLowerCase(),
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
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _TrainerLedHeader extends StatelessWidget {
  final String clientName;

  const _TrainerLedHeader({required this.clientName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trainer-Led Session',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Training: $clientName',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'LIVE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestTimerCard extends StatelessWidget {
  final int restSeconds;
  final bool isRunning;
  final VoidCallback onStartRest;
  final VoidCallback onEndRest;

  const _RestTimerCard({
    required this.restSeconds,
    required this.isRunning,
    required this.onStartRest,
    required this.onEndRest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = restSeconds ~/ 60;
    final seconds = restSeconds % 60;
    const totalRest = 90;
    final progress = restSeconds / totalRest;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Rest Timer', style: theme.textTheme.titleSmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.5
                      ? theme.colorScheme.primary
                      : progress > 0.25
                          ? Colors.orange
                          : theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isRunning)
                  FilledButton.tonalIcon(
                    onPressed: onStartRest,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: onEndRest,
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('End'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RpePickerWrapper extends StatelessWidget {
  final void Function(double rpe) onSelected;
  final VoidCallback onDismiss;
  final Key? key;

  const _RpePickerWrapper({
    this.key,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: onDismiss,
                child: const Text('Cancel'),
              ),
              const Spacer(),
              Text(
                'Select RPE',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              const SizedBox(width: 60),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 11,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final rpe = 10.0 - (index * 0.5);
                return GestureDetector(
                  onTap: () => onSelected(rpe),
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rpe.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _rpeDescription(rpe),
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _rpeDescription(double rpe) {
    if (rpe >= 10) return 'Max';
    if (rpe >= 9) return '1 rep left';
    if (rpe >= 8) return '2 reps left';
    if (rpe >= 7) return '3 reps left';
    if (rpe >= 6) return '4+ reps left';
    return 'Warm up';
  }
}

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
                  state.clients.isEmpty ? 'No clients found.' : 'No matching clients.',
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
                          client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(client.name),
                      subtitle: client.email != null ? Text(client.email!) : null,
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
