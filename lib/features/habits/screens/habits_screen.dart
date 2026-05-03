import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/daily_habit.dart';
import 'package:zirofit_fl/features/habits/providers/habits_provider.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  /// Tracks which habit IDs are checked for today (local optimistic state).
  final Set<String> _completedToday = {};

  @override
  void initState() {
    super.initState();
    // Fetch habits on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitsProvider.notifier).fetchHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(HabitsState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.habits.isEmpty) {
      return _ErrorView(
        error: state.error!,
        onRetry: () => ref.read(habitsProvider.notifier).fetchHabits(),
      );
    }

    if (state.habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your trainer will assign habits for you.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final completedCount = _completedToday.length;
    final totalCount = state.habits.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return RefreshIndicator(
      onRefresh: () => ref.read(habitsProvider.notifier).fetchHabits(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ---- Progress section ----
          _ProgressCard(
            completedCount: completedCount,
            totalCount: totalCount,
            progress: progress,
          ),
          const SizedBox(height: 8),

          // ---- Saving indicator ----
          if (state.isSaving)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),

          // ---- Error banner ----
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),

          // ---- Habit list ----
          ...state.habits.map(
            (habit) => _HabitTile(
              habit: habit,
              isChecked: _completedToday.contains(habit.id),
              onToggle: (checked) => _toggleHabit(habit, checked),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleHabit(DailyHabit habit, bool checked) {
    setState(() {
      if (checked) {
        _completedToday.add(habit.id);
      } else {
        _completedToday.remove(habit.id);
      }
    });

    ref.read(habitsProvider.notifier).logHabit(
          habit.id,
          DateTime.now(),
          checked,
        );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ProgressCard extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final double progress;

  const _ProgressCard({
    required this.completedCount,
    required this.totalCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Today's Progress",
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '$completedCount / $totalCount',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final DailyHabit habit;
  final bool isChecked;
  final ValueChanged<bool> onToggle;

  const _HabitTile({
    required this.habit,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          habit.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            decoration:
                isChecked ? TextDecoration.lineThrough : null,
            color: isChecked
                ? theme.colorScheme.onSurfaceVariant
                : null,
          ),
        ),
        subtitle: habit.description != null
            ? Text(habit.description!)
            : null,
        value: isChecked,
        onChanged: onToggle,
        secondary: Icon(
          isChecked ? Icons.check_circle : Icons.check_circle_outline,
          color: isChecked
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load habits',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
