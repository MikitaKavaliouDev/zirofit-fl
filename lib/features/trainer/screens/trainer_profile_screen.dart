import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zirofit_fl/data/models/benefit.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/data/models/social_link.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';
import 'package:zirofit_fl/data/models/external_link.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_external_links_provider.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_branding_provider.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_profile_provider.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_transformation_photos_provider.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_social_links_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_social_links_screen.dart';

class TrainerProfileScreen extends ConsumerStatefulWidget {
  const TrainerProfileScreen({super.key});

  @override
  ConsumerState<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends ConsumerState<TrainerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(trainerProfileProvider.notifier).setActiveTab(_tabController.index);
      }
    });

    // Fetch profile data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerProfileProvider.notifier).fetchProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Profile'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Core Info'),
            Tab(text: 'About'),
            Tab(text: 'Services'),
            Tab(text: 'Packages'),
            Tab(text: 'Testimonials'),
            Tab(text: 'Benefits'),
            Tab(text: 'Transformation'),
            Tab(text: 'Social Links'),
            Tab(text: 'External Links'),
          ],
        ),
      ),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _CoreInfoSection(),
                _AboutSection(),
                _ServicesSection(),
                _PackagesSection(),
                _TestimonialsSection(),
                _BenefitsSection(),
                _TransformationSection(),
                const _SocialLinksSection(),
                const _ExternalLinksSection(),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Core Info Section
// ---------------------------------------------------------------------------

class _CoreInfoSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerProfileProvider);
    final brandingState = ref.watch(trainerBrandingProvider);
    final profile = state.profile;

    // Determine effective URLs – branding provider takes precedence
    final effectiveBannerUrl =
        brandingState.bannerUrl ?? profile?.bannerImagePath;
    final effectiveAvatarUrl =
        brandingState.avatarUrl ?? profile?.profilePhotoPath;

    return RefreshIndicator(
      onRefresh: () => ref.read(trainerProfileProvider.notifier).fetchProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branding Header: Banner + Avatar
            _BrandingHeader(
              bannerUrl: effectiveBannerUrl,
              avatarUrl: effectiveAvatarUrl,
              isUploading: brandingState.isUploading,
              uploadProgress: brandingState.uploadProgress,
              onBannerEdit: () =>
                  _showImagePickerSheet(context, ref, _ImageType.banner),
              onAvatarEdit: () =>
                  _showImagePickerSheet(context, ref, _ImageType.avatar),
            ),
            const SizedBox(height: 16),

            // Upload progress indicator
            if (brandingState.isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: brandingState.uploadProgress,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uploading... ${(brandingState.uploadProgress * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

            if (brandingState.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  brandingState.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // User Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      const _InfoRow(
                        icon: Icons.person,
                        label: 'Name',
                        value: 'Trainer User',
                      ),
                      const Divider(),
                      const _InfoRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: 'trainer@example.com',
                      ),
                      const Divider(),
                      const _InfoRow(
                        icon: Icons.alternate_email,
                        label: 'Username',
                        value: '@trainer',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Profile Completion
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Completion',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (profile?.completionPercentage ?? 0) / 100,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${profile?.completionPercentage ?? 0}% complete',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image Type enum for picker
// ---------------------------------------------------------------------------

enum _ImageType { banner, avatar }

// ---------------------------------------------------------------------------
// Branding Header: Banner + Avatar with overlays
// ---------------------------------------------------------------------------

class _BrandingHeader extends StatelessWidget {
  final String? bannerUrl;
  final String? avatarUrl;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback onBannerEdit;
  final VoidCallback onAvatarEdit;

  const _BrandingHeader({
    this.bannerUrl,
    this.avatarUrl,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    required this.onBannerEdit,
    required this.onAvatarEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // --- Banner ---
        SizedBox(
          width: double.infinity,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Banner image or placeholder
              if (bannerUrl != null && bannerUrl!.isNotEmpty)
                Image.network(
                  bannerUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _bannerPlaceholder(theme),
                )
              else
                _bannerPlaceholder(theme),

              // Gradient overlay for readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),

              // Edit button overlay
              Positioned(
                right: 12,
                top: 12,
                child: Material(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onBannerEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              // Upload progress overlay on banner
              if (isUploading)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: uploadProgress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // --- Avatar (overlapping banner bottom) ---
        Transform.translate(
          offset: const Offset(0, -50),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),

              // Edit button on avatar
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onAvatarEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bannerPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Banner Image',
              style: theme.textTheme.bodyMedium?.copyWith(
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
// Image picker helpers
// ---------------------------------------------------------------------------

extension on _CoreInfoSection {
  void _showImagePickerSheet(
      BuildContext context, WidgetRef ref, _ImageType type) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                type == _ImageType.avatar
                    ? 'Change Profile Photo'
                    : 'Change Banner Image',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(context, ref, type, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(context, ref, type, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    _ImageType type,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
    );

    if (pickedFile == null) return;

    final notifier = ref.read(trainerBrandingProvider.notifier);
    if (type == _ImageType.avatar) {
      await notifier.uploadAvatar(pickedFile.path);
    } else {
      await notifier.uploadBanner(pickedFile.path);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == _ImageType.avatar
                ? 'Profile photo updated'
                : 'Banner image updated',
          ),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// About Section
// ---------------------------------------------------------------------------

class _AboutSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainerProfileProvider);
    final profile = state.profile;

    return RefreshIndicator(
      onRefresh: () => ref.read(trainerProfileProvider.notifier).fetchProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AboutCard(
              title: 'About Me',
              content: profile?.aboutMe ?? '',
              field: 'aboutMe',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _AboutCard(
              title: 'Philosophy',
              content: profile?.philosophy ?? '',
              field: 'philosophy',
              icon: Icons.lightbulb_outline,
            ),
            const SizedBox(height: 16),
            _AboutCard(
              title: 'Methodology',
              content: profile?.methodology ?? '',
              field: 'methodology',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 16),
            _AboutCard(
              title: 'Branding',
              content: profile?.branding ?? '',
              field: 'branding',
              icon: Icons.palette_outlined,
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/trainer/profile/edit-text'),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Edit Text Content'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends ConsumerWidget {
  final String title;
  final String content;
  final String field;
  final IconData icon;

  const _AboutCard({
    required this.title,
    required this.content,
    required this.field,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditDialog(context, ref),
                  tooltip: 'Edit',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content.isEmpty ? 'No content yet' : content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: content.isEmpty
                    ? theme.colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter $title...',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(trainerProfileProvider.notifier).updateTextContent(
                    field,
                    controller.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Services Section
// ---------------------------------------------------------------------------

class _ServicesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerProfileProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(trainerProfileProvider.notifier).fetchProfile(),
      child: Column(
        children: [
          // Add Service Button & Manage link
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddServiceDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Service'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/trainer/profile/services'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: state.services.isEmpty
                ? Center(
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
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.services.length,
                    itemBuilder: (context, index) {
                      final service = state.services[index];
                      return _ServiceCard(service: service);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Personal Training',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your service...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: '0.00',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  hintText: '60',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final data = {
                'title': titleController.text,
                'description': descriptionController.text,
                'price': double.tryParse(priceController.text) ?? 0,
                'duration': int.tryParse(durationController.text) ?? 60,
              };
              ref.read(trainerProfileProvider.notifier).addService(data);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  final Service service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Expanded(
                  child: Text(
                    service.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditServiceDialog(context, ref);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, ref);
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
            const SizedBox(height: 8),
            Text(
              service.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (service.price != null) ...[
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

  void _showEditServiceDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController(text: service.title);
    final descriptionController = TextEditingController(text: service.description);
    final priceController = TextEditingController(
      text: service.price?.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: service.duration?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final data = {
                'title': titleController.text,
                'description': descriptionController.text,
                'price': double.tryParse(priceController.text) ?? 0,
                'duration': int.tryParse(durationController.text) ?? 60,
              };
              ref.read(trainerProfileProvider.notifier).updateService(
                    service.id,
                    data,
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(trainerProfileProvider.notifier).deleteService(service.id);
              Navigator.pop(context);
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
// Packages Section
// ---------------------------------------------------------------------------

class _PackagesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerProfileProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(trainerProfileProvider.notifier).fetchProfile(),
      child: Column(
        children: [
          // Add Package Button & Manage link
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddPackageDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Package'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/trainer/profile/packages'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
          ),

          // Packages List
          Expanded(
            child: state.packages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No packages yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create packages to bundle your services',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.packages.length,
                    itemBuilder: (context, index) {
                      final package = state.packages[index];
                      return _PackageCard(package: package);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddPackageDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final sessionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Package'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Package Name',
                  hintText: 'e.g., 10-Session Bundle',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your package...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: '0.00',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sessionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Sessions',
                  hintText: '10',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final data = {
                'name': nameController.text,
                'description': descriptionController.text,
                'price': double.tryParse(priceController.text) ?? 0,
                'numberOfSessions': int.tryParse(sessionsController.text) ?? 1,
              };
              ref.read(trainerProfileProvider.notifier).addPackage(data);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends ConsumerWidget {
  final Package package;

  const _PackageCard({required this.package});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Expanded(
                  child: Text(
                    package.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditPackageDialog(context, ref);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, ref);
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
            if (package.description != null) ...[
              const SizedBox(height: 8),
              Text(
                package.description!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                Text(
                  package.price.toStringAsFixed(2),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                Text(
                  '${package.numberOfSessions} sessions',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPackageDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: package.name);
    final descriptionController = TextEditingController(text: package.description ?? '');
    final priceController = TextEditingController(text: package.price.toString());
    final sessionsController = TextEditingController(
      text: package.numberOfSessions.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Package'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Package Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sessionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Sessions',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final data = {
                'name': nameController.text,
                'description': descriptionController.text,
                'price': double.tryParse(priceController.text) ?? 0,
                'numberOfSessions': int.tryParse(sessionsController.text) ?? 1,
              };
              ref.read(trainerProfileProvider.notifier).updatePackage(
                    package.id,
                    data,
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: Text('Are you sure you want to delete "${package.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(trainerProfileProvider.notifier).deletePackage(package.id);
              Navigator.pop(context);
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
// Testimonials Section
// ---------------------------------------------------------------------------

class _TestimonialsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerProfileProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(trainerProfileProvider.notifier).fetchProfile(),
      child: Column(
        children: [
          // Add Testimonial Button & Manage link
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddTestimonialDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Testimonial'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/trainer/profile/testimonials'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
          ),

          // Testimonials List
          Expanded(
            child: state.testimonials.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.format_quote,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No testimonials yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add testimonials from your clients',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.testimonials.length,
                    itemBuilder: (context, index) {
                      final testimonial = state.testimonials[index];
                      return _TestimonialCard(testimonial: testimonial);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddTestimonialDialog(BuildContext context, WidgetRef ref) {
    final clientNameController = TextEditingController();
    final testimonialTextController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Testimonial'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: clientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    hintText: 'John Doe',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: testimonialTextController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Testimonial',
                    hintText: 'What did the client say?',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Rating:',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(width: 16),
                    ...List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final data = {
                  'clientName': clientNameController.text,
                  'testimonialText': testimonialTextController.text,
                  'rating': rating,
                };
                ref.read(trainerProfileProvider.notifier).addTestimonial(data);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialCard extends ConsumerWidget {
  final Testimonial testimonial;

  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Expanded(
                  child: Text(
                    testimonial.clientName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (testimonial.rating != null) ...[
                  ...List.generate(
                    testimonial.rating!,
                    (index) => const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _showDeleteConfirmation(context, ref),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              testimonial.testimonialText,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Testimonial'),
        content: Text('Are you sure you want to delete this testimonial from ${testimonial.clientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(trainerProfileProvider.notifier).deleteTestimonial(testimonial.id);
              Navigator.pop(context);
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
// Benefits Section
// ---------------------------------------------------------------------------

class _BenefitsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerProfileProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(trainerProfileProvider.notifier).fetchProfile(),
      child: Column(
        children: [
          // Add Benefit Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => _showAddBenefitDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Benefit'),
            ),
          ),

          // Benefits List
          Expanded(
            child: state.benefits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No benefits yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add benefits of working with you',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.benefits.length,
                    itemBuilder: (context, index) {
                      final benefit = state.benefits[index];
                      return _BenefitCard(benefit: benefit);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddBenefitDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Benefit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Benefit Title',
                  hintText: 'e.g., Personalized Plans',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Describe this benefit...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final data = {
                'title': titleController.text,
                'description': descriptionController.text,
              };
              ref.read(trainerProfileProvider.notifier).addBenefit(data);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends ConsumerWidget {
  final Benefit benefit;

  const _BenefitCard({required this.benefit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.check,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(benefit.title),
        subtitle: benefit.description != null
            ? Text(benefit.description!)
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _showDeleteConfirmation(context, ref),
          tooltip: 'Delete',
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Benefit'),
        content: Text('Are you sure you want to delete "${benefit.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(trainerProfileProvider.notifier).deleteBenefit(benefit.id);
              Navigator.pop(context);
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
// Social Links Section (in TrainerProfileScreen)
// ---------------------------------------------------------------------------

class _SocialLinksSection extends ConsumerStatefulWidget {
  const _SocialLinksSection();

  @override
  ConsumerState<_SocialLinksSection> createState() =>
      _SocialLinksSectionState();
}

class _SocialLinksSectionState extends ConsumerState<_SocialLinksSection> {
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

    return RefreshIndicator(
      onRefresh: () => ref.read(trainerSocialLinksProvider.notifier).fetchLinks(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddLinkDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Link'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/trainer/profile/social-links'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.socialLinks.isEmpty
                ? Center(
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
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.socialLinks.length,
                    itemBuilder: (context, index) {
                      final link = state.socialLinks[index];
                      final platform = SocialPlatform.fromKey(link.platform);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: platform.color.withOpacity(0.15),
                            child: Icon(
                              platform.icon,
                              color: platform.color,
                              size: 20,
                            ),
                          ),
                          title: Text(platform.displayName),
                          subtitle: Text(
                            link.profileUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteConfirmation(context, link),
                            tooltip: 'Delete',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

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
                  _ProfilePlatformPicker(
                    selected: selectedPlatform,
                    onSelected: (key) {
                      setState(() => selectedPlatform = key);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Profile URL *',
                      hintText: 'https://instagram.com/yourprofile',
                      border: OutlineInputBorder(),
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
// External Links Section
// ---------------------------------------------------------------------------

class _ExternalLinksSection extends ConsumerWidget {
  const _ExternalLinksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerExternalLinksProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(trainerExternalLinksProvider.notifier).fetchLinks(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddLinkDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Link'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/trainer/profile/external-links'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.links.isEmpty
                ? Center(
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
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.links.length,
                    itemBuilder: (context, index) {
                      final link = state.links[index];
                      return _ExternalLinkCard(
                        link: link,
                        onDelete: () =>
                            _showDeleteConfirmation(context, ref, link),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddLinkDialog(BuildContext context, WidgetRef ref) {
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
                    hintText: 'Brief description...',
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

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, ExternalLink link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Link'),
        content: Text('Are you sure you want to delete "${link.label}"?'),
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
// External Link Card (used inside profile section)
// ---------------------------------------------------------------------------

class _ExternalLinkCard extends StatelessWidget {
  final ExternalLink link;
  final VoidCallback onDelete;

  const _ExternalLinkCard({
    required this.link,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.link,
          color: theme.colorScheme.primary,
        ),
        title: Text(link.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              link.linkUrl,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (link.description != null &&
                link.description!.isNotEmpty)
              Text(
                link.description!,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.error,
          ),
          onPressed: onDelete,
          tooltip: 'Delete',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transformation Section
// ---------------------------------------------------------------------------

class _TransformationSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerTransformationPhotosProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(trainerTransformationPhotosProvider.notifier).fetchPhotos(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/trainer/profile/transformations'),
                    icon: const Icon(Icons.transform),
                    label: const Text('Manage Photos'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/trainer/profile/transformations'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open'),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.photos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.transform,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transformation photos yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add before/after photos to showcase progress',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: state.photos.length > 4 ? 4 : state.photos.length,
                    itemBuilder: (context, index) {
                      final pair = state.photos[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(pair.beforeImageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        foregroundDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Before',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Minimal platform picker used inside the profile screen dialogs.
class _ProfilePlatformPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _ProfilePlatformPicker({
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