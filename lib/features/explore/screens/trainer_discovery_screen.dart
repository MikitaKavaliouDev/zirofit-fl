import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/trainer_search_result.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/explore/screens/public_trainer_profile_screen.dart';

/// Trainer Discovery Screen - full search/filter UI.
///
/// Usage:
/// ```dart
/// Navigate to '/client/explore/discovery'
/// ```
class TrainerDiscoveryScreen extends ConsumerStatefulWidget {
  const TrainerDiscoveryScreen({super.key});

  @override
  ConsumerState<TrainerDiscoveryScreen> createState() =>
      _TrainerDiscoveryScreenState();
}

class _TrainerDiscoveryScreenState extends ConsumerState<TrainerDiscoveryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-load data if needed
    Future.microtask(() {
      final notifier = ref.read(exploreProvider.notifier);
      notifier.loadMetadata();
      notifier.loadUpcomingEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Trainers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.push('/client/explore/map'),
            tooltip: 'View map',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search trainers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(exploreProvider.notifier).search(query: '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onSubmitted: (query) {
                ref.read(exploreProvider.notifier).search(query: query);
              },
            ),
          ),

          // Category filter chips
          if (state.specialties.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.specialties.length,
                itemBuilder: (context, index) {
                  final specialty = state.specialties[index];
                  final isSelected = specialty == state.selectedSpecialty;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(specialty),
                      selected: isSelected,
                      onSelected: (_) {
                        if (isSelected) {
                          ref.read(exploreProvider.notifier).setSpecialty(null);
                        } else {
                          ref.read(exploreProvider.notifier).setSpecialty(specialty);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _buildContent(state, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ExploreState state, ThemeData theme) {
    if (state.isLoading && state.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(state.error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(exploreProvider.notifier).search(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final results = state.results;
    if (results.isEmpty && state.trainers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('No trainers found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your filters',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // Show results or fallback to featured trainers
    final displayList = results.isNotEmpty ? results : state.trainers;

    return RefreshIndicator(
      onRefresh: () => ref.read(exploreProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayList.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= displayList.length) {
            // Load more trigger
            ref.read(exploreProvider.notifier).loadMore();
            return const Center(child: CircularProgressIndicator());
          }

          final result = displayList[index];
          final profile = result is TrainerSearchResult
              ? _searchResultToProfile(result)
              : result as Profile;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: profile.profilePhotoPath != null && profile.profilePhotoPath!.isNotEmpty
                    ? NetworkImage(profile.profilePhotoPath!)
                    : null,
                child: profile.profilePhotoPath == null || profile.profilePhotoPath!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(profile.aboutMe ?? 'Trainer'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile.specialties.isNotEmpty)
                    Text(
                      profile.specialties.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (profile.location != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            profile.location!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profile.averageRating != null) ...[
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    Text(profile.averageRating!.toStringAsFixed(1)),
                  ],
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _openProfile(profile),
            ),
          );
        },
      ),
    );
  }

  Profile _searchResultToProfile(TrainerSearchResult result) {
    // Convert search result to profile for display
    return Profile(
      id: result.id,
      userId: result.id,
      aboutMe: result.name,
      profilePhotoPath: result.avatarUrl,
      specialties: result.specialties,
      averageRating: result.rating,
      location: result.location,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _openProfile(Profile trainer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicTrainerProfileScreen(trainer: trainer),
      ),
    );
  }
}