import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/data/models/external_link.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_external_links_provider.dart';

class TrainerExternalLinksScreen extends ConsumerStatefulWidget {
  const TrainerExternalLinksScreen({super.key});

  @override
  ConsumerState<TrainerExternalLinksScreen> createState() =>
      _TrainerExternalLinksScreenState();
}

class _TrainerExternalLinksScreenState
    extends ConsumerState<TrainerExternalLinksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerExternalLinksProvider.notifier).fetchLinks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerExternalLinksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('External Links'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddLinkDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add'),
          ),
        ],
      ),
      body: state.isLoading && state.links.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.links.isEmpty
              ? _buildEmptyState(theme)
              : _buildLinksList(theme, state.links),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No external links yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add links to your website, blog, or social media',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddLinkDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksList(ThemeData theme, List<ExternalLink> links) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(trainerExternalLinksProvider.notifier).fetchLinks(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: links.length,
        itemBuilder: (context, index) {
          final link = links[index];
          return _ExternalLinkCard(
            link: link,
            onEdit: () => _showEditLinkDialog(context, link),
            onDelete: () => _showDeleteConfirmation(context, link),
            onOpen: () => _openLink(link.linkUrl),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add Link Dialog
  // ---------------------------------------------------------------------------

  void _showAddLinkDialog(BuildContext context) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Link'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., My Website',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL *',
                    hintText: 'https://example.com',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final uri = Uri.tryParse(v.trim());
                    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                      return 'Enter a valid URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Brief description of this link...',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final Map<String, dynamic> data = {
                  'label': titleController.text,
                  'link_url': urlController.text,
                };
                if (descriptionController.text.trim().isNotEmpty) {
                  data['description'] = descriptionController.text;
                }
                ref
                    .read(trainerExternalLinksProvider.notifier)
                    .addLink(data);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit Link Dialog
  // ---------------------------------------------------------------------------

  void _showEditLinkDialog(BuildContext context, ExternalLink link) {
    final titleController = TextEditingController(text: link.label);
    final urlController = TextEditingController(text: link.linkUrl);
    final descriptionController =
        TextEditingController(text: link.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Link'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'URL *'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final uri = Uri.tryParse(v.trim());
                    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                      return 'Enter a valid URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final Map<String, dynamic> data = {
                  'label': titleController.text,
                  'link_url': urlController.text,
                };
                if (descriptionController.text.trim().isNotEmpty) {
                  data['description'] = descriptionController.text;
                }
                ref
                    .read(trainerExternalLinksProvider.notifier)
                    .updateLink(link.id, data);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete Confirmation
  // ---------------------------------------------------------------------------

  void _showDeleteConfirmation(BuildContext context, ExternalLink link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Link'),
        content: Text(
          'Are you sure you want to delete "${link.label}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(trainerExternalLinksProvider.notifier)
                  .deleteLink(link.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${link.label}" deleted')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link')),
          );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// External Link Card
// ---------------------------------------------------------------------------

class _ExternalLinkCard extends StatelessWidget {
  final ExternalLink link;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  const _ExternalLinkCard({
    required this.link,
    required this.onEdit,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.label,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        link.linkUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.open_in_new,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: onOpen,
                  tooltip: 'Open link',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Delete'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (link.description != null &&
                link.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                link.description!,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
