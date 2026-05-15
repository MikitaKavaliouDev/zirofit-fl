import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/active_program_progress.dart';
import 'package:zirofit_fl/data/models/active_program_template.dart';
import 'package:zirofit_fl/data/models/enums/template_step_status.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';

/// Screen displaying the client's currently active assigned program
/// with per-template progress and the ability to switch programs.
class ClientActiveProgramScreen extends ConsumerStatefulWidget {
  const ClientActiveProgramScreen({super.key});

  @override
  ConsumerState<ClientActiveProgramScreen> createState() =>
      _ClientActiveProgramScreenState();
}

class _ClientActiveProgramScreenState
    extends ConsumerState<ClientActiveProgramScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(clientProgramsProvider);
      if (state.activeProgramResponse == null && !state.isLoading) {
        ref.read(clientProgramsProvider.notifier).fetchActiveProgram();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientProgramsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Program'),
        actions: [
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref
                    .read(clientProgramsProvider.notifier)
                    .fetchActiveProgram(),
          ),
        ],
      ),
      body: _buildBody(state, theme, colorScheme),
    );
  }

  // ---------------------------------------------------------------------------
  // Body router
  // ---------------------------------------------------------------------------

  Widget _buildBody(
    ClientProgramsState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Loading (initial, no data yet)
    if (state.isLoading && state.activeProgramResponse == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error (no data)
    if (state.error != null && state.activeProgramResponse == null) {
      return _ErrorView(
        error: state.error!,
        onRetry: () =>
            ref.read(clientProgramsProvider.notifier).fetchActiveProgram(),
      );
    }

    // No active program (response is null, no error, not loading)
    if (state.activeProgramResponse == null) {
      return _EmptyView();
    }

    // Data
    final response = state.activeProgramResponse!;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(clientProgramsProvider.notifier).fetchActiveProgram(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Program Header Card ────────────────────────────────────────
          _ProgramHeaderCard(program: response.program),

          const SizedBox(height: 16),

          // ── Progress Card ──────────────────────────────────────────────
          _ProgressCard(
            progress: response.progress,
            templates: response.templates,
          ),

          const SizedBox(height: 24),

          // ── Templates Section Title ────────────────────────────────────
          Text(
            'Templates',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // ── Templates List ─────────────────────────────────────────────
          if (response.templates.isEmpty)
            _EmptyTemplatesPlaceholder()
          else
            ...response.templates.map(
              (template) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TemplateTile(template: template),
              ),
            ),

          const SizedBox(height: 24),

          // ── Switch Program ─────────────────────────────────────────────
          _SwitchProgramButton(
            onPressed: () => _showSwitchProgramSheet(state),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Switch Program Sheet
  // ---------------------------------------------------------------------------

  Future<void> _showSwitchProgramSheet(ClientProgramsState state) async {
    // Ensure library is loaded
    if (state.library == null) {
      await ref.read(clientProgramsProvider.notifier).fetchLibrary();
    }

    if (!mounted) return;

    final updatedState = ref.read(clientProgramsProvider);
    final assignedPrograms =
        updatedState.library?.assignedPrograms ?? <dynamic>[];

    if (assignedPrograms.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assigned programs available')),
      );
      return;
    }

    if (!mounted) return;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Switch Program',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: assignedPrograms.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    // assignedPrograms is List<AssignedProgram>
                    final assignment = assignedPrograms[index];
                    final program = assignment is Map<String, dynamic>
                        ? WorkoutProgram.fromJson(
                            assignment['program'] as Map<String, dynamic>,
                          )
                        : _resolveProgram(assignment);

                    final isActive = state.activeProgramResponse?.program.id ==
                        program.id;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isActive ? theme.colorScheme.primaryContainer : null,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive
                                ? theme.colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ),
                      ),
                      title: Text(
                        program.name,
                        style: TextStyle(
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: program.category != null
                          ? Text(program.category!)
                          : null,
                      trailing: isActive
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: isActive
                          ? null
                          : () async {
                              Navigator.of(ctx).pop();
                              await _switchProgram(program.id);
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Resolves the program from an assigned program object regardless of type.
  WorkoutProgram _resolveProgram(dynamic assignment) {
    if (assignment is Map<String, dynamic>) {
      final programData = assignment['program'];
      if (programData is Map<String, dynamic>) {
        return WorkoutProgram.fromJson(programData);
      }
    }
    // If the object has a .program getter (e.g. AssignedProgram model)
    try {
      final program = assignment.program;
      if (program is WorkoutProgram) return program;
    } catch (_) {
      // fall through
    }
    return WorkoutProgram(
      id: '',
      name: 'Unknown Program',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _switchProgram(String programId) async {
    final success =
        await ref.read(clientProgramsProvider.notifier).setActiveProgram(
              programId,
            );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Program switched successfully!'
              : 'Failed to switch program. Please try again.',
        ),
        backgroundColor: success
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

/// Error state with retry button.
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when no active program exists.
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              'No active program',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have an active program yet. Browse available programs to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/client/programs'),
              icon: const Icon(Icons.explore),
              label: const Text('Browse Programs'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown when the active program has no templates.
class _EmptyTemplatesPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 40,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'No templates yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card displaying the program name, description, and category.
class _ProgramHeaderCard extends StatelessWidget {
  final WorkoutProgram program;

  const _ProgramHeaderCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    program.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (program.category != null) ...[
                  const SizedBox(width: 12),
                  Chip(
                    label: Text(
                      program.category!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    backgroundColor: colorScheme.secondaryContainer,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            if (program.description != null &&
                program.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                program.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card showing the overall progress bar, percentage, and next template info.
class _ProgressCard extends StatelessWidget {
  final ActiveProgramProgress progress;
  final List<ActiveProgramTemplate> templates;

  const _ProgressCard({
    required this.progress,
    required this.templates,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isComplete = progress.progressPercentage >= 100;

    final progressColor =
        isComplete ? const Color(0xFF10B981) : colorScheme.primary;
    final percentage =
        (progress.progressPercentage.clamp(0, 100)).toStringAsFixed(0);

    final nextName = _nextTemplateName();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Percentage + label row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.totalCount > 0
                    ? (progress.completedCount / progress.totalCount)
                        .clamp(0, 1)
                    : 0,
                minHeight: 12,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 12),

            // Completed count
            Text(
              '${progress.completedCount} of ${progress.totalCount} templates completed',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            // Next template
            if (nextName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Next: $nextName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Looks up the next template name from [nextTemplateId].
  String? _nextTemplateName() {
    final nextId = progress.nextTemplateId;
    if (nextId == null) return null;
    try {
      return templates.firstWhere((t) => t.id == nextId).name;
    } catch (_) {
      return null;
    }
  }
}

/// A single template row with order avatar, name, and status badge.
class _TemplateTile extends StatelessWidget {
  final ActiveProgramTemplate template;

  const _TemplateTile({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isNext = template.status == TemplateStepStatus.next;
    final isCompleted = template.status == TemplateStepStatus.completed;

    return Card(
      color: isNext
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? const Color(0xFF10B981)
              : isNext
                  ? colorScheme.secondaryContainer
                  : colorScheme.surfaceContainerHighest,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text(
                  '${template.order}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isNext
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        title: Text(
          template.name,
          style: TextStyle(
            fontWeight: isNext ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${template.exerciseCount} exercises',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: _StatusBadge(
          status: template.status,
          theme: theme,
          colorScheme: colorScheme,
        ),
      ),
    );
  }
}

/// Small badge chip reflecting the template's completion status.
class _StatusBadge extends StatelessWidget {
  final TemplateStepStatus status;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _StatusBadge({
    required this.status,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TemplateStepStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              Text(
                'Completed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case TemplateStepStatus.next:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_forward,
                size: 14,
                color: colorScheme.secondary,
              ),
            ],
          ),
        );
      case TemplateStepStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Pending',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }
}

/// Outlined button to trigger the switch-program bottom sheet.
class _SwitchProgramButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SwitchProgramButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Switch Program'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
