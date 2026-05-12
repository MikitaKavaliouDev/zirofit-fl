import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/core/providers/location_provider.dart';
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
    // Sequentially: 1) request location, 2) load data with location context.
    Future.microtask(() async {
      final notifier = ref.read(exploreProvider.notifier);

      // Step 1: Request geolocation permission and detect city.
      await _detectUserCityAndSetLocation(notifier);

      // Step 2: Now load data — API calls will include the location filter.
      notifier.loadFeatured();
      notifier.loadMetadata();
      notifier.loadUpcomingEvents();
    });
  }

  /// Requests geolocation permission, reverse-geocodes to a city name,
  /// and updates the explore state with the detected location.
  ///
  /// Uses [updateLocation] (no search triggered) so that the subsequent
  /// [loadFeatured] / [loadUpcomingEvents] calls include the location
  /// context. Falls back silently if permission is denied or location
  /// is unavailable — the screen still loads data without a filter.
  Future<void> _detectUserCityAndSetLocation(
      ExploreNotifier notifier) async {
    final locService = ref.read(locationServiceProvider);
    final position = await locService.requestLocation();
    if (position != null && locService.currentCity != null && mounted) {
      notifier.updateLocation(
        locService.currentCity!,
        position.latitude,
        position.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreProvider);
    final theme = Theme.of(context);

    // Loading state
    if (state.isLoading && state.trainers.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (state.error != null && state.trainers.isEmpty) {
      return Scaffold(
        body: Center(
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
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            // Tab bar
            TabBar(
              tabs: const [
                Tab(text: 'Events'),
                Tab(text: 'Trainers'),
              ],
              labelColor: theme.colorScheme.primary,
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _buildEventsTab(state, theme),
                  _buildTrainersTab(state, theme),
                ],
              ),
            ),
          ],
        ),
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
      // Update location without triggering search, then reload explore data.
      notifier.updateLocation(
        selectedCity.name,
        selectedCity.latitude,
        selectedCity.longitude,
      );
      notifier.loadFeatured();
      notifier.loadUpcomingEvents();
    }
  }

  Widget _buildEventsTab(ExploreState state, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => ref.read(exploreProvider.notifier).loadFeatured(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Featured Events
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
        ],
      ),
    );
  }

  Widget _buildTrainersTab(ExploreState state, ThemeData theme) {
    if (state.trainers.isEmpty) {
      return _buildEmptyTrainersState(theme);
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

  Widget _buildEmptyTrainersState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No trainers available',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'There are no trainers in your area yet. Check back later or try a different location.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/client/explore/discovery'),
              child: const Text('Browse All Trainers'),
            ),
          ],
        ),
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