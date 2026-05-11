import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zirofit_fl/data/models/transformation_photo_pair.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_transformation_photos_provider.dart';

class TrainerTransformationPhotosScreen extends ConsumerStatefulWidget {
  const TrainerTransformationPhotosScreen({super.key});

  @override
  ConsumerState<TrainerTransformationPhotosScreen> createState() =>
      _TrainerTransformationPhotosScreenState();
}

class _TrainerTransformationPhotosScreenState
    extends ConsumerState<TrainerTransformationPhotosScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerTransformationPhotosProvider.notifier).fetchPhotos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerTransformationPhotosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transformation Photos'),
        actions: [
          if (!state.isUploading)
            TextButton.icon(
              onPressed: () => _showAddPhotoFlow(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add'),
            ),
        ],
      ),
      body: _buildBody(theme, state),
    );
  }

  Widget _buildBody(ThemeData theme, TrainerTransformationPhotosState state) {
    if (state.isLoading && state.photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.photos.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(trainerTransformationPhotosProvider.notifier).fetchPhotos(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: state.photos.length,
        itemBuilder: (context, index) {
          final pair = state.photos[index];
          return _TransformationPairCard(
            pair: pair,
            onTap: () => _openFullScreenViewer(context, pair, index),
            onDelete: () => _showDeleteConfirmation(context, pair),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
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
            'Add before/after photos to showcase your clients\' progress',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddPhotoFlow(context),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add Photos'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add Photo Flow
  // ---------------------------------------------------------------------------

  Future<void> _showAddPhotoFlow(BuildContext context) async {
    XFile? beforeImage;
    XFile? afterImage;
    final captionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    final currentlyUploading =
        ref.read(trainerTransformationPhotosProvider).isUploading;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Transformation Photos'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Before photo picker
                  Text(
                    'Before Photo *',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  _PhotoPickerTile(
                    image: beforeImage,
                    label: 'Tap to select Before photo',
                    onPick: () => _pickImage().then((picked) {
                      if (picked != null) {
                        setDialogState(() => beforeImage = picked);
                      }
                    }),
                  ),
                  const SizedBox(height: 16),

                  // After photo picker
                  Text(
                    'After Photo *',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  _PhotoPickerTile(
                    image: afterImage,
                    label: 'Tap to select After photo',
                    onPick: () => _pickImage().then((picked) {
                      if (picked != null) {
                        setDialogState(() => afterImage = picked);
                      }
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Caption
                  TextFormField(
                    controller: captionController,
                    decoration: const InputDecoration(
                      labelText: 'Caption',
                      hintText: 'e.g., 12-week transformation',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                      ),
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
            if (currentlyUploading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              FilledButton.icon(
                onPressed: beforeImage != null && afterImage != null
                    ? () async {
                        final error = await ref
                            .read(trainerTransformationPhotosProvider.notifier)
                            .uploadPhotos(
                              beforeImagePath: beforeImage!.path,
                              afterImagePath: afterImage!.path,
                              caption: captionController.text.isNotEmpty
                                  ? captionController.text
                                  : null,
                              date: selectedDate,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        }
                      }
                    : null,
                icon: const Icon(Icons.upload),
                label: const Text('Upload'),
              ),
          ],
        ),
      ),
    );
  }

  Future<XFile?> _pickImage() async {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  }

  // ---------------------------------------------------------------------------
  // Full Screen Photo Viewer
  // ---------------------------------------------------------------------------

  void _openFullScreenViewer(
    BuildContext context,
    TransformationPhotoPair pair,
    int index,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoViewer(pair: pair),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete Confirmation
  // ---------------------------------------------------------------------------

  void _showDeleteConfirmation(
      BuildContext context, TransformationPhotoPair pair) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photos'),
        content: Text(
          pair.caption != null
              ? 'Are you sure you want to delete transformation "${pair.caption}"?'
              : 'Are you sure you want to delete this transformation photo pair?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(trainerTransformationPhotosProvider.notifier)
                  .deletePhoto(pair.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transformation photos deleted')),
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
// Transformation Pair Card
// ---------------------------------------------------------------------------

class _TransformationPairCard extends StatelessWidget {
  final TransformationPhotoPair pair;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransformationPairCard({
    required this.pair,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Side-by-side before/after thumbnails
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildThumbnail(pair.beforeImageUrl, 'Before'),
                  ),
                  Container(
                    width: 2,
                    color: theme.colorScheme.primary,
                  ),
                  Expanded(
                    child: _buildThumbnail(pair.afterImageUrl, 'After'),
                  ),
                ],
              ),
            ),
            // Caption and date row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pair.caption != null)
                          Text(
                            pair.caption!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          '${pair.createdAt.year}-${pair.createdAt.month.toString().padLeft(2, '0')}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String imageUrl, String label) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 24),
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey[100],
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Photo Picker Tile (used in add dialog)
// ---------------------------------------------------------------------------

class _PhotoPickerTile extends StatelessWidget {
  final XFile? image;
  final String label;
  final VoidCallback onPick;

  const _PhotoPickerTile({
    required this.image,
    required this.label,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(image!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full Screen Photo Viewer
// ---------------------------------------------------------------------------

class _FullScreenPhotoViewer extends StatelessWidget {
  final TransformationPhotoPair pair;

  const _FullScreenPhotoViewer({required this.pair});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          pair.caption ?? 'Transformation',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Before photo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFullPhoto(pair.beforeImageUrl, 'Before', theme),
            ),
            const SizedBox(height: 8),
            // VS divider
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VS',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 8),
            // After photo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFullPhoto(pair.afterImageUrl, 'After', theme),
            ),
            const SizedBox(height: 16),
            // Date
            Text(
              '${pair.createdAt.year}-${pair.createdAt.month.toString().padLeft(2, '0')}-${pair.createdAt.day.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPhoto(String imageUrl, String label, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: 200,
            errorBuilder: (_, _, _) => Container(
              color: Colors.grey[900],
              height: 200,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                color: Colors.grey[900],
                height: 200,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ],
    );
  }
}
