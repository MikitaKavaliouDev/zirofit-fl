import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/client_progress_photo.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/clients/providers/client_detail_provider.dart';
import 'package:zirofit_fl/features/clients/screens/assign_program_screen.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const ClientDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ClientDetailScreen> createState() =>
      _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    Future.microtask(() {
      ref.read(clientDetailProvider(widget.id).notifier).fetchAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientDetailProvider(widget.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.client?.name ?? 'Client'),
        actions: [
          if (state.client != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'assign') {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AssignProgramScreen(
                        clientId: widget.id,
                        clientName: state.client!.name,
                        clientAvatarPath: state.client!.avatarPath,
                      ),
                    ),
                  );
                  if (result == true) {
                    ref.read(clientDetailProvider(widget.id).notifier)
                        .fetchAll();
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'assign',
                  child: ListTile(
                    leading: Icon(Icons.assignment),
                    title: Text('Assign Program'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(ClientDetailState state, ThemeData theme) {
    if (state.isLoadingClient && state.client == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.client == null) {
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
                    ref.read(clientDetailProvider(widget.id).notifier).fetchAll(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final client = state.client!;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(clientDetailProvider(widget.id).notifier).fetchAll(),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _ClientHeader(client: client, theme: theme),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabController: _tabController,
                tabNames: const [
                  'Overview',
                  'Measurements',
                  'Photos',
                  'Sessions',
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(client: client),
            _MeasurementsTab(clientId: widget.id),
            _PhotosTab(clientId: widget.id),
            _SessionsTab(clientId: widget.id),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client Header
// ---------------------------------------------------------------------------

class _ClientHeader extends StatelessWidget {
  final Client client;
  final ThemeData theme;

  const _ClientHeader({required this.client, required this.theme});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(client.status);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: client.avatarPath != null
                ? NetworkImage(client.avatarPath!)
                : null,
            child: client.avatarPath == null
                ? Text(
                    _initials(client.name),
                    style: TextStyle(
                      fontSize: 24,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.name, style: theme.textTheme.titleLarge),
                if (client.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    client.email!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (client.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    client.phone!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              client.status.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'lead':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
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
// TabBar Delegate
// ---------------------------------------------------------------------------

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> tabNames;

  _TabBarDelegate({
    required this.tabController,
    required this.tabNames,
  });

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        tabs: tabNames.map((name) => Tab(text: name)).toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      tabController != oldDelegate.tabController;
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  final Client client;

  const _OverviewTab({required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_today,
                  label: 'Age',
                  value: client.dateOfBirth != null
                      ? '${_yearsSince(client.dateOfBirth!)} yrs'
                      : '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.email,
                  label: 'Email',
                  value: client.email ?? '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: client.phone ?? '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.flag,
                  label: 'Status',
                  value: client.status,
                ),
              ),
            ],
          ),

          // Goals
          if (client.goals != null && client.goals!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Goals', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  client.goals!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],

          // Health Notes
          if (client.healthNotes != null &&
              client.healthNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Health Notes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  client.healthNotes!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],

          // Emergency Contact
          if (client.emergencyContactName != null ||
              client.emergencyContactPhone != null) ...[
            const SizedBox(height: 16),
            Text('Emergency Contact',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (client.emergencyContactName != null)
                      Text('Name: ${client.emergencyContactName}'),
                    if (client.emergencyContactPhone != null)
                      Text('Phone: ${client.emergencyContactPhone}'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _yearsSince(DateTime date) {
    final now = DateTime.now();
    int age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }
    return age;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Measurements Tab
// ---------------------------------------------------------------------------

class _MeasurementsTab extends ConsumerWidget {
  final String clientId;

  const _MeasurementsTab({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientDetailProvider(clientId));
    final theme = Theme.of(context);

    if (state.isLoadingMeasurements && state.measurements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final measurements = state.measurements;

    return Column(
      children: [
        // Add button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                'Measurements',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () =>
                    _showAddMeasurementDialog(context, ref, clientId),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),

        // Table header
        if (measurements.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Date',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Weight',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Body Fat',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

        // List
        Expanded(
          child: measurements.isEmpty
              ? Center(
                  child: Text(
                    'No measurements recorded yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: measurements.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final m = measurements[index];
                    return _MeasurementRow(measurement: m);
                  },
                ),
        ),
      ],
    );
  }

  void _showAddMeasurementDialog(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) {
    final dateController = TextEditingController();
    final weightController = TextEditingController();
    final bodyFatController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedDate = DateTime.now();
    var isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Measurement',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),

                    // Date
                    TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          dateController.text =
                              DateFormat('yyyy-MM-dd').format(picked);
                        }
                      },
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Date is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Weight
                    TextFormField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(Icons.monitor_weight),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Body Fat
                    TextFormField(
                      controller: bodyFatController,
                      decoration: const InputDecoration(
                        labelText: 'Body Fat (%)',
                        prefixIcon: Icon(Icons.percent),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;

                              setSheetState(() => isSubmitting = true);

                              final error = await ref
                                  .read(clientDetailProvider(clientId).notifier)
                                  .addMeasurement(
                                    measurementDate: selectedDate,
                                    weightKg: double.tryParse(
                                        weightController.text),
                                    bodyFatPercentage: double.tryParse(
                                        bodyFatController.text),
                                    notes: notesController.text.trim().isEmpty
                                        ? null
                                        : notesController.text.trim(),
                                  );

                              if (!context.mounted) return;

                              if (error != null) {
                                setSheetState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                );
                              } else {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Measurement added successfully!'),
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Measurement'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  final ClientMeasurement measurement;

  const _MeasurementRow({required this.measurement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatted =
        DateFormat('MMM dd, yyyy').format(measurement.measurementDate);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              dateFormatted,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              measurement.weightKg != null
                  ? '${measurement.weightKg!.toStringAsFixed(1)} kg'
                  : '—',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              measurement.bodyFatPercentage != null
                  ? '${measurement.bodyFatPercentage!.toStringAsFixed(1)}%'
                  : '—',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photos Tab
// ---------------------------------------------------------------------------

class _PhotosTab extends ConsumerWidget {
  final String clientId;

  const _PhotosTab({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientDetailProvider(clientId));
    final theme = Theme.of(context);

    if (state.isLoadingPhotos && state.photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final photos = state.photos;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                'Progress Photos',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () =>
                    _pickAndUploadPhoto(context, ref, clientId),
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('Upload'),
              ),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: photos.isEmpty
              ? Center(
                  child: Text(
                    'No progress photos yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return _PhotoTile(
                      photo: photo,
                      onTap: () => _showPhotoFullScreen(
                          context, photo, photos),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (picked == null) return;

    // Show loading indicator
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading photo...')),
    );

    final error = await ref
        .read(clientDetailProvider(clientId).notifier)
        .uploadPhoto(imagePath: picked.path);

    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully!')),
      );
    }
  }

  void _showPhotoFullScreen(
    BuildContext context,
    ClientProgressPhoto photo,
    List<ClientProgressPhoto> allPhotos,
  ) {
    final initialIndex = allPhotos.indexOf(photo);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoGalleryScreen(
          photos: allPhotos,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final ClientProgressPhoto photo;
  final VoidCallback onTap;

  const _PhotoTile({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatted =
        DateFormat('MMM dd').format(photo.photoDate);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  photo.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                dateFormatted,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-Screen Photo Gallery
// ---------------------------------------------------------------------------

class _PhotoGalleryScreen extends StatelessWidget {
  final List<ClientProgressPhoto> photos;
  final int initialIndex;

  const _PhotoGalleryScreen({
    required this.photos,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          DateFormat('MMM dd, yyyy')
              .format(photos[initialIndex].photoDate),
        ),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: Image.network(
                photo.imagePath,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image,
                      color: Colors.white54, size: 64),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sessions Tab
// ---------------------------------------------------------------------------

class _SessionsTab extends ConsumerWidget {
  final String clientId;

  const _SessionsTab({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientDetailProvider(clientId));
    final theme = Theme.of(context);

    if (state.isLoadingSessions && state.sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final sessions = state.sessions;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                'Workout Sessions',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${sessions.length} session${sessions.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (sessions.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => context.push('/trainer/clients/$clientId/sessions'),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('History'),
                ),
              ],
            ],
          ),
        ),

        // List
        Expanded(
          child: sessions.isEmpty
              ? Center(
                  child: Text(
                    'No workout sessions yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return _SessionCard(session: session);
                  },
                ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final WorkoutSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatted =
        DateFormat('MMM dd, yyyy').format(session.startTime);
    final timeFormatted = DateFormat('HH:mm').format(session.startTime);
    final statusColor = _sessionStatusColor(session.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name ?? 'Workout Session',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateFormatted at $timeFormatted',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.status.name.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _sessionStatusColor(WorkoutSessionStatus status) {
    switch (status) {
      case WorkoutSessionStatus.completed:
        return Colors.green;
      case WorkoutSessionStatus.inProgress:
        return Colors.blue;
      case WorkoutSessionStatus.planned:
        return Colors.grey;
    }
  }
}
