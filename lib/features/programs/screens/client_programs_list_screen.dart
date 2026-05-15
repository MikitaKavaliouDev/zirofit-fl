import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/active_program_response.dart';
import 'package:zirofit_fl/data/models/assigned_program.dart';
import 'package:zirofit_fl/data/models/personal_program.dart';
import 'package:zirofit_fl/data/models/personal_template.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';

/// Client-facing screen showing the full programs/templates library.
///
/// Displays sections for: active program, assigned-by-trainer programs,
/// personal programs, and system templates — with a category filter bar
/// and a FAB to create new programs/templates.
class ClientProgramsListScreen extends ConsumerStatefulWidget {
  const ClientProgramsListScreen({super.key});

  @override
  ConsumerState<ClientProgramsListScreen> createState() =>
      _ClientProgramsListScreenState();
}

class _ClientProgramsListScreenState
    extends ConsumerState<ClientProgramsListScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientProgramsProvider.notifier).fetchLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientProgramsProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
      body: _buildBody(state, colorScheme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body builder
  // ---------------------------------------------------------------------------

  Widget _buildBody(ClientProgramsState state, ColorScheme colorScheme) {
    // Initial loading (no data yet)
    if (state.isLoading && state.library == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error (no data yet)
    if (state.error != null && state.library == null) {
      return _ErrorState(
        message: state.error!,
        onRetry: () =>
            ref.read(clientProgramsProvider.notifier).fetchLibrary(),
      );
    }

    final library = state.library;
    if (library == null) return const SizedBox.shrink();

    // Empty state
    final hasActive = state.activeProgramResponse != null;
    final hasAssigned = library.assignedPrograms.isNotEmpty;
    final hasPersonal = library.personalPrograms.isNotEmpty;
    final hasSystemTemplates = library.systemTemplates.isNotEmpty;

    if (!hasActive && !hasAssigned && !hasPersonal && !hasSystemTemplates) {
      return _EmptyProgramsState(
        onCreateProgram: () => context.push('/client/programs/create'),
      );
    }

    // Data state
    return RefreshIndicator(
      onRefresh: () => ref
          .read(clientProgramsProvider.notifier)
          .fetchLibrary(category: _selectedCategory),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          // -- Category filter bar --
          _CategoryFilterBar(
            categories: library.categories,
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) {
              setState(() => _selectedCategory = category);
              ref
                  .read(clientProgramsProvider.notifier)
                  .fetchLibrary(category: category);
            },
          ),

          // -- Active Program section --
          if (hasActive) ...[
            const _SectionHeader(title: 'Active Program'),
            _ActiveProgramCard(
              response: state.activeProgramResponse!,
            ),
          ],

          // -- Assigned by Trainer section --
          if (hasAssigned) ...[
            const _SectionHeader(title: 'Assigned by Trainer'),
            ...library.assignedPrograms.map(
              (ap) => _AssignedProgramCard(assigned: ap),
            ),
          ],

          // -- My Programs section --
          if (hasPersonal) ...[
            const _SectionHeader(title: 'My Programs'),
            ...library.personalPrograms.map(
              (pp) => _PersonalProgramCard(program: pp),
            ),
          ],

          // -- System Templates section --
          if (hasSystemTemplates) ...[
            const _SectionHeader(title: 'System Templates'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SystemTemplatesGrid(
                templates: library.systemTemplates,
                onCopy: (templateId) => _handleCopyTemplate(templateId),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FAB actions
  // ---------------------------------------------------------------------------

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Create New',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Program'),
              subtitle: const Text('A full workout program'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/client/programs/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Template'),
              subtitle: const Text('A single workout template'),
              onTap: () {
                Navigator.of(ctx).pop();
                _handleCreateTemplate();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _handleCreateTemplate() {
    final library = ref.read(clientProgramsProvider).library;
    final programs = library?.personalPrograms ?? [];

    if (programs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a program first before adding templates'),
        ),
      );
      return;
    }

    if (programs.length == 1) {
      context.push('/client/programs/create-template', extra: programs.first.id);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Program'),
        children: [
          ...programs.map(
            (program) => SimpleDialogOption(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push(
                  '/client/programs/create-template',
                  extra: program.id,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    program.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: program.description != null &&
                          program.description!.isNotEmpty
                      ? Text(
                          program.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  dense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCopyTemplate(String templateId) async {
    final messenger = ScaffoldMessenger.of(context);
    final success =
        await ref.read(clientProgramsProvider.notifier).copyTemplate(templateId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Template copied to your library!' : 'Failed to copy template',
        ),
      ),
    );
  }
}

// =============================================================================
// Private Widgets
// =============================================================================

/// Horizontal scrolling category filter bar with ChoiceChips.
class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selectedCategory == null,
            onSelected: (_) => onCategoryChanged(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_capitalize(category)),
                selected: selectedCategory == category,
                onSelected: (selected) {
                  onCategoryChanged(selected ? category : null);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// Section header label placed above each section.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Active program card with name, progress bar, and completion stats.
class _ActiveProgramCard extends StatelessWidget {
  final ActiveProgramResponse response;
  const _ActiveProgramCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = response.progress;
    final percentage = (progress.progressPercentage * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/client/programs/active'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        response.program.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.progressPercentage.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$percentage% complete · ${progress.completedCount}/${progress.totalCount} workouts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Assigned program card (from trainer).
class _AssignedProgramCard extends StatelessWidget {
  final AssignedProgram assigned;
  const _AssignedProgramCard({required this.assigned});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final program = assigned.program;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/client/programs/${program.id}'),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Source badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'From Trainer',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                if (program.description != null &&
                    program.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    program.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (assigned.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
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
      ),
    );
  }
}

/// Personal program card (created by user).
class _PersonalProgramCard extends StatelessWidget {
  final PersonalProgram program;
  const _PersonalProgramCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/client/programs/${program.id}'),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Source badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'My Program',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                if (program.description != null &&
                    program.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    program.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
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
                    if (program.category != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _capitalize(program.category!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
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
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// Grid of system template cards with copy action.
class _SystemTemplatesGrid extends StatelessWidget {
  final List<PersonalTemplate> templates;
  final ValueChanged<String> onCopy;

  const _SystemTemplatesGrid({
    required this.templates,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'System',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  template.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${template.exerciseCount} exercises',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onCopy(template.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Error state when no data is available.
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
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

/// Empty state when no programs or templates exist.
class _EmptyProgramsState extends StatelessWidget {
  final VoidCallback onCreateProgram;
  const _EmptyProgramsState({required this.onCreateProgram});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No programs available',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a program or browse system templates to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateProgram,
              icon: const Icon(Icons.add),
              label: const Text('Create Program'),
            ),
          ],
        ),
      ),
    );
  }
}
