import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/programs/providers/program_assignment_provider.dart';

class AssignProgramScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final String? clientAvatarPath;

  const AssignProgramScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    this.clientAvatarPath,
  });

  @override
  ConsumerState<AssignProgramScreen> createState() =>
      _AssignProgramScreenState();
}

class _AssignProgramScreenState extends ConsumerState<AssignProgramScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(programAssignmentProvider.notifier).fetchPrograms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(programAssignmentProvider);
    final theme = Theme.of(context);

    ref.listen<ProgramAssignmentState>(programAssignmentProvider, (prev, next) {
      // On successful assignment, pop with a result
      if (next.assignSuccess && prev?.assignSuccess != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }

      // Show error snackbar if not already shown
      if (next.hasError && prev?.hasError != true) {
        // Only show errors not related to assigning (those are shown in dialog)
        if (!next.isAssigning) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Program'),
      ),
      body: Column(
        children: [
          // Client info header
          _ClientInfoHeader(
            name: widget.clientName,
            avatarPath: widget.clientAvatarPath,
          ),
          const Divider(height: 1),

          // Program list
          Expanded(
            child: _buildBody(state, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ProgramAssignmentState state, ThemeData theme) {
    if (state.isLoading && state.programs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.programs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(programAssignmentProvider.notifier).fetchPrograms(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.programs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center,
                  size: 64, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'No programs available',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a workout program first before assigning it to a client.',
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

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(programAssignmentProvider.notifier).fetchPrograms(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.programs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final program = state.programs[index];
          return _ProgramCard(
            program: program,
            isAssigning: state.isAssigning,
            onAssign: () => _confirmAssign(context, program),
          );
        },
      ),
    );
  }

  void _confirmAssign(BuildContext context, WorkoutProgram program) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Assign Program'),
          content: Text(
            'Assign "${program.name}" to ${widget.clientName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _doAssign(program);
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _doAssign(WorkoutProgram program) async {
    final error = await ref
        .read(programAssignmentProvider.notifier)
        .assignProgram(
          programId: program.id,
          clientId: widget.clientId,
        );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Client Info Header
// ---------------------------------------------------------------------------

class _ClientInfoHeader extends StatelessWidget {
  final String name;
  final String? avatarPath;

  const _ClientInfoHeader({
    required this.name,
    this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage:
                avatarPath != null && avatarPath!.isNotEmpty ? NetworkImage(avatarPath!) : null,
            child: avatarPath == null || avatarPath!.isEmpty
                ? Text(
                    _initials(name),
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigning program to',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  name,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ---------------------------------------------------------------------------
// Program Card
// ---------------------------------------------------------------------------

class _ProgramCard extends StatelessWidget {
  final WorkoutProgram program;
  final bool isAssigning;
  final VoidCallback onAssign;

  const _ProgramCard({
    required this.program,
    required this.isAssigning,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatted =
        DateFormat('MMM dd, yyyy').format(program.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Leading icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),

            // Program info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (program.description != null &&
                      program.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      program.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Created $dateFormatted',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Assign button
            FilledButton.tonal(
              onPressed: isAssigning ? null : onAssign,
              child: isAssigning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}
