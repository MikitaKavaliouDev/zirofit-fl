import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/clients/providers/client_list_provider.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/screens/workout_summary_screen.dart';
import 'package:zirofit_fl/features/workout/services/voice_feedback_service.dart';
import 'package:zirofit_fl/features/workout/services/voice_log_service.dart';
import 'package:zirofit_fl/features/workout/services/workout_toast_service.dart';
import 'package:zirofit_fl/features/workout/models/workout_focus_state.dart';
import 'package:zirofit_fl/features/workout/widgets/exercise_selection_view.dart';
import 'package:zirofit_fl/features/workout/widgets/enhanced_exercise_list_builder.dart';
import 'package:zirofit_fl/features/workout/widgets/voice_input_overlay.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_numeric_keyboard.dart';
import 'package:zirofit_fl/features/workout/widgets/rpe_picker_overlay.dart';
import 'package:zirofit_fl/features/workout/widgets/rest_timer_sheet.dart';
import 'package:zirofit_fl/features/workout/widgets/interactive_plate_calculator.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_session_header.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_session_controls.dart';

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
    extends ConsumerState<EnhancedActiveWorkoutScreen> with SingleTickerProviderStateMixin {
  final VoiceFeedbackService _voiceService = VoiceFeedbackService();
  final VoiceLogService _voiceLogService = VoiceLogService();

  // Advanced input system state
  WorkoutInputState _inputState = const WorkoutInputState();

  // Drag to dismiss state
  final ValueNotifier<double> _dragOffset = ValueNotifier<double>(0.0);
  late AnimationController _minimizeController;

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
      _updateLogField(_inputState.activeSetId!, weight: numericValue);
    } else if (_inputState.focusedField?.isReps == true) {
      _updateLogField(_inputState.activeSetId!, reps: numericValue.toInt());
    }
  }

  void _updateLogField(String logId, {double? weight, int? reps}) {
    // Note: In production, use proper provider methods.
    // This is a placeholder for local updates if needed.
  }

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

    // Listen for new record changes to show toast
    ref.listen<String?>(activeWorkoutProvider.select((s) => s.lastNewRecord), (previous, next) {
      if (next != null && next.isNotEmpty) {
        WorkoutToastService.showNewRecordToast(context, next);
      }
    });

    // Listen for rest timer start to auto-show rest timer sheet
    ref.listen<bool>(activeWorkoutProvider.select((s) => s.isRestRunning), (previous, next) {
      if (next && !(previous ?? false)) {
        _showRestTimer(context);
      }
    });

    final bodyWidget = ValueListenableBuilder<double>(
      valueListenable: _dragOffset,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            Column(
              children: [
                const SizedBox(height: 12),
                // Header with Drag Gesture
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 0 || _dragOffset.value > 0) {
                      _dragOffset.value += details.delta.dy;
                    }
                  },
                  onVerticalDragEnd: (details) {
                    if (_dragOffset.value > 120 || details.primaryVelocity! > 500) {
                      _minimize();
                    } else {
                      _resetDrag();
                    }
                  },
                  child: WorkoutSessionHeader(
                    onShowRestTimer: () => _showRestTimer(context),
                    onMinimize: _minimize,
                  ),
                ),

                // Main content
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

            // Bottom Controls
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
                    onVoicePressed: () => _onVoiceInput(context),
                    onFinishPressed: () => _onFinishWorkout(context),
                    onCancelPressed: () => _onCancelWorkout(context),
                  ),
                ),
              ),

            // Input overlay (keyboard/plate/RPE)
            if (_inputState.isActive) _buildInputOverlay(theme),
          ],
        ),
      ),
    );

    if (widget.isOverlay) {
      return bodyWidget;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: bodyWidget,
    );
  }

  void _minimize() {
    HapticFeedback.mediumImpact();
    _minimizeController.forward(from: _dragOffset.value / MediaQuery.of(context).size.height);
    
    // Set overlay state to mini so the mini-player shows up in the shells
    ref.read(sessionOverlayProvider.notifier).showMini();
    
    if (widget.onMinimize != null) {
      widget.onMinimize!();
      return;
    }
    
    // Delay navigation slightly to allow the slide-down animation to be visible
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        // Navigate to dashboard based on user role
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

  void _resetDrag() {
    _dragOffset.value = 0.0;
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
          GestureDetector(
            onTap: _closeInput,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 100,
              color: Colors.transparent,
            ),
          ),
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
        return RPEPickerOverlay(
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

  // ---------------------------------------------------------------------------
  // Dialogs & Sheets
  // ---------------------------------------------------------------------------

  void _showRestTimer(BuildContext context) {
    RestTimerSheet.show(context);
  }

  void _showExerciseSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseSelectionView(
        onExerciseSelected: (exercise, isSelected) {
          if (isSelected) {
            // Live background populate
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
        ref.read(sessionOverlayProvider.notifier).hide();
        _voiceService.announceWorkoutComplete();
        if (widget.onFinish != null) {
          widget.onFinish!(finishedSession, currentLogs);
        } else {
          _navigateToSummary(context, finishedSession, currentLogs);
        }
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
      ref.read(sessionOverlayProvider.notifier).hide();
      if (widget.onCancel != null) {
        widget.onCancel!();
      } else if (mounted) {
        Navigator.of(context).pop();
      }
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
