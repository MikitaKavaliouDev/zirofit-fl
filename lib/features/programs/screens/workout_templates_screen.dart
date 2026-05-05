import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/features/programs/providers/template_picker_provider.dart';

/// Client-facing screen for browsing workout templates.
///
/// Shows a searchable list/grid of templates from [templatePickerProvider].
/// Tapping a template opens a detail view. Includes loading, empty,
/// and error states.
class WorkoutTemplatesScreen extends ConsumerStatefulWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  ConsumerState<WorkoutTemplatesScreen> createState() =>
      _WorkoutTemplatesScreenState();
}

class _WorkoutTemplatesScreenState
    extends ConsumerState<WorkoutTemplatesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(templatePickerProvider);
      if (state.templates.isEmpty && !state.isLoading) {
        ref.read(templatePickerProvider.notifier).loadTemplates();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(templatePickerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Templates'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(templatePickerProvider.notifier)
                              .search('');
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (query) {
                ref.read(templatePickerProvider.notifier).search(query);
                setState(() {}); // update suffix icon
              },
            ),
          ),

          // Body
          Expanded(
            child: _buildBody(state, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TemplatePickerState state, ThemeData theme) {
    // Loading (initial)
    if (state.isLoading && state.templates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (state.error != null && state.templates.isEmpty) {
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
                    ref.read(templatePickerProvider.notifier).loadTemplates(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty
    if (state.templates.isEmpty) {
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
                state.searchQuery != null && state.searchQuery!.isNotEmpty
                    ? 'No templates match your search'
                    : 'No templates available',
                style: theme.textTheme.titleMedium,
              ),
              if (state.searchQuery != null && state.searchQuery!.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(templatePickerProvider.notifier).search('');
                  },
                  child: const Text('Clear search'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Template grid
    return RefreshIndicator(
      onRefresh: () => ref.read(templatePickerProvider.notifier).loadTemplates(),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: state.templates.length,
        itemBuilder: (context, index) {
          final template = state.templates[index];
          return _TemplateGridCard(
            template: template,
            onTap: () => _showDetail(context, template),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, WorkoutTemplate template) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(template.name),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (template.description != null &&
                    template.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(template.description!),
                  ),
                _InfoRow(
                  icon: Icons.fitness_center,
                  label: 'Program',
                  value: template.programId.length > 12
                      ? '...${template.programId.substring(template.programId.length - 12)}'
                      : template.programId,
                ),
                const SizedBox(height: 8),
                const _InfoRow(
                  icon: Icons.list,
                  label: 'Exercises',
                  value: '0', // placeholder until exercise count is available
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Template grid card
// ---------------------------------------------------------------------------

class _TemplateGridCard extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onTap;

  const _TemplateGridCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              // Name
              Text(
                template.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Exercise count placeholder
              Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '0 exercises',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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
// Info row for detail dialog
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
