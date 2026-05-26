import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/active_program_response.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/client_package.dart';
import 'package:zirofit_fl/data/models/client_progress_photo.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/clients/providers/client_detail_provider.dart';
import 'package:zirofit_fl/features/clients/screens/assign_program_screen.dart';
import 'package:zirofit_fl/features/workout/providers/active_workout_provider.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/checkin/screens/completed_session_detail_screen.dart';

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
    final client = ref.watch(
      clientDetailProvider(widget.id).select((s) => s.client),
    );
    final isLoadingClient = ref.watch(
      clientDetailProvider(widget.id).select((s) => s.isLoadingClient),
    );
    final error = ref.watch(
      clientDetailProvider(widget.id).select((s) => s.error),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(client?.name ?? 'Client'),
        actions: [
          if (client != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'assign') {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AssignProgramScreen(
                        clientId: widget.id,
                        clientName: client.name,
                        clientAvatarPath: client.avatarPath,
                      ),
                    ),
                  );
                  if (result == true) {
                    ref.read(clientDetailProvider(widget.id).notifier)
                        .fetchAll();
                  }
                } else if (value == 'monitor') {
                  context.push('/trainer/clients/${widget.id}/live-session');
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
                  value: 'monitor',
                  child: ListTile(
                    leading: Icon(Icons.monitor_heart),
                    title: Text('Live Session'),
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
      body: _buildBody(client, isLoadingClient, error, theme),
    );
  }

  Widget _buildBody(Client? client, bool isLoadingClient, String? error, ThemeData theme) {
    if (isLoadingClient && client == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && client == null) {
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
                error,
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

    final c = client!;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(clientDetailProvider(widget.id).notifier).fetchAll(),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _ClientHeader(client: c, theme: theme),
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
            _OverviewTab(client: c, clientId: widget.id),
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
            backgroundImage: client.avatarPath != null && client.avatarPath!.isNotEmpty
                ? NetworkImage(client.avatarPath!)
                : null,
            child: client.avatarPath == null || client.avatarPath!.isEmpty
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


class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
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
            Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.primary),
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
    final measurements = ref.watch(
      clientDetailProvider(clientId).select((s) => s.measurements),
    );
    final isLoadingMeasurements = ref.watch(
      clientDetailProvider(clientId).select((s) => s.isLoadingMeasurements),
    );
    final theme = Theme.of(context);

    if (isLoadingMeasurements && measurements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          if (bodyFatController.text.isNotEmpty) {
                            return 'Weight is required when body fat is provided';
                          }
                          return null;
                        }
                        final weight = double.tryParse(v);
                        if (weight == null) {
                          return 'Please enter a valid number';
                        }
                        if (weight < 20 || weight > 500) {
                          return 'Weight must be between 20 and 500 kg';
                        }
                        return null;
                      },
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
    final photos = ref.watch(
      clientDetailProvider(clientId).select((s) => s.photos),
    );
    final isLoadingPhotos = ref.watch(
      clientDetailProvider(clientId).select((s) => s.isLoadingPhotos),
    );
    final theme = Theme.of(context);

    if (isLoadingPhotos && photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  final Client client;
  final String clientId;

  const _OverviewTab({required this.client, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(clientDetailProvider(clientId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats Row ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.fitness_center,
                  label: 'Workouts',
                  value: state.workoutsCount.toString(),
                  iconColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Active Streak',
                  value: state.activeStreak,
                  iconColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.schedule,
                  label: 'Last Session',
                  value: state.lastSessionTime,
                  iconColor: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Active Program Section ─────────────────────────────────
          if (state.activeProgram != null)
            _buildActiveProgram(context, ref, state.activeProgram!, state.isLoadingProgram),
          if (state.activeProgram == null && state.isLoadingProgram)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )),
          if (state.activeProgram == null && !state.isLoadingProgram)
            const SizedBox.shrink(),

          // ── Active Package Section ─────────────────────────────────
          ..._buildActivePackage(context, ref, state.clientPackages),

          // ── Start Workout Session Button ───────────────────────────
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final activeState = ref.read(activeWorkoutProvider);
                if (activeState.hasActiveSession) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Ongoing Session'),
                      content: const Text(
                        'You already have an active workout session. '
                        'Would you like to end it and start a new one?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('End & Start New'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  // End the existing session before starting a new one
                  await ref.read(activeWorkoutProvider.notifier).cancelWorkout();
                }
                ref.read(sessionOverlayProvider.notifier).showFull();
                ref.read(activeWorkoutProvider.notifier)
                    .startSessionForClient(clientId: clientId, clientName: client.name);
              },
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                'Start Workout Session',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: Colors.blue.withValues(alpha: 0.4),
              ).copyWith(
                backgroundColor: const WidgetStatePropertyAll(
                  // Blue gradient simulated via a blue shade
                  Color(0xFF2196F3),
                ),
              ),
            ),
          ),

          // ── Management Actions ─────────────────────────────────────
          const SizedBox(height: 24),
          Text('Management', style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _requestCheckIn(context, ref),
                  icon: const Icon(Icons.calendar_month, color: Colors.orange),
                  label: const Text(
                    'Request Check-in',
                    style: TextStyle(color: Colors.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.orange.withValues(alpha: 0.05),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AssignProgramScreen(
                          clientId: clientId,
                          clientName: client.name,
                          clientAvatarPath: client.avatarPath,
                        ),
                      ),
                    ).then((result) {
                      if (result == true) {
                        ref.read(clientDetailProvider(clientId).notifier).fetchAll();
                      }
                    });
                  },
                  icon: const Icon(Icons.assignment, color: Colors.blue),
                  label: const Text(
                    'Assign Program',
                    style: TextStyle(color: Colors.blue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue.withValues(alpha: 0.05),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/trainer/clients/$clientId/analytics?name=${Uri.encodeComponent(client.name)}',
                  ),
                  icon: const Icon(Icons.bar_chart, color: Colors.teal),
                  label: const Text(
                    'View Analytics',
                    style: TextStyle(color: Colors.teal),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.teal.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),

          // ── Recent Activity ────────────────────────────────────────
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Recent Activity', style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/trainer/clients/$clientId/sessions'),
                child: const Text('View Full History'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.sessions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.bar_chart, size: 40,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text('No recent activity',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (final session in state.sessions.take(5)) ...[
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CompletedSessionDetailScreen(
                              sessionId: session.id,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _RecentSessionRow(session: session),
                    ),
                    if (session.id != state.sessions.take(5).last.id)
                      Divider(
                        height: 1,
                        indent: 16,
                        color: theme.dividerColor,
                      ),
                  ],
                ],
              ),
            ),

          // ── Old Content: Goals, Health Notes, Emergency Contact ────
          const SizedBox(height: 24),
          if (client.goals != null && client.goals!.isNotEmpty) ...[
            Text('Goals', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(client.goals!, style: theme.textTheme.bodyLarge),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (client.healthNotes != null && client.healthNotes!.isNotEmpty) ...[
            Text('Health Notes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(client.healthNotes!, style: theme.textTheme.bodyLarge),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (client.emergencyContactName != null ||
              client.emergencyContactPhone != null) ...[
            Text('Emergency Contact', style: theme.textTheme.titleMedium),
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActiveProgram(
    BuildContext context,
    WidgetRef ref,
    ActiveProgramResponse program,
    bool isLoading,
  ) {
    final theme = Theme.of(context);
    final progress = program.progress;
    final pct = progress.progressPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Program', style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fitness_center, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        program.program.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct > 0 ? pct / 100 : null,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${progress.completedCount} of ${progress.totalCount} workouts completed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Cancel Program button
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _showCancelProgramDialog(context, ref, program),
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text(
              'Cancel Program',
              style: TextStyle(color: Colors.red),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _buildActivePackage(
    BuildContext context,
    WidgetRef ref,
    List<ClientPackage> packages,
  ) {
    final activePackage = packages.where((p) => p.sessionsRemaining > 0).toList();
    if (activePackage.isEmpty) return [];

    final pkg = activePackage.first;
    final theme = Theme.of(context);

    return [
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ref.read(sessionOverlayProvider.notifier).showFull();
              ref.read(activeWorkoutProvider.notifier)
                  .startSessionForClient(clientId: clientId, clientName: client.name);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Active Package',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pkg.sessionsRemaining} sessions remaining',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Start Package Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  void _showCancelProgramDialog(
    BuildContext context,
    WidgetRef ref,
    ActiveProgramResponse program,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Program'),
        content: Text(
          'Are you sure you want to cancel "${program.program.name}" for ${client.name}? '
          'This will remove all scheduled sessions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Program'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final error = await ref.read(clientDetailProvider(clientId).notifier)
                  .cancelProgram(program.program.id);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Program'),
          ),
        ],
      ),
    );
  }

  void _requestCheckIn(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Check-in Requested'),
        content: Text(
          'A notification has been sent to ${client.name} requesting their weekly progress check-in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(clientDetailProvider(clientId).notifier).requestCheckIn();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Activity Session Row
// ---------------------------------------------------------------------------

class _RecentSessionRow extends StatelessWidget {
  final WorkoutSession session;

  const _RecentSessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = DateFormat('MMM').format(session.startTime);
    final day = session.startTime.day.toString();

    final durationStr = session.endTime != null
        ? '${session.endTime!.difference(session.startTime).inMinutes}m'
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Date box
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  month,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  day,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Session info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name ?? 'Workout Session',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (durationStr != null) ...[
                      Icon(Icons.timer_outlined, size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        durationStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      session.status.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _statusColor(session.status, theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 18,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Color _statusColor(WorkoutSessionStatus status, ThemeData theme) {
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

// ---------------------------------------------------------------------------
// Sessions Tab
// ---------------------------------------------------------------------------

class _SessionsTab extends ConsumerWidget {
  final String clientId;

  const _SessionsTab({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(
      clientDetailProvider(clientId).select((s) => s.sessions),
    );
    final isLoadingSessions = ref.watch(
      clientDetailProvider(clientId).select((s) => s.isLoadingSessions),
    );
    final theme = Theme.of(context);

    if (isLoadingSessions && sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
