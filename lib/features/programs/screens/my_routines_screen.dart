import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/personal_program.dart';
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
    final library = state.library;
    final assignedPrograms = state.programs;
    final personalPrograms = library?.personalPrograms ?? [];
    final hasAssigned = assignedPrograms.isNotEmpty;
    final hasPersonal = personalPrograms.isNotEmpty;

    // Loading (initial - no library data yet)
    if (state.isLoading && library == null) {
      return _ShimmerList();
    }

    // Error (no data yet)
    if (state.error != null && library == null) {
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

    // Empty (no assigned nor personal programs)
    if (!hasAssigned && !hasPersonal) {
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
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // -- Assigned by Trainer (My Routines) --
          if (hasAssigned) ...[
            const _SectionHeader(title: 'My Routines'),
            ...assignedPrograms.map((routine) => RoutineCard(
              routine: routine,
              onEdit: () => _openBuilder(context, routine: routine),
              onSchedule: () => _openScheduler(context, routine: routine),
            )),
          ],

          // -- Personal Programs (My Programs) --
          if (hasPersonal) ...[
            const _SectionHeader(title: 'My Programs'),
            ...personalPrograms.map(
              (program) => _PersonalProgramCard(
                program: program,
                onTap: () => context.push('/client/programs/${program.id}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openBuilder(
    BuildContext context, {
    WorkoutProgram? routine,
  }) async {
    if (!context.mounted) return;
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => RoutineBuilderScreen(routine: routine),
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine saved')),
      );
      // Refresh to show the new/updated program
      ref.read(clientProgramsProvider.notifier).fetchPrograms();
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
// Section header
// ---------------------------------------------------------------------------

/// Section header label placed above each program section.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Personal program card
// ---------------------------------------------------------------------------

/// Card displaying a personal (self-created) program.
class _PersonalProgramCard extends StatelessWidget {
  final PersonalProgram program;
  final VoidCallback? onTap;

  const _PersonalProgramCard({
    required this.program,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name, badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (program.description != null &&
                            program.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            program.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // "My Program" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'My Program',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Template count
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${program.templates.length} templates',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
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
