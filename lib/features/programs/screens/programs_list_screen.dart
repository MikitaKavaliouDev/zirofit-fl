import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';

class ProgramsListScreen extends ConsumerStatefulWidget {
  const ProgramsListScreen({super.key});

  @override
  ConsumerState<ProgramsListScreen> createState() => _ProgramsListScreenState();
}

class _ProgramsListScreenState extends ConsumerState<ProgramsListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch programs on initial load if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(programsProvider);
      if (state.programs.isEmpty && !state.isLoading) {
        ref.read(programsProvider.notifier).fetchPrograms();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(programsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
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
        onPressed: () => context.push('/trainer/programs/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ProgramsState state, ThemeData theme) {
    // Loading state (initial load, no data yet)
    if (state.isLoading && state.programs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
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
                onPressed: () => ref.read(programsProvider.notifier).fetchPrograms(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (state.programs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'No programs yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first workout program to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Data state
    return RefreshIndicator(
      onRefresh: () => ref.read(programsProvider.notifier).fetchPrograms(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.programs.length,
        itemBuilder: (context, index) {
          final program = state.programs[index];
          return _ProgramListTile(program: program);
        },
      ),
    );
  }
}

class _ProgramListTile extends StatelessWidget {
  final WorkoutProgram program;

  const _ProgramListTile({required this.program});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(program.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: program.description != null && program.description!.isNotEmpty
            ? Text(
                program.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/trainer/programs/${program.id}'),
      ),
    );
  }
}
