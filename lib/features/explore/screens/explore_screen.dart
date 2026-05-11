import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/explore/screens/public_trainer_profile_screen.dart';
import 'package:zirofit_fl/features/explore/widgets/featured_trainers_section.dart';
import 'package:zirofit_fl/features/explore/widgets/featured_events_section.dart';
import 'package:zirofit_fl/features/explore/widgets/browse_by_category_section.dart';
import 'package:zirofit_fl/features/explore/widgets/floating_explore_header.dart';
import 'package:zirofit_fl/features/explore/widgets/upcoming_events_section.dart';
import 'package:zirofit_fl/features/explore/widgets/city_picker_sheet.dart';

/// Main Explore screen - matches iOS PersonalExploreView behavior.
///
/// Sections:
/// - Featured Trainers (horizontal scroll → PublicTrainerProfileScreen)
/// - Featured Events (horizontal scroll → EventDetailScreen)
/// - Browse by Category (filter chips)
/// - Trainers Near You (horizontal scroll → TrainerDiscoveryScreen)
/// - Floating header (city + search + map)
///
/// Usage: Add route to GoRouter and wire into ClientShell.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(exploreProvider.notifier);
      // Load all needed data in parallel
      notifier.loadFeatured();
      notifier.loadMetadata();
      notifier.loadUpcomingEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Floating header
          FloatingExploreHeader(
            selectedCity: state.locationFilter,
            onCityTap: () => _showCityPicker(),
            onSearchTap: () {
              context.push('/client/explore/discovery');
            },
            onMapTap: () {
              context.push('/client/explore/map');
            },
          ),
          // Content
          Expanded(
            child: _buildContent(state, theme),
          ),
        ],
      ),
    );
  }

  Future<void> _showCityPicker() async {
    // Load cities if needed
    final notifier = ref.read(exploreProvider.notifier);
    if (ref.read(exploreProvider).cities.isEmpty) {
      await notifier.loadMetadata();
    }

    final selectedCity = await CityPickerSheet.show(context);
    if (selectedCity != null) {
      notifier.setLocation(selectedCity.name, selectedCity.latitude, selectedCity.longitude);
    }
  }

  Widget _buildContent(ExploreState state, ThemeData theme) {
    if (state.isLoading && state.trainers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.trainers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(state.error!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(exploreProvider.notifier).fetchFeatured(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(exploreProvider.notifier).loadFeatured(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Featured Trainers
          if (state.trainers.isNotEmpty) ...[
            FeaturedTrainersSection(
              trainers: state.trainers.take(5).toList(),
              onTrainerTap: (trainer) => _openTrainerProfile(trainer),
            ),
            const SizedBox(height: 24),
          ],

          // Featured Events (placeholder - uses exploreProvider's featured events if available)
          if (state.featuredEvents.isNotEmpty) ...[
            FeaturedEventsSection(
              events: state.featuredEvents.take(5).toList(),
              onEventTap: (event) {
                context.push('/client/events/${event.id}');
              },
            ),
            const SizedBox(height: 24),
          ],

          // Upcoming Events (grouped by date)
          if (state.upcomingEvents.isNotEmpty) ...[
            UpcomingEventsSection(
              events: state.upcomingEvents,
              onEventTap: (event) {
                context.push('/client/events/${event.id}');
              },
            ),
            const SizedBox(height: 24),
          ],

          // Browse by Category
          if (state.specialties.isNotEmpty) ...[
            BrowseByCategorySection(
              categories: state.specialties,
              selectedCategory: state.selectedSpecialty,
              onCategoryTap: (category) {
                ref.read(exploreProvider.notifier).setSpecialty(category);
              },
            ),
            const SizedBox(height: 24),
          ],

          // Trainers Near You
          _buildNearbySection(state, theme),
        ],
      ),
    );
  }

  Widget _buildNearbySection(ExploreState state, ThemeData theme) {
    // Use state.trainers as the primary source for nearby trainers
    final nearbyTrainers = state.trainers;
    if (nearbyTrainers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trainers Near You',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/client/explore/discovery'),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: nearbyTrainers.length.clamp(0, 5),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final trainer = nearbyTrainers[index];
              return _NearbyTrainerCard(
                trainer: trainer,
                onTap: () => _openTrainerProfile(trainer),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openTrainerProfile(Profile trainer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicTrainerProfileScreen(trainer: trainer),
      ),
    );
  }
}

class _NearbyTrainerCard extends StatelessWidget {
  final Profile trainer;
  final VoidCallback onTap;

  const _NearbyTrainerCard({
    required this.trainer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 100,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: trainer.profilePhotoPath != null && trainer.profilePhotoPath!.isNotEmpty
                  ? NetworkImage(trainer.profilePhotoPath!)
                  : null,
              child: trainer.profilePhotoPath == null || trainer.profilePhotoPath!.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              trainer.aboutMe ?? 'Trainer',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (trainer.location != null) ...[
              const SizedBox(height: 2),
              Text(
                trainer.location!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}