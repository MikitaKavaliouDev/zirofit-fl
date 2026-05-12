import 'package:flutter/material.dart';
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
import 'package:zirofit_fl/features/workout/services/workout_toast_service.dart';
import 'package:zirofit_fl/features/workout/widgets/exercise_selection_view.dart';
import 'package:zirofit_fl/features/workout/widgets/exercise_list_builder.dart';
import 'package:zirofit_fl/features/workout/widgets/set_input_sheet.dart';
import 'package:zirofit_fl/features/workout/widgets/voice_input_overlay.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String? templateId;

  const ActiveWorkoutScreen({super.key, this.templateId});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  final VoiceFeedbackService _voiceService = VoiceFeedbackService();
  final VoiceLogService _voiceLogService = VoiceLogService();

  @override
  void initState() {
    super.initState();
    // Schedule the async init to avoid calling during build.
    Future.microtask(() => _initWorkout());
    Future.microtask(() => _voiceService.initialize());
  }

  Future<void> _initWorkout() async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    if (widget.templateId != null) {
      await notifier.startWorkout(templateId: widget.templateId);
    } else {
      await notifier.loadActiveSession();
    }
  }

  @override
  void dispose() {
    _voiceService.stop();
    _voiceLogService.stopListening();
    super.dispose();
  }

  /// Called whenever [ActiveWorkoutState] changes to trigger voice announcements.
  void _onWorkoutStateChanged(ActiveWorkoutState? prev, ActiveWorkoutState next) {
    // Detect rest timer just started
    final wasRestRunning = prev?.isRestRunning ?? false;
    if (next.isRestRunning && !wasRestRunning && next.restSeconds > 0) {
      _voiceService.announceRestTimer(next.restSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);

    // Listen to state transitions for voice announcements
    ref.listen<ActiveWorkoutState>(activeWorkoutProvider, _onWorkoutStateChanged);

    // Listen for new record changes to show toast
    ref.listen<String?>(activeWorkoutProvider.select((s) => s.lastNewRecord), (previous, next) {
      if (next != null && next.isNotEmpty) {
        WorkoutToastService.showNewRecordToast(context, next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.session?.name ?? 'Active Workout',
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          // Speaker toggle
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
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(ActiveWorkoutState state, ThemeData theme) {
    // Loading state
    if (state.isLoading && !state.hasActiveSession) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no session
    if (state.error != null && !state.hasActiveSession) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
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

    // Idle — no active session
    if (state.isIdle) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No active workout',
                style: theme.textTheme.titleLarge,
              ),
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

    // Active workout
    return Column(
      children: [
        // Error banner (non-blocking)
        if (state.error != null)
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            content: Text(state.error!),
            leading: Icon(Icons.warning, color: theme.colorScheme.error),
            actions: [
              TextButton(
                onPressed: () =>
                    ref.read(activeWorkoutProvider.notifier).clearError(),
                child: const Text('DISMISS'),
              ),
            ],
          ),

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

        // Trainer-led session indicator
        if (state.isTrainerLed)
          _TrainerLedHeader(clientName: state.clientName!),

        // Main content
        Expanded(
          child: ExerciseListBuilder(
            onAddExercise: () => _showExerciseSelection(context),
          ),
        ),

        // Bottom action bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Voice + Add set row
                Row(
                  children: [
                    // Microphone button
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: FilledButton.tonal(
                        onPressed: () => _onVoiceInput(context),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.mic),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add set button (fills remaining width)
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
                const SizedBox(height: 8),
                // Finish workout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: state.isLoading ? null : () => _onFinishWorkout(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Finish Workout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

  void _handleSelectedExercises(
      List<Exercise> exercises, BuildContext context) {
    if (exercises.isEmpty) return;

    final notifier = ref.read(activeWorkoutProvider.notifier);

    // Store exercise names for display in log
    for (final exercise in exercises) {
      notifier.setExerciseName(exercise.id, exercise.name);
    }

    // Show SetInputSheet for each exercise
    _showNextSetInput(context, exercises, 0);
  }

  void _showNextSetInput(
      BuildContext context, List<Exercise> exercises, int index) {
    if (index >= exercises.length) return;

    final exercise = exercises[index];

      SetInputSheet.show(
      context,
      exercise: exercise,
      onLog: ({required int reps, double? weight, String? side}) {
        final notifier = ref.read(activeWorkoutProvider.notifier);
        notifier.logExercise(
          exerciseId: exercise.id,
          reps: reps,
          weight: weight,
        );
        // Voice feedback: announce the logged set
        _voiceService.speakConfirmation(
          exerciseName: exercise.name,
          reps: reps,
          weight: weight,
        );
        // After logging, immediately show next exercise's input
        if (index + 1 < exercises.length) {
          _showNextSetInput(context, exercises, index + 1);
        }
      },
    );
  }

  Future<void> _onFinishWorkout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout'),
        content: const Text(
          'Are you sure you want to finish this workout?',
        ),
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
      // Capture logs before finishing (finishWorkout clears state)
      final state = ref.read(activeWorkoutProvider);
      final currentLogs = state.logs.toList();
      final exerciseNames = state.exerciseNames;

      // Enrich logs with exercise names from provider state
      // (ensures names survive API response replacement in completeSet)
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

      final notifier = ref.read(activeWorkoutProvider.notifier);
      final finishedSession = await notifier.finishWorkout();
      if (finishedSession != null && mounted) {
        // Voice feedback: announce workout complete
        _voiceService.announceWorkoutComplete();
        // ignore: use_build_context_synchronously
        _navigateToSummary(context, finishedSession, enrichedLogs);
      }
    }
  }

  Future<void> _onCancelWorkout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Workout'),
        content: const Text(
          'Are you sure you want to cancel this workout? '
          'All progress will be lost.',
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
      if (mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
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

  Future<void> _onStartWorkout() async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    await notifier.startWorkout();

    // If started from a template, populate exercise names for display
    if (widget.templateId != null && mounted) {
      // Template exercises are populated when available through the exercise
      // selection flow or via the template's exercise list.
    }
  }

  // ---------------------------------------------------------------------------
  // Trainer-Led Session
  // ---------------------------------------------------------------------------

  Future<void> _showClientSelector(BuildContext context) async {
    // Fetch clients and show a selection dialog
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

  // ---------------------------------------------------------------------------
  // Voice Input
  // ---------------------------------------------------------------------------

  Future<void> _onVoiceInput(BuildContext context) async {
    // Use exercise names already known in the session to help NLP matching
    final knownExercises =
        ref.read(activeWorkoutProvider).exerciseNames.values.toList();

    final parsed = await VoiceInputOverlay.show(
      context,
      service: _voiceLogService,
      knownExercises: knownExercises,
    );

    if (parsed == null || !mounted) return;

    // Log the recognised set using the first known exercise if a name was
    // recognised, or fall back to the exercise selection flow.
    if (parsed.exerciseName != null) {
      // Try to match the recognised name to a known exercise ID
      final state = ref.read(activeWorkoutProvider);
      final matchedEntry = state.exerciseNames.entries.firstWhere(
        (e) =>
            e.value.toLowerCase() == parsed.exerciseName!.toLowerCase(),
        orElse: () => const MapEntry('', ''),
      );

      if (matchedEntry.key.isNotEmpty) {
        // Found a matching exercise — log directly
        await ref.read(activeWorkoutProvider.notifier).logExercise(
              exerciseId: matchedEntry.key,
              reps: parsed.reps,
              weight: parsed.weight,
            );
        return;
      }
    }

    // No exercise name matched — fall back to the exercise selection sheet so
    // the user can pick which exercise this set belongs to.
    if (!mounted) return;
    _showExerciseSelectionWithPreFill(context, parsed);
  }

  void _showExerciseSelectionWithPreFill(
    BuildContext context,
    ParsedVoiceInput parsed,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExerciseSelectionView(
        onDone: (selectedExercises) {
          if (selectedExercises.isEmpty) return;
          final notifier = ref.read(activeWorkoutProvider.notifier);
          for (final exercise in selectedExercises) {
            notifier.setExerciseName(exercise.id, exercise.name);
          }
          // Log the set against the first selected exercise with voice data
          final exercise = selectedExercises.first;
          notifier.logExercise(
            exerciseId: exercise.id,
            reps: parsed.reps,
            weight: parsed.weight,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trainer-Led Header
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
            Icon(
              Icons.person,
              color: theme.colorScheme.onPrimaryContainer,
            ),
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
                color: theme.colorScheme.onPrimaryContainer.withAlpha(25),
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

// ---------------------------------------------------------------------------
// Client Selector Dialog
// ---------------------------------------------------------------------------

class _ClientSelectorDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ClientSelectorDialog> createState() =>
      _ClientSelectorDialogState();
}

class _ClientSelectorDialogState
    extends ConsumerState<_ClientSelectorDialog> {
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
            state.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                : state.filteredClients.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.clients.isEmpty
                              ? 'No clients found.'
                              : 'No matching clients.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: state.filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = state.filteredClients[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Text(
                                  client.name.isNotEmpty
                                      ? client.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(client.name),
                              subtitle: client.email != null
                                  ? Text(
                                      client.email!,
                                      style: theme.textTheme.bodySmall,
                                    )
                                  : null,
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

// ---------------------------------------------------------------------------
// Rest Timer Card
// ---------------------------------------------------------------------------

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
                Icon(
                  Icons.timer_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rest Timer',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                // Timer display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
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
            // Start / End buttons
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
