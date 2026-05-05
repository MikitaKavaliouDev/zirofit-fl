import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';
import 'package:zirofit_fl/features/programs/widgets/routine_card.dart';
import 'package:zirofit_fl/features/programs/screens/routine_builder_screen.dart';
import 'package:zirofit_fl/features/programs/screens/routine_scheduler_screen.dart';

/// Client-facing screen that displays all routines (programs).
///
/// Lists routines from [clientProgramsProvider] with pull-to-refresh,
/// loading shimmer, empty state, and error handling.
class MyRoutinesScreen extends ConsumerStatefulWidget {
  const MyRoutinesScreen({super.key});

  @override
  ConsumerState<MyRoutinesScreen> createState() => _MyRoutinesScreenState();
}

class _MyRoutinesScreenState extends ConsumerState<MyRoutinesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(clientProgramsProvider);
      if (state.programs.isEmpty && !state.isLoading) {
        ref.read(clientProgramsProvider.notifier).fetchPrograms();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientProgramsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routines'),
        actions: [
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _buildBody(state, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBuilder(context),
        heroTag: 'create_routine',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ClientProgramsState state, ThemeData theme) {
    // Loading (initial)
    if (state.isLoading && state.programs.isEmpty) {
      return _ShimmerList();
    }

    // Error (no data)
    if (state.error != null && state.programs.isEmpty) {
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
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(clientProgramsProvider.notifier).fetchPrograms(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty
    if (state.programs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No routines yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first routine!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _openBuilder(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Routine'),
              ),
            ],
          ),
        ),
      );
    }

    // Data
    return RefreshIndicator(
      onRefresh: () => ref.read(clientProgramsProvider.notifier).fetchPrograms(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.programs.length,
        itemBuilder: (context, index) {
          final routine = state.programs[index];
          return RoutineCard(
            routine: routine,
            onEdit: () => _openBuilder(context, routine: routine),
            onSchedule: () => _openScheduler(context, routine: routine),
          );
        },
      ),
    );
  }

  Future<void> _openBuilder(
    BuildContext context, {
    WorkoutProgram? routine,
  }) async {
    if (!context.mounted) return;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => RoutineBuilderScreen(routine: routine),
      ),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Routine "${result['name']}" saved')),
      );
    }
  }

  Future<void> _openScheduler(
    BuildContext context, {
    required WorkoutProgram routine,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutineSchedulerScreen(routine: routine),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading list
// ---------------------------------------------------------------------------

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title placeholder
                Container(
                  width: 180,
                  height: 16,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Description placeholder
                Container(
                  width: 240,
                  height: 12,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Chips row
                Row(
                  children: List.generate(
                    3,
                    (_) => Container(
                      width: 60,
                      height: 24,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
