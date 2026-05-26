import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/core/providers/location_provider.dart';
import 'package:zirofit_fl/data/models/explore_event.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/explore/widgets/map_pin.dart';
import 'package:zirofit_fl/features/events/screens/event_detail_screen.dart';
import 'package:zirofit_fl/features/explore/screens/public_trainer_profile_screen.dart';

/// Internal model for a marketplace map pin combining data from both
/// event and trainer sources.
class _MarketplacePin {
  final String id;
  final bool isEvent;
  final double latitude;
  final double longitude;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? eventId;
  final String? trainerId;

  const _MarketplacePin({
    required this.id,
    required this.isEvent,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.eventId,
    this.trainerId,
  });
}

/// Map view sub-widget for the marketplace screen.
///
/// Shows a [FlutterMap] with:
/// - [EventMapPin] markers for events that have location coordinates
/// - [TrainerMapPin] markers for trainers with latitude/longitude
/// - Tap any pin to open a bottom sheet with summary + navigate action
/// - My Location FAB to center on device location
class MarketplaceMapView extends ConsumerStatefulWidget {
  final String searchQuery;
  final String? selectedCategory;

  const MarketplaceMapView({
    super.key,
    required this.searchQuery,
    this.selectedCategory,
  });

  @override
  ConsumerState<MarketplaceMapView> createState() => _MarketplaceMapViewState();
}

class _MarketplaceMapViewState extends ConsumerState<MarketplaceMapView> {
  final MapController _mapController = MapController();
  bool _hasFittedBounds = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final locService = ref.read(locationServiceProvider);
      final location = locService.userLocation;
      if (location != null && mounted) {
        _mapController.move(location, 14);
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreProvider);
    final pins = _buildPins(state);
    final theme = Theme.of(context);

    // Fit bounds to pins once loaded
    if (pins.isNotEmpty && !_hasFittedBounds) {
      _hasFittedBounds = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds(pins);
      });
    }

    if (pins.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No events or trainers with locations',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // Calculate average center for initial map position
    final avgLat =
        pins.fold<double>(0.0, (s, p) => s + p.latitude) / pins.length;
    final avgLng =
        pins.fold<double>(0.0, (s, p) => s + p.longitude) / pins.length;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(avgLat, avgLng),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.zirofit.app',
            ),
            MarkerLayer(
              markers: pins.map((pin) {
                return Marker(
                  point: LatLng(pin.latitude, pin.longitude),
                  width: 50,
                  height: 65,
                  child: GestureDetector(
                    onTap: () => _showPinBottomSheet(pin, state),
                    child: pin.isEvent
                        ? EventMapPin(imageUrl: pin.imageUrl)
                        : TrainerMapPin(photoUrl: pin.imageUrl),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // My Location FAB
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'marketplace_location',
            onPressed: _goToMyLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  /// Builds a list of [_MarketplacePin] from explore state data.
  List<_MarketplacePin> _buildPins(ExploreState state) {
    final pins = <_MarketplacePin>[];
    final query = widget.searchQuery.toLowerCase().trim();

    // ── Event pins ──────────────────────────────────────────────────────
    // Build city lookup map
    final cityById = <String, ExploreCity>{};
    for (final city in state.cities) {
      cityById[city.id] = city;
    }

    var events = state.featuredEvents;
    // Apply search filter
    if (query.isNotEmpty) {
      events = events.where((e) {
        return e.title.toLowerCase().contains(query) ||
            (e.hostName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    // Apply category filter
    if (widget.selectedCategory != null) {
      events = events
          .where((e) =>
              e.category?.toLowerCase() ==
              widget.selectedCategory!.toLowerCase())
          .toList();
    }

    for (final event in events) {
      if (event.cityId == null) {
        // Also check if event has locationName but no city — skip
        continue;
      }
      final city = cityById[event.cityId];
      final lat = city?.latitude;
      final lng = city?.longitude;
      if (lat == null || lng == null) continue;

      pins.add(_MarketplacePin(
        id: 'event-${event.id}',
        isEvent: true,
        latitude: lat,
        longitude: lng,
        title: event.title,
        subtitle: event.locationName ?? city?.name,
        imageUrl: event.imageUrl,
        eventId: event.id,
      ));
    }

    // ── Trainer pins ────────────────────────────────────────────────────
    var trainers = state.trainers;
    // Apply search filter
    if (query.isNotEmpty) {
      trainers = trainers.where((t) {
        return t.aboutMe?.toLowerCase().contains(query) ?? false;
      }).toList();
    }

    for (final trainer in trainers) {
      final lat = trainer.latitude;
      final lng = trainer.longitude;
      if (lat == null || lng == null) continue;

      pins.add(_MarketplacePin(
        id: 'trainer-${trainer.id}',
        isEvent: false,
        latitude: lat,
        longitude: lng,
        title: trainer.aboutMe ?? 'Trainer',
        subtitle: trainer.specialties.take(2).join(', '),
        imageUrl: trainer.profilePhotoPath,
        trainerId: trainer.id,
      ));
    }

    return pins;
  }

  /// Fits the camera to encompass all pins with padding.
  void _fitBounds(List<_MarketplacePin> pins) {
    if (pins.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(
      pins.map((p) => LatLng(p.latitude, p.longitude)).toList(),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  /// Moves the map camera to the device's current location.
  Future<void> _goToMyLocation() async {
    final locService = ref.read(locationServiceProvider);
    final position = await locService.requestLocation();
    if (position != null && mounted) {
      _mapController.move(LatLng(position.latitude, position.longitude), 14);
    }
  }

  // ---------------------------------------------------------------------------
  // Pin tap → bottom sheet
  // ---------------------------------------------------------------------------

  void _showPinBottomSheet(_MarketplacePin pin, ExploreState state) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        if (pin.isEvent) {
          return _buildEventBottomSheet(ctx, pin, state);
        } else {
          return _buildTrainerBottomSheet(ctx, pin);
        }
      },
    );
  }

  Widget _buildTrainerBottomSheet(
      BuildContext context, _MarketplacePin pin) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo
          CircleAvatar(
            radius: 40,
            backgroundImage: pin.imageUrl != null
                ? NetworkImage(pin.imageUrl!)
                : null,
            child: pin.imageUrl == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          // Name
          Text(pin.title, style: theme.textTheme.titleLarge),
          // Specialties
          if (pin.subtitle != null && pin.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pin.subtitle!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          // Action
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (pin.trainerId != null) {
                _navigateToTrainerProfile(pin.trainerId!);
              }
            },
            child: const Text('View Profile'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEventBottomSheet(
    BuildContext context,
    _MarketplacePin pin,
    ExploreState state,
  ) {
    final theme = Theme.of(context);

    // Look up the full event for date/time display
    final event = state.featuredEvents
        .where((e) => e.id == pin.eventId)
        .firstOrNull;
    final String? timeDisplay = event != null
        ? DateFormat('EEE, MMM d · HH:mm').format(event.startTime)
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image
          CircleAvatar(
            radius: 40,
            backgroundImage: pin.imageUrl != null
                ? NetworkImage(pin.imageUrl!)
                : null,
            child: pin.imageUrl == null
                ? const Icon(Icons.event, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          // Event title
          Text(pin.title, style: theme.textTheme.titleLarge),
          // Time
          if (timeDisplay != null) ...[
            const SizedBox(height: 4),
            Text(
              timeDisplay,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          // Location subtitle (fallback if no event time found)
          if (timeDisplay == null &&
              pin.subtitle != null &&
              pin.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pin.subtitle!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          // Action
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (pin.eventId != null) {
                _navigateToEventDetail(pin.eventId!);
              }
            },
            child: const Text('View Event'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _navigateToTrainerProfile(String trainerId) {
    final state = ref.read(exploreProvider);
    final trainer =
        state.trainers.where((t) => t.id == trainerId).firstOrNull;

    if (trainer != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicTrainerProfileScreen(trainer: trainer),
        ),
      );
    }
  }

  void _navigateToEventDetail(String eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: eventId),
      ),
    );
  }
}
