import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/personal_template.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';

/// Client-facing detail screen for a personal program.
///
/// Shows program info, category, source badge, and a list of its templates.
class ClientProgramDetailScreen extends ConsumerWidget {
  final String programId;

  const ClientProgramDetailScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientProgramsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final program = state.library?.personalPrograms
        .where((p) => p.id == programId)
        .firstOrNull;

    // Loading (no library yet)
    if (state.isLoading && state.library == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Program')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error (no data loaded)
    if (state.error != null && state.library == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Program')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      ref.read(clientProgramsProvider.notifier).fetchLibrary(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Not found
    if (program == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Program')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Program not found',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Data
    return Scaffold(
      appBar: AppBar(title: Text(program.name)),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(clientProgramsProvider.notifier).fetchLibrary(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Program header card ──────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(program.name, style: theme.textTheme.titleLarge),
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
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (program.category != null &&
                            program.category!.isNotEmpty)
                          Chip(
                            label: Text(program.category!),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        Chip(
                          label: Text(
                            program.source == 'self'
                                ? 'My Program'
                                : 'Assigned',
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Add Template button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  '/client/programs/create-template',
                  extra: program.id,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Template'),
              ),
            ),

            const SizedBox(height: 24),

            // ── Templates section ───────────────────────────────────
            Text(
              'Templates (${program.templates.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            if (program.templates.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 40,
                          color: colorScheme.primary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No templates yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...program.templates.map(
                (template) => _TemplateListTile(
                  template: template,
                  onTap: () =>
                      context.push('/client/programs/templates/${template.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Template list tile
// ---------------------------------------------------------------------------

class _TemplateListTile extends StatelessWidget {
  final PersonalTemplate template;
  final VoidCallback onTap;

  const _TemplateListTile({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (template.description != null &&
                        template.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        template.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${template.exerciseCount} exercises',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
