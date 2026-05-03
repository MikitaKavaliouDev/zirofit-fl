import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/resource.dart';
import 'package:zirofit_fl/features/resources/providers/resource_provider.dart';

class ResourceVaultScreen extends ConsumerStatefulWidget {
  const ResourceVaultScreen({super.key});

  @override
  ConsumerState<ResourceVaultScreen> createState() =>
      _ResourceVaultScreenState();
}

class _ResourceVaultScreenState extends ConsumerState<ResourceVaultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(resourcesProvider);
      if (state.resources.isEmpty && !state.isLoading) {
        ref.read(resourcesProvider.notifier).fetchResources();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resourcesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Vault'),
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
        onPressed: () => context.push('/trainer/resources/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ResourcesState state, ThemeData theme) {
    // Loading state (initial load, no data yet)
    if (state.isLoading && state.resources.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (state.error != null && state.resources.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(resourcesProvider.notifier).fetchResources(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (state.resources.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No resources yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first resource to get started.',
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
      onRefresh: () => ref.read(resourcesProvider.notifier).fetchResources(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.resources.length,
        itemBuilder: (context, index) {
          final resource = state.resources[index];
          return Dismissible(
            key: ValueKey(resource.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: theme.colorScheme.error,
              child:
                  Icon(Icons.delete_outline, color: theme.colorScheme.onError),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Resource'),
                  content: Text(
                      'Are you sure you want to delete "${resource.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) {
              ref
                  .read(resourcesProvider.notifier)
                  .deleteResource(resource.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${resource.title} deleted')),
              );
            },
            child: _ResourceListTile(resource: resource),
          );
        },
      ),
    );
  }
}

class _ResourceListTile extends StatelessWidget {
  final Resource resource;

  const _ResourceListTile({required this.resource});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          _iconForFileType(resource.fileType),
          color: theme.colorScheme.primary,
        ),
        title: Text(resource.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: resource.description != null &&
                resource.description!.isNotEmpty
            ? Text(
                resource.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                resource.fileType.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, size: 16),
          ],
        ),
        onTap: () {
          // Open the resource URL
        },
      ),
    );
  }

  IconData _iconForFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'video':
      case 'mp4':
      case 'mov':
        return Icons.video_file;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }
}
