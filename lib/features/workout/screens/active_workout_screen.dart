import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String? templateId;

  const ActiveWorkoutScreen({super.key, this.templateId});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _exerciseIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Schedule the async init to avoid calling during build.
    Future.microtask(() => _initWorkout());
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
    _repsController.dispose();
    _weightController.dispose();
    _exerciseIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.session?.name ?? 'Active Workout',
          style: theme.textTheme.titleMedium,
        ),
        actions: [
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

        // Main content
        Expanded(
          child: state.logs.isEmpty
              ? _buildEmptyLog(theme)
              : _buildExerciseLog(state.logs, theme),
        ),

        // Bottom action bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add set button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showAddSetDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Set'),
                  ),
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

  Widget _buildEmptyLog(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Log your first set',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Set" to log an exercise with weight and reps.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseLog(List<ClientExerciseLog> logs, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isCompleted = log.isCompleted ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            title: Text(
              _formatExerciseName(log),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${log.weight != null ? '${log.weight!.toStringAsFixed(1)} kg' : '—'} × '
              '${log.reps != null ? '${log.reps} reps' : '—'}'
              '${log.side != 'BOTH' ? ' (${log.side})' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: isCompleted
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : IconButton(
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Complete set',
                    onPressed: () =>
                        ref.read(activeWorkoutProvider.notifier).completeSet(log.id),
                  ),
          ),
        );
      },
    );
  }

  String _formatExerciseName(ClientExerciseLog log) {
    // Use the exercise ID as a placeholder since we might not have the name.
    // In a full implementation, we'd look up the Exercise model.
    return 'Exercise: ${log.exerciseId.substring(0, 8)}…';
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showAddSetDialog(BuildContext context) {
    _repsController.clear();
    _weightController.clear();
    _exerciseIdController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Exercise Set'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _exerciseIdController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise ID',
                    hintText: 'Enter exercise ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'e.g. 50',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _repsController,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    hintText: 'e.g. 10',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                ref.read(activeWorkoutProvider.notifier).logExercise(
                      exerciseId: _exerciseIdController.text.trim(),
                      reps:
                          int.tryParse(_repsController.text.trim()),
                      weight: double.tryParse(
                          _weightController.text.trim()),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Log Set'),
          ),
        ],
      ),
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
      final notifier = ref.read(activeWorkoutProvider.notifier);
      final finishedSession = await notifier.finishWorkout();
      if (finishedSession != null && mounted) {
        // ignore: use_build_context_synchronously
        _navigateToSummary(context, finishedSession);
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

  void _navigateToSummary(BuildContext context, dynamic session) {
    // For now, pop back. In the full app this would navigate to a summary screen.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Workout completed: ${session.name ?? 'Finished'}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  void _onStartWorkout() {
    ref.read(activeWorkoutProvider.notifier).startWorkout();
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
