import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_profile_provider.dart';

class TrainerServicesScreen extends ConsumerStatefulWidget {
  const TrainerServicesScreen({super.key});

  @override
  ConsumerState<TrainerServicesScreen> createState() =>
      _TrainerServicesScreenState();
}

class _TrainerServicesScreenState
    extends ConsumerState<TrainerServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerProfileProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddServiceDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add'),
          ),
        ],
      ),
      body: state.isLoading && state.services.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.services.isEmpty
              ? _buildEmptyState(theme)
              : _buildServicesList(theme, state.services),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No services yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first service to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddServiceDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Service'),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(ThemeData theme, List<Service> services) {
    return RefreshIndicator(
      onRefresh: () => ref.read(trainerProfileProvider.notifier).fetchProfile(),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        onReorder: (oldIndex, newIndex) {
          // Reorder is visual-only for now; full reorder API can be added later
          final updated = List<Service>.from(services);
          if (oldIndex < newIndex) newIndex--;
          final item = updated.removeAt(oldIndex);
          updated.insert(newIndex, item);
          // We update the local state optimistically
          ref.read(trainerProfileProvider.notifier).reorderServices(updated);
        },
        itemBuilder: (context, index) {
          final service = services[index];
          return _ServiceCard(
            key: ValueKey(service.id),
            service: service,
            index: index,
            onEdit: () => _showEditServiceDialog(context, service),
            onDelete: () => _showDeleteConfirmation(context, service),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add Service Dialog
  // ---------------------------------------------------------------------------

  void _showAddServiceDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final iconController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Service'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g., Personal Training',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your service...',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    hintText: 'e.g., fitness_center',
                    helperText: 'Material icon name',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          hintText: '0.00',
                          prefixText: '\$ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (min)',
                          hintText: '60',
                        ),
                      ),
                    ),
                  ],
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
                final data = {
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'price': double.tryParse(priceController.text) ?? 0,
                  'duration': int.tryParse(durationController.text) ?? 60,
                };
                ref
                    .read(trainerProfileProvider.notifier)
                    .addService(data);
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
  // Edit Service Dialog
  // ---------------------------------------------------------------------------

  void _showEditServiceDialog(BuildContext context, Service service) {
    final titleController = TextEditingController(text: service.title);
    final descriptionController =
        TextEditingController(text: service.description);
    final priceController = TextEditingController(
      text: service.price?.toStringAsFixed(2) ?? '',
    );
    final durationController = TextEditingController(
      text: service.duration?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Service'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          prefixText: '\$ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (min)',
                        ),
                      ),
                    ),
                  ],
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
                final data = {
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'price': double.tryParse(priceController.text) ?? 0,
                  'duration': int.tryParse(durationController.text) ?? 60,
                };
                ref
                    .read(trainerProfileProvider.notifier)
                    .updateService(service.id, data);
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

  void _showDeleteConfirmation(BuildContext context, Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content:
            Text('Are you sure you want to delete "${service.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(trainerProfileProvider.notifier)
                  .deleteService(service.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${service.title}" deleted')),
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
// Service Card
// ---------------------------------------------------------------------------

class _ServiceCard extends StatelessWidget {
  final Service service;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    super.key,
    required this.service,
    required this.index,
    required this.onEdit,
    required this.onDelete,
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
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.title,
                    style: theme.textTheme.titleMedium,
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
            if (service.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                service.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (service.price != null && service.price! > 0) ...[
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    service.price!.toStringAsFixed(2),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (service.duration != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${service.duration} min',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
