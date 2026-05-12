import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/core/providers/location_provider.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/explore/providers/map_markers_provider.dart';
import 'package:zirofit_fl/features/explore/widgets/map_pin.dart';
import 'package:zirofit_fl/features/explore/screens/public_trainer_profile_screen.dart';
import 'package:zirofit_fl/features/events/screens/event_detail_screen.dart';

/// Map screen with [FlutterMap] showing trainer/event markers and a fallback
/// list view toggled via the AppBar action button.
///
/// Tapping a marker opens a bottom sheet with quick details and a navigation
/// button to the full profile / event detail screen.
class TrainerMapScreen extends ConsumerStatefulWidget {
  const TrainerMapScreen({super.key});

  @override
  ConsumerState<TrainerMapScreen> createState() => _TrainerMapScreenState();
}

class _TrainerMapScreenState extends ConsumerState<TrainerMapScreen> {
  final MapController _mapController = MapController();
  bool _isListView = false;
  bool _hasFittedBounds = false;
  bool _showFilterMenu = false;

  @override
  void initState() {
    super.initState();
    // If a location was already obtained (e.g. during bootstrap or a previous
    // screen visit), center the map on it immediately.
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
    final markers = ref.watch(mapFilteredMarkersProvider);
    final state = ref.watch(exploreProvider);
    final theme = Theme.of(context);

    // Fit camera bounds to markers once they load.
    if (markers.isNotEmpty && !_hasFittedBounds) {
      _hasFittedBounds = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds(markers);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Map'),
        actions: [
          IconButton(
            icon: Icon(_isListView ? Icons.map : Icons.list),
            onPressed: () => setState(() => _isListView = !_isListView),
            tooltip: _isListView ? 'Switch to Map' : 'Switch to List',
          ),
          IconButton(
            icon: const Icon(Icons.line_weight),
            onPressed: () => setState(() => _showFilterMenu = !_showFilterMenu),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isListView
              ? _buildListView(state, theme)
              : _buildMapView(markers, state, theme),
          if (_showFilterMenu)
            Positioned(
              top: 8,
              right: 8,
              child: Card(
                elevation: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterOption('All', MapFilterMode.all),
                    _buildFilterOption('Trainers', MapFilterMode.trainers),
                    _buildFilterOption('Events', MapFilterMode.events),
                  ],
                ),
              ),
            ),
          if (!_isListView)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'location',
                onPressed: _goToMyLocation,
                child: const Icon(Icons.my_location),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Map view
  // ---------------------------------------------------------------------------

  Widget _buildMapView(
    List<MapMarker> markers,
    ExploreState state,
    ThemeData theme,
  ) {
    if (markers.isEmpty) {
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
              'No trainers or events with locations',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // Calculate average center from all markers.
    final avgLat =
        markers.fold<double>(0.0, (s, m) => s + m.latitude) / markers.length;
    final avgLng =
        markers.fold<double>(0.0, (s, m) => s + m.longitude) / markers.length;

    return FlutterMap(
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
          markers: markers.map((m) {
            return Marker(
              point: LatLng(m.latitude, m.longitude),
              width: 50,
              height: 65,
              child: GestureDetector(
                onTap: () => _showMarkerBottomSheet(m),
                child: m.type == MapMarkerType.trainer
                    ? TrainerMapPin(photoUrl: m.imageUrl)
                    : EventMapPin(imageUrl: m.imageUrl),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Fits the camera to encompass all markers with padding.
  void _fitBounds(List<MapMarker> markers) {
    if (markers.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(
      markers.map((m) => LatLng(m.latitude, m.longitude)).toList(),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  /// Builds a tappable filter option for the filter dropdown overlay.
  Widget _buildFilterOption(String label, MapFilterMode mode) {
    final currentMode = ref.read(mapFilterModeProvider);
    final isActive = currentMode == mode;

    return InkWell(
      onTap: () {
        ref.read(mapFilterModeProvider.notifier).state = mode;
        setState(() => _showFilterMenu = false);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (isActive) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ],
        ),
      ),
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
  // List view (fallback — preserved from original implementation)
  // ---------------------------------------------------------------------------

  Widget _buildListView(ExploreState state, ThemeData theme) {
    if (state.trainers.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.trainers.length,
      itemBuilder: (context, index) {
        final trainer = state.trainers[index];
        final hasLocation =
            trainer.latitude != null && trainer.longitude != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  trainer.profilePhotoPath != null &&
                          trainer.profilePhotoPath!.isNotEmpty
                      ? NetworkImage(trainer.profilePhotoPath!)
                      : null,
              child: trainer.profilePhotoPath == null ||
                      trainer.profilePhotoPath!.isEmpty
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
                    decoration: const BoxDecoration(
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
                        builder: (_) =>
                            PublicTrainerProfileScreen(trainer: trainer),
                      ),
                    );
                  }
                : null,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Marker tap → bottom sheet
  // ---------------------------------------------------------------------------

  void _showMarkerBottomSheet(MapMarker marker) {
    final currentState = ref.read(exploreProvider);

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        if (marker.type == MapMarkerType.trainer) {
          return _buildTrainerBottomSheet(ctx, marker);
        } else {
          return _buildEventBottomSheet(ctx, marker, currentState);
        }
      },
    );
  }

  Widget _buildTrainerBottomSheet(BuildContext context, MapMarker marker) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo
          CircleAvatar(
            radius: 40,
            backgroundImage: marker.imageUrl != null
                ? NetworkImage(marker.imageUrl!)
                : null,
            child: marker.imageUrl == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          // Name
          Text(marker.title, style: theme.textTheme.titleLarge),
          // Specialties
          if (marker.subtitle != null && marker.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              marker.subtitle!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          // Action
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToTrainerProfile(marker.trainerId!);
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
    MapMarker marker,
    ExploreState state,
  ) {
    final theme = Theme.of(context);

    // Look up the full event for date/time display.
    final event =
        state.upcomingEvents.where((e) => e.id == marker.eventId).firstOrNull;
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
            backgroundImage: marker.imageUrl != null
                ? NetworkImage(marker.imageUrl!)
                : null,
            child: marker.imageUrl == null
                ? const Icon(Icons.event, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          // Event title
          Text(marker.title, style: theme.textTheme.titleLarge),
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
              marker.subtitle != null &&
              marker.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              marker.subtitle!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          // Action
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEventDetail(marker.eventId!);
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
