import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/explore_event.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/trainer_search_result.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/explore/screens/public_trainer_profile_screen.dart';
import 'package:zirofit_fl/features/explore/widgets/discovery_filter_sheet.dart';

/// Trainer Discovery Screen – full search / filter UI with iOS-style
/// segmented tabs, filter sheet, and contextual empty states.
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

class _TrainerDiscoveryScreenState
    extends ConsumerState<TrainerDiscoveryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(exploreProvider.notifier);
      notifier.loadMetadata();
      notifier.loadUpcomingEvents();
      notifier.loadFeatured();
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
        title: const Text('Discover'),
        actions: [
          // Filter button – turns primary colour when filters are active
          IconButton(
            icon: Icon(
              Icons.tune,
              color: state.hasActiveFilters
                  ? theme.colorScheme.primary
                  : null,
            ),
            onPressed: _showFilterSheet,
            tooltip: 'Filters',
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.push('/client/explore/map'),
            tooltip: 'View map',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Segmented picker ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<DiscoveryType>(
                segments: const [
                  ButtonSegment<DiscoveryType>(
                    value: DiscoveryType.specialists,
                    label: Text('Specialists'),
                    icon: Icon(Icons.person_outline, size: 18),
                  ),
                  ButtonSegment<DiscoveryType>(
                    value: DiscoveryType.events,
                    label: Text('Events'),
                    icon: Icon(Icons.event, size: 18),
                  ),
                  ButtonSegment<DiscoveryType>(
                    value: DiscoveryType.all,
                    label: Text('All'),
                    icon: Icon(Icons.explore, size: 18),
                  ),
                ],
                selected: {state.discoveryType},
                onSelectionChanged: (selected) {
                  ref
                      .read(exploreProvider.notifier)
                      .setDiscoveryType(selected.first);
                },
                showSelectedIcon: false,
              ),
            ),
          ),

          // ── Search bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _searchPlaceholder(state.discoveryType),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(exploreProvider.notifier)
                              .search(query: '');
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
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ── Active filter chips ──────────────────────────────────────
          if (state.hasActiveFilters)
            _ActiveFilterChips(
              state: state,
              onRemoveSort: () =>
                  ref.read(exploreProvider.notifier).setSortBy(null),
              onRemoveLocation: () => ref
                  .read(exploreProvider.notifier)
                  .clearFilters(),
              onRemoveSpecialty: (s) {
                final updated = state.selectedSpecialties
                    .where((e) => e != s)
                    .toList();
                ref.read(exploreProvider.notifier).applyFilters(
                      specialties:
                          updated.isNotEmpty ? updated : null,
                    );
              },
              onRemoveMinRating: () =>
                  ref.read(exploreProvider.notifier).applyFilters(
                        minRating: null,
                      ),
              onClearAll: () =>
                  ref.read(exploreProvider.notifier).clearFilters(),
            ),

          // ── Specialty quick-filter chips ─────────────────────────────
          if (state.specialties.isNotEmpty &&
              state.discoveryType != DiscoveryType.events)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.specialties.length,
                itemBuilder: (context, index) {
                  final specialty = state.specialties[index];
                  final isSelected =
                      specialty == state.selectedSpecialty;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(specialty),
                      selected: isSelected,
                      onSelected: (_) {
                        if (isSelected) {
                          ref
                              .read(exploreProvider.notifier)
                              .setSpecialty(null);
                        } else {
                          ref
                              .read(exploreProvider.notifier)
                              .setSpecialty(specialty);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 4),

          // ── Results ─────────────────────────────────────────────────
          Expanded(
            child: _buildContent(state, theme),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _searchPlaceholder(DiscoveryType type) {
    switch (type) {
      case DiscoveryType.specialists:
        return 'Search specialists…';
      case DiscoveryType.events:
        return 'Search events…';
      case DiscoveryType.all:
        return 'Search trainers & events…';
    }
  }

  Future<void> _showFilterSheet() async {
    await DiscoveryFilterSheet.show(context);
  }

  // ── Content builder ────────────────────────────────────────────────────

  Widget _buildContent(ExploreState state, ThemeData theme) {
    final showEvents = state.discoveryType == DiscoveryType.events ||
        state.discoveryType == DiscoveryType.all;
    final showTrainers = state.discoveryType == DiscoveryType.specialists ||
        state.discoveryType == DiscoveryType.all;

    // Loading state
    if (state.isLoading &&
        state.results.isEmpty &&
        state.upcomingEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (state.error != null &&
        state.results.isEmpty &&
        state.upcomingEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(state.error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(exploreProvider.notifier).search(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty states – contextual
    final hasTrainerResults = state.results.isNotEmpty;
    final hasEventResults = state.upcomingEvents.isNotEmpty ||
        state.featuredEvents.isNotEmpty;

    if (!hasTrainerResults && !hasEventResults) {
      return _buildEmptyState(state, theme);
    }

    // Build combined results list
    final trainerList =
        state.results.isNotEmpty ? state.results : state.trainers;
    final eventList = state.upcomingEvents.isNotEmpty
        ? state.upcomingEvents
        : state.featuredEvents;

    // Determine items to show
    final items = <_DiscoveryItem>[];

    if (showTrainers) {
      for (final t in trainerList) {
        items.add(_DiscoveryItem.trainer(t));
      }
    }

    if (showEvents) {
      for (final e in eventList) {
        items.add(_DiscoveryItem.event(e));
      }
    }

    // Add a "load more" sentinel if trainers have more pages
    final hasTrainerMore =
        showTrainers && state.hasMore && state.results.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => ref.read(exploreProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + (hasTrainerMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            // Load more trigger for trainers
            ref.read(exploreProvider.notifier).loadMore();
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = items[index];
          return item.when(
            trainer: (result) {
              final profile = result is TrainerSearchResult
                  ? _searchResultToProfile(result)
                  : result as Profile;
              return _TrainerResultCard(
                profile: profile,
                onTap: () => _openProfile(profile),
              );
            },
            event: (event) => _EventResultRow(
              event: event,
              onTap: () => _openEvent(event),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ExploreState state, ThemeData theme) {
    final hasSearchQuery =
        state.searchQuery != null && state.searchQuery!.isNotEmpty;
    final hasActiveFilters = state.hasActiveFilters;
    final isEventsTab = state.discoveryType == DiscoveryType.events;
    final isSpecialistsTab =
        state.discoveryType == DiscoveryType.specialists;

    String title;
    String subtitle;
    IconData icon;

    if (isEventsTab) {
      icon = Icons.event_busy;
      title = 'No events found';
      subtitle = hasSearchQuery
          ? 'No events match "${state.searchQuery}". Try a different search.'
          : hasActiveFilters
              ? 'No events match your filters. Try adjusting them.'
              : 'There are no upcoming events in your area yet.';
    } else if (isSpecialistsTab || !isEventsTab) {
      if (hasSearchQuery && hasActiveFilters) {
        icon = Icons.search_off;
        title = 'No specialists found';
        subtitle =
            'No results for "${state.searchQuery}" with current filters. Try broadening your search.';
      } else if (hasSearchQuery) {
        icon = Icons.search_off;
        title = 'No specialists found';
        subtitle =
            'No results for "${state.searchQuery}". Try a different search term.';
      } else if (hasActiveFilters) {
        icon = Icons.filter_alt_off;
        title = 'No filters match';
        subtitle =
            'No specialists match your current filters. Try resetting them.';
      } else {
        icon = Icons.people_outline;
        title = 'No specialists in your area';
        subtitle =
            'There are no specialists available yet. Check back later or try a different location.';
      }
    } else {
      icon = Icons.search_off;
      title = 'Nothing found';
      subtitle =
          'No results match your search. Try adjusting your filters.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasActiveFilters)
              OutlinedButton(
                onPressed: () =>
                    ref.read(exploreProvider.notifier).clearFilters(),
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      ),
    );
  }

  Profile _searchResultToProfile(TrainerSearchResult result) {
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

  void _openEvent(ExploreEvent event) {
    // Placeholder – navigate to event detail when available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event: ${event.title}')),
    );
  }
}

// =============================================================================
// Helper types
// =============================================================================

/// Union-type wrapper so we can mix trainers and events in a single list.
sealed class _DiscoveryItem {
  const _DiscoveryItem();
  factory _DiscoveryItem.trainer(Object trainer) = _TrainerItem;
  factory _DiscoveryItem.event(ExploreEvent event) = _EventItem;

  T when<T>({
    required T Function(Object trainer) trainer,
    required T Function(ExploreEvent event) event,
  });
}

class _TrainerItem extends _DiscoveryItem {
  final Object trainer;
  const _TrainerItem(this.trainer);

  @override
  T when<T>({
    required T Function(Object trainer) trainer,
    required T Function(ExploreEvent event) event,
  }) =>
      trainer(this.trainer);
}

class _EventItem extends _DiscoveryItem {
  final ExploreEvent event;
  const _EventItem(this.event);

  @override
  T when<T>({
    required T Function(Object trainer) trainer,
    required T Function(ExploreEvent event) event,
  }) =>
      event(this.event);
}

// =============================================================================
// Active filter chips widget
// =============================================================================

class _ActiveFilterChips extends StatelessWidget {
  final ExploreState state;
  final VoidCallback onRemoveSort;
  final VoidCallback onRemoveLocation;
  final void Function(String specialty) onRemoveSpecialty;
  final VoidCallback onRemoveMinRating;
  final VoidCallback onClearAll;

  const _ActiveFilterChips({
    required this.state,
    required this.onRemoveSort,
    required this.onRemoveLocation,
    required this.onRemoveSpecialty,
    required this.onRemoveMinRating,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    if (state.sortBy != null) {
      chips.add(_chip(
        theme: theme,
        label: state.sortBy!.label,
        onRemove: onRemoveSort,
      ));
    }
    if (state.locationFilter != null && state.locationFilter!.isNotEmpty) {
      chips.add(_chip(
        theme: theme,
        label: state.locationFilter!,
        icon: Icons.location_on_outlined,
        onRemove: onRemoveLocation,
      ));
    }
    for (final s in state.selectedSpecialties) {
      chips.add(_chip(
        theme: theme,
        label: s,
        onRemove: () => onRemoveSpecialty(s),
      ));
    }
    if (state.minRating != null) {
      chips.add(_chip(
        theme: theme,
        label: 'Rating ≥ ${state.minRating!.toStringAsFixed(1)}',
        icon: Icons.star,
        onRemove: onRemoveMinRating,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClearAll,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required ThemeData theme,
    required String label,
    IconData? icon,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        avatar: icon != null
            ? Icon(icon, size: 14, color: theme.colorScheme.primary)
            : null,
        label: Text(label, style: theme.textTheme.labelSmall),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

// =============================================================================
// Trainer result card
// =============================================================================

class _TrainerResultCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onTap;

  const _TrainerResultCard({
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundImage:
                    profile.profilePhotoPath != null &&
                            profile.profilePhotoPath!.isNotEmpty
                        ? NetworkImage(profile.profilePhotoPath!)
                        : null,
                child: profile.profilePhotoPath == null ||
                        profile.profilePhotoPath!.isEmpty
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.aboutMe ?? 'Trainer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (profile.averageRating != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.star,
                                size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              profile.averageRating!.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (profile.location != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                profile.location!,
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (profile.specialties.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: profile.specialties
                              .take(3)
                              .map(
                                (s) => Chip(
                                  label: Text(s,
                                      style: theme.textTheme.labelSmall),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  labelPadding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Event result row
// =============================================================================

class _EventResultRow extends StatelessWidget {
  final ExploreEvent event;
  final VoidCallback onTap;

  const _EventResultRow({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');
    final dayFormat = DateFormat('MMM d');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Date badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayFormat.format(event.startTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      timeFormat.format(event.startTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (event.locationName != null ||
                        event.address != null)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              event.locationName ?? event.address ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (event.price > 0)
                          Text(
                            event.priceDisplay ??
                                '\$${event.price.toStringAsFixed(0)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else
                          Text(
                            'Free',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(Icons.people_outline,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          '${event.enrolledCount}/${event.capacity}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (event.isNearCapacity) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Almost full',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
