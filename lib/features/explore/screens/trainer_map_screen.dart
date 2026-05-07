import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/explore/screens/public_trainer_profile_screen.dart';

/// Trainer Map Screen - placeholder for future map integration.
///
/// Currently shows a list view of trainer locations. Future: Google Maps/Mapbox integration.
class TrainerMapScreen extends ConsumerWidget {
  const TrainerMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exploreProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.pop(),
            tooltip: 'List view',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map placeholder banner
          Container(
            height: 200,
            width: double.infinity,
            color: theme.colorScheme.primaryContainer,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map,
                        size: 48,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Map coming soon',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View trainer locations on the map',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Floating "Switch to list" button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FilledButton.tonal(
                    onPressed: () => context.pop(),
                    child: const Text('Switch to List'),
                  ),
                ),
              ],
            ),
          ),

          // Trainer locations list (as fallback)
          Expanded(
            child: state.trainers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No trainers with locations',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.trainers.length,
                    itemBuilder: (context, index) {
                      final trainer = state.trainers[index];
                      final hasLocation = trainer.latitude != null && trainer.longitude != null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: trainer.profilePhotoPath != null
                                ? NetworkImage(trainer.profilePhotoPath!)
                                : null,
                            child: trainer.profilePhotoPath == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(trainer.aboutMe ?? 'Trainer'),
                          subtitle: hasLocation
                              ? Text(
                                  '${trainer.latitude!.toStringAsFixed(2)}, ${trainer.longitude!.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodySmall,
                                )
                              : Text(
                                  'Location not available',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                          trailing: hasLocation
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          onTap: hasLocation
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PublicTrainerProfileScreen(trainer: trainer),
                                    ),
                                  );
                                }
                              : null,
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