import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/explore_event.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/events/screens/event_detail_screen.dart';
import 'package:zirofit_fl/features/explore/screens/public_trainer_profile_screen.dart';

/// List view sub-widget for the marketplace screen.
///
/// Shows two sections:
/// 1. Events — cards with title, date, location, price, image
/// 2. Featured trainers — cards with name, specialty, rating
///
/// Supports filtering by [searchQuery] and [selectedCategory].
class MarketplaceListView extends ConsumerWidget {
  final String searchQuery;
  final String? selectedCategory;

  const MarketplaceListView({
    super.key,
    required this.searchQuery,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exploreProvider);
    final theme = Theme.of(context);

    // Filter events
    var events = state.featuredEvents;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      events = events.where((e) {
        return e.title.toLowerCase().contains(query) ||
            (e.hostName?.toLowerCase().contains(query) ?? false) ||
            (e.locationName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    if (selectedCategory != null) {
      events = events
          .where((e) =>
              e.category?.toLowerCase() == selectedCategory!.toLowerCase())
          .toList();
    }

    // Filter trainers
    var trainers = state.trainers;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      trainers = trainers.where((t) {
        return t.aboutMe?.toLowerCase().contains(query) ?? false;
      }).toList();
    }

    if (state.isLoading && state.featuredEvents.isEmpty && state.trainers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.featuredEvents.isEmpty && state.trainers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load marketplace', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(state.error!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(exploreProvider.notifier).loadFeatured(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (events.isEmpty && trainers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty ? 'No results found' : 'No events or trainers yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try a different search term.'
                  : 'Check back later for new listings.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(exploreProvider.notifier).loadFeatured(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Events section
          if (events.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Events',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...events.map((event) => _EventCard(
                  event: event,
                  onTap: () => _openEventDetail(context, event),
                )),
            const SizedBox(height: 16),
          ],

          // Featured Trainers section
          if (trainers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Featured Trainers',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...trainers.map((trainer) => _TrainerCard(
                  trainer: trainer,
                  onTap: () => _openTrainerProfile(context, trainer),
                )),
          ],
        ],
      ),
    );
  }

  void _openEventDetail(BuildContext context, ExploreEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: event.id),
      ),
    );
  }

  void _openTrainerProfile(BuildContext context, Profile trainer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicTrainerProfileScreen(trainer: trainer),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Event card
// ---------------------------------------------------------------------------

class _EventCard extends StatelessWidget {
  final ExploreEvent event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                      ? Image.network(
                          event.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _eventPlaceholder(theme),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _eventPlaceholder(theme);
                          },
                        )
                      : _eventPlaceholder(theme),
                ),
              ),
              const SizedBox(width: 12),
              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Date/time
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateFormat.format(event.startTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Location
                    if (event.locationName != null &&
                        event.locationName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.locationName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Price + category row
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (event.priceDisplay != null &&
                            event.priceDisplay!.isNotEmpty)
                          Text(
                            event.priceDisplay!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else
                          Text(
                            event.price > 0
                                ? '${event.price.toStringAsFixed(2)} ${event.currency}'
                                : 'Free',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: event.price > 0
                                  ? theme.colorScheme.primary
                                  : Colors.green,
                            ),
                          ),
                        const Spacer(),
                        if (event.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              event.category!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Chevron
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventPlaceholder(ThemeData theme) {
    return Container(
      width: 72,
      height: 72,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.event,
        size: 28,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trainer card
// ---------------------------------------------------------------------------

class _TrainerCard extends StatelessWidget {
  final Profile trainer;
  final VoidCallback onTap;

  const _TrainerCard({required this.trainer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundImage:
                    trainer.profilePhotoPath != null &&
                            trainer.profilePhotoPath!.isNotEmpty
                        ? NetworkImage(trainer.profilePhotoPath!)
                        : null,
                child: trainer.profilePhotoPath == null ||
                        trainer.profilePhotoPath!.isEmpty
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verified badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            trainer.aboutMe ?? 'Trainer',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trainer.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    // Specialties
                    if (trainer.specialties.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        trainer.specialties.take(3).join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Rating + location row
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Rating
                        if (trainer.averageRating != null) ...[
                          Icon(Icons.star,
                              size: 14, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(
                            trainer.averageRating!.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Location
                        if (trainer.location != null) ...[
                          Icon(Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              trainer.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Chevron
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
