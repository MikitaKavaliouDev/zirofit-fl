import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/settings/providers/profile_settings_provider.dart';

// ---------------------------------------------------------------------------
// Profile Settings Screen
// ---------------------------------------------------------------------------

/// Profile settings screen with change tracking and image picker support.
///
/// Mirrors the iOS [ProfileSettingsView] with sections for:
///   - Profile picture (tap to change via camera/gallery)
///   - Personal information (name, email, bio)
///   - Work locations (trainer-only, with add/remove)
///   - Trainer content (philosophy, methodology, certifications, qualifications)
///   - Physical stats (height, weight)
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState
    extends ConsumerState<ProfileSettingsScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _philosophyController = TextEditingController();
  final _methodologyController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _locationController = TextEditingController();

  final _imagePicker = ImagePicker();

  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _philosophyController.dispose();
    _methodologyController.dispose();
    _certificationsController.dispose();
    _qualificationsController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _syncControllers(ProfileSettingsState state) {
    _nameController.text = state.name;
    _bioController.text = state.bio;
    _philosophyController.text = state.philosophy;
    _methodologyController.text = state.methodology;
    _certificationsController.text = state.certifications;
    _qualificationsController.text = state.qualifications;
    _heightController.text =
        state.height > 0 ? state.height.toStringAsFixed(1) : '';
    _weightController.text =
        state.weight > 0 ? state.weight.toStringAsFixed(1) : '';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSettingsProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTrainer = authState.isTrainer;

    // Load profile on first build
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileSettingsProvider.notifier).loadProfile(
              isTrainer: isTrainer,
            );
      });
    }

    // Sync controllers when state changes from load or reset
    ref.listen<ProfileSettingsState>(profileSettingsProvider, (_, next) {
      if (!next.isLoading && _nameController.text != next.name) {
        _syncControllers(next);
      }
    });

    return PopScope(
      canPop: !state.isChanged,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard(context);
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (state.isChanged) {
                final shouldPop = await _confirmDiscard(context);
                if (shouldPop && context.mounted) {
                  context.pop();
                }
              } else {
                context.pop();
              }
            },
          ),
          actions: [
            _SaveButton(
              isSaving: state.isSaving,
              canSave: state.isChanged,
            ),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(profileSettingsProvider.notifier)
                    .loadProfile(isTrainer: state.isTrainer),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Feedback banners
                      if (state.successMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _MessageBanner(
                            message: state.successMessage!,
                            type: _BannerType.success,
                            onDismiss: () {
                              ref
                                  .read(profileSettingsProvider.notifier)
                                  .loadProfile(isTrainer: state.isTrainer);
                            },
                          ),
                        ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _MessageBanner(
                            message: state.error!,
                            type: _BannerType.error,
                            onDismiss: () {
                              ref
                                  .read(profileSettingsProvider.notifier)
                                  .loadProfile(isTrainer: state.isTrainer);
                            },
                          ),
                        ),

                      // -- Avatar Section --
                      _AvatarCard(
                        avatarUrl: state.pendingAvatar != null
                            ? null
                            : state.avatarUrl,
                        pendingFile: state.pendingAvatar,
                        onPickImage: _pickImage,
                        onClear: () {
                          ref
                              .read(profileSettingsProvider.notifier)
                              .clearPendingAvatar();
                        },
                      ),
                      const SizedBox(height: 24),

                      // -- Personal Information --
                      const _SectionHeader(
                        icon: Icons.person_outline,
                        title: 'Personal Information',
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon:
                                      Icon(Icons.badge_outlined),
                                ),
                                onChanged: (v) {
                                  ref
                                      .read(profileSettingsProvider.notifier)
                                      .setName(v);
                                },
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: TextEditingController(
                                    text: state.email),
                                enabled: false,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon:
                                      const Icon(Icons.email_outlined),
                                  filled: true,
                                  fillColor: theme
                                      .colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // -- Bio --
                      const _SectionHeader(
                        icon: Icons.info_outline,
                        title: 'Bio',
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _bioController,
                            maxLines: 4,
                            maxLength: 500,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Tell clients about yourself...',
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                            onChanged: (v) {
                              ref
                                  .read(profileSettingsProvider.notifier)
                                  .setBio(v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // -- Work Locations (trainer only) --
                      if (state.isTrainer) ...[
                        const _SectionHeader(
                          icon: Icons.location_on_outlined,
                          title: 'Work Locations',
                        ),
                        const SizedBox(height: 12),
                        _LocationsCard(
                          locations: state.locations,
                          onAdd: () => _showAddLocationDialog(context),
                          onRemove: (index) {
                            ref
                                .read(profileSettingsProvider.notifier)
                                .removeLocation(index);
                          },
                        ),
                        const SizedBox(height: 24),

                        // -- Philosophy --
                        const _SectionHeader(
                          icon: Icons.psychology_outlined,
                          title: 'Philosophy',
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _philosophyController,
                              maxLines: 4,
                              maxLength: 1000,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText:
                                    'Your training philosophy...',
                                border: OutlineInputBorder(),
                                counterText: '',
                              ),
                              onChanged: (v) {
                                ref
                                    .read(profileSettingsProvider.notifier)
                                    .setPhilosophy(v);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // -- Methodology --
                        const _SectionHeader(
                          icon: Icons.account_tree_outlined,
                          title: 'Methodology',
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _methodologyController,
                              maxLines: 4,
                              maxLength: 1000,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText:
                                    'Your training methodology...',
                                border: OutlineInputBorder(),
                                counterText: '',
                              ),
                              onChanged: (v) {
                                ref
                                    .read(profileSettingsProvider.notifier)
                                    .setMethodology(v);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // -- Certifications --
                        const _SectionHeader(
                          icon: Icons.verified_outlined,
                          title: 'Certifications',
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _certificationsController,
                              maxLines: 4,
                              maxLength: 1000,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText:
                                    'List your certifications...',
                                border: OutlineInputBorder(),
                                counterText: '',
                              ),
                              onChanged: (v) {
                                ref
                                    .read(profileSettingsProvider.notifier)
                                    .setCertifications(v);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // -- Qualifications --
                        const _SectionHeader(
                          icon: Icons.school_outlined,
                          title: 'Qualifications',
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _qualificationsController,
                              maxLines: 4,
                              maxLength: 1000,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText:
                                    'List your qualifications...',
                                border: OutlineInputBorder(),
                                counterText: '',
                              ),
                              onChanged: (v) {
                                ref
                                    .read(profileSettingsProvider.notifier)
                                    .setQualifications(v);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // -- Physical Stats --
                      const _SectionHeader(
                        icon: Icons.monitor_weight_outlined,
                        title: 'Physical Stats',
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _heightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Height (cm)',
                                    prefixIcon:
                                        Icon(Icons.height_outlined),
                                    hintText: 'e.g. 175',
                                  ),
                                  onChanged: (v) {
                                    final parsed =
                                        double.tryParse(v.trim());
                                    ref
                                        .read(
                                            profileSettingsProvider.notifier)
                                        .setHeight(parsed ?? 0);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _weightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Weight (kg)',
                                    prefixIcon:
                                        Icon(Icons.monitor_weight_outlined),
                                    hintText: 'e.g. 70',
                                  ),
                                  onChanged: (v) {
                                    final parsed =
                                        double.tryParse(v.trim());
                                    ref
                                        .read(
                                            profileSettingsProvider.notifier)
                                        .setWeight(parsed ?? 0);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // -- Save Button --
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (state.isChanged && !state.isSaving)
                              ? () => _saveProfile()
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: state.isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Image picker
  // --------------------------------------------------------------------------

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Change Profile Photo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      ref.read(profileSettingsProvider.notifier).setPendingAvatar(pickedFile);
    }
  }

  // --------------------------------------------------------------------------
  // Add location dialog
  // --------------------------------------------------------------------------

  Future<void> _showAddLocationDialog(BuildContext context) async {
    _locationController.clear();
    final location = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Location'),
        content: TextField(
          controller: _locationController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. New York, NY',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_locationController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, _locationController.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (location != null && mounted) {
      ref.read(profileSettingsProvider.notifier).addLocation(location);
    }
  }

  // --------------------------------------------------------------------------
  // Save
  // --------------------------------------------------------------------------

  Future<void> _saveProfile() async {
    final success =
        await ref.read(profileSettingsProvider.notifier).saveProfile();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Unsaved changes confirmation
  // --------------------------------------------------------------------------

  Future<bool> _confirmDiscard(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// =============================================================================
// Save button in AppBar
// =============================================================================

class _SaveButton extends ConsumerWidget {
  final bool isSaving;
  final bool canSave;

  const _SaveButton({
    required this.isSaving,
    required this.canSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEnabled = canSave && !isSaving;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: isEnabled
                    ? () => _saveProfile(ref, context)
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                ),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.38),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _saveProfile(WidgetRef ref, BuildContext context) async {
    final success =
        await ref.read(profileSettingsProvider.notifier).saveProfile();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
    }
  }
}

// =============================================================================
// Avatar Card
// =============================================================================

class _AvatarCard extends StatelessWidget {
  final String? avatarUrl;
  final XFile? pendingFile;
  final VoidCallback onPickImage;
  final VoidCallback onClear;

  const _AvatarCard({
    required this.avatarUrl,
    required this.pendingFile,
    required this.onPickImage,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            const _SectionHeader(
              icon: Icons.photo_camera_outlined,
              title: 'Profile Picture',
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onPickImage,
              child: Stack(
                children: [
                  // Avatar circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer,
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildAvatarContent(colorScheme),
                    ),
                  ),

                  // Camera overlay badge
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onPickImage,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Change Photo'),
            ),
            if (pendingFile != null)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                label: Text(
                  'Remove',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent(ColorScheme colorScheme) {
    // Pending image takes priority
    if (pendingFile != null) {
      return Image.file(
        File(pendingFile!.path),
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    }

    // Existing avatar URL
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(colorScheme),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Icon(
      Icons.person_rounded,
      size: 56,
      color: colorScheme.onPrimaryContainer,
    );
  }
}

// =============================================================================
// Locations Card
// =============================================================================

class _LocationsCard extends StatelessWidget {
  final List<String> locations;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _LocationsCard({
    required this.locations,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (locations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No locations added yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(locations.length, (i) {
                  return Chip(
                    avatar: Icon(
                      Icons.location_on,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    label: Text(locations[i]),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => onRemove(i),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Message Banner
// =============================================================================

enum _BannerType { success, error }

class _MessageBanner extends StatelessWidget {
  final String message;
  final _BannerType type;
  final VoidCallback onDismiss;

  const _MessageBanner({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = type == _BannerType.success
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;
    final fgColor = type == _BannerType.success
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;
    final icon =
        type == _BannerType.success ? Icons.check_circle : Icons.error;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fgColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: fgColor),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: fgColor),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Section Header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}
