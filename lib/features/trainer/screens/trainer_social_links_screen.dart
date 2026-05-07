import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/social_link.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_social_links_provider.dart';

// ---------------------------------------------------------------------------
// Social platform metadata
// ---------------------------------------------------------------------------

class SocialPlatform {
  final String key;
  final String displayName;
  final IconData icon;
  final Color color;

  const SocialPlatform({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.color,
  });

  static const List<SocialPlatform> all = [
    SocialPlatform(
      key: 'instagram',
      displayName: 'Instagram',
      icon: Icons.camera_alt,
      color: Color(0xFFE4405F),
    ),
    SocialPlatform(
      key: 'twitter',
      displayName: 'Twitter / X',
      icon: Icons.alternate_email,
      color: Color(0xFF1DA1F2),
    ),
    SocialPlatform(
      key: 'youtube',
      displayName: 'YouTube',
      icon: Icons.play_circle_filled,
      color: Color(0xFFFF0000),
    ),
    SocialPlatform(
      key: 'tiktok',
      displayName: 'TikTok',
      icon: Icons.music_note,
      color: Color(0xFF010101),
    ),
    SocialPlatform(
      key: 'linkedin',
      displayName: 'LinkedIn',
      icon: Icons.business,
      color: Color(0xFF0A66C2),
    ),
    SocialPlatform(
      key: 'facebook',
      displayName: 'Facebook',
      icon: Icons.people,
      color: Color(0xFF1877F2),
    ),
    SocialPlatform(
      key: 'website',
      displayName: 'Website',
      icon: Icons.language,
      color: Color(0xFF4CAF50),
    ),
  ];

  static SocialPlatform fromKey(String key) =>
      all.firstWhere((p) => p.key == key, orElse: () => all.last);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TrainerSocialLinksScreen extends ConsumerStatefulWidget {
  const TrainerSocialLinksScreen({super.key});

  @override
  ConsumerState<TrainerSocialLinksScreen> createState() =>
      _TrainerSocialLinksScreenState();
}

class _TrainerSocialLinksScreenState
    extends ConsumerState<TrainerSocialLinksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerSocialLinksProvider.notifier).fetchLinks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerSocialLinksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Links'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddLinkDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add'),
          ),
        ],
      ),
      body: state.isLoading && state.socialLinks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.socialLinks.isEmpty
              ? _buildEmptyState(theme)
              : _buildLinksList(theme, state.socialLinks),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.share,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No social links yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add links to your social profiles',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddLinkDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Social Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksList(ThemeData theme, List<SocialLink> links) {
    return RefreshIndicator(
      onRefresh: () => ref.read(trainerSocialLinksProvider.notifier).fetchLinks(),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: links.length,
        onReorder: (oldIndex, newIndex) {
          final updated = List<SocialLink>.from(links);
          if (oldIndex < newIndex) newIndex--;
          final item = updated.removeAt(oldIndex);
          updated.insert(newIndex, item);
          ref.read(trainerSocialLinksProvider.notifier).reorderLinks(updated);
        },
        itemBuilder: (context, index) {
          final link = links[index];
          return _SocialLinkCard(
            key: ValueKey(link.id),
            link: link,
            index: index,
            onEdit: () => _showEditLinkDialog(context, link),
            onDelete: () => _showDeleteConfirmation(context, link),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add Link Dialog
  // ---------------------------------------------------------------------------

  void _showAddLinkDialog(BuildContext context) {
    String selectedPlatform = SocialPlatform.all.first.key;
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Social Link'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _PlatformPicker(
                    selected: selectedPlatform,
                    onSelected: (key) {
                      setState(() => selectedPlatform = key);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'Profile URL *',
                      hintText: 'https://$selectedPlatform.com/yourprofile',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        SocialPlatform.fromKey(selectedPlatform).icon,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'URL is required';
                      }
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null || !uri.hasScheme) {
                        return 'Enter a valid URL (include https://)';
                      }
                      return null;
                    },
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
                  ref
                      .read(trainerSocialLinksProvider.notifier)
                      .addLink(
                        platform: selectedPlatform,
                        url: urlController.text.trim(),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit Link Dialog
  // ---------------------------------------------------------------------------

  void _showEditLinkDialog(BuildContext context, SocialLink link) {
    String selectedPlatform = link.platform;
    final urlController = TextEditingController(text: link.profileUrl);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Social Link'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _PlatformPicker(
                    selected: selectedPlatform,
                    onSelected: (key) {
                      setState(() => selectedPlatform = key);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'Profile URL *',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        SocialPlatform.fromKey(selectedPlatform).icon,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'URL is required';
                      }
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null || !uri.hasScheme) {
                        return 'Enter a valid URL (include https://)';
                      }
                      return null;
                    },
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
                  ref
                      .read(trainerSocialLinksProvider.notifier)
                      .updateLink(
                        id: link.id,
                        platform: selectedPlatform,
                        url: urlController.text.trim(),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete Confirmation
  // ---------------------------------------------------------------------------

  void _showDeleteConfirmation(BuildContext context, SocialLink link) {
    final platform = SocialPlatform.fromKey(link.platform);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Social Link'),
        content: Text(
          'Are you sure you want to delete your ${platform.displayName} link?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(trainerSocialLinksProvider.notifier).deleteLink(link.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${platform.displayName} link deleted'),
                ),
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
}

// ---------------------------------------------------------------------------
// Platform Picker Widget
// ---------------------------------------------------------------------------

class _PlatformPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _PlatformPicker({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SocialPlatform.all.map((platform) {
        final isSelected = platform.key == selected;
        return ChoiceChip(
          selected: isSelected,
          avatar: Icon(platform.icon, size: 18),
          label: Text(platform.displayName),
          onSelected: (_) => onSelected(platform.key),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Social Link Card
// ---------------------------------------------------------------------------

class _SocialLinkCard extends StatelessWidget {
  final SocialLink link;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SocialLinkCard({
    super.key,
    required this.link,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platform = SocialPlatform.fromKey(link.platform);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: platform.color.withOpacity(0.15),
              child: Icon(platform.icon, color: platform.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    link.profileUrl,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
      ),
    );
  }
}
