import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:zirofit_fl/core/providers/location_provider.dart';
import 'package:zirofit_fl/features/events/providers/events_provider.dart';
import 'package:zirofit_fl/features/explore/widgets/map_pin.dart';
import 'package:zirofit_fl/features/events/screens/event_detail_screen.dart';
import 'package:zirofit_fl/data/models/event.dart';

/// Map screen showing event pins on a [FlutterMap] with OpenStreetMap tiles.
///
/// Features:
/// - Category filter chips to narrow displayed events
/// - "My Location" FAB using geolocator
/// - Camera auto-fits to bounds of all visible markers on load
/// - Pin tap navigates to [EventDetailScreen]
class EventMapScreen extends ConsumerStatefulWidget {
  const EventMapScreen({super.key});

  @override
  ConsumerState<EventMapScreen> createState() => _EventMapScreenState();
}

class _EventMapScreenState extends ConsumerState<EventMapScreen> {
  final MapController _mapController = MapController();
  bool _hasFittedBounds = false;
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Workshop',
    'Class',
    'Seminar',
    'Competition',
    'Social',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(eventsProvider);
      if (state.events.isEmpty && !state.isLoading) {
        ref.read(eventsProvider.notifier).fetchEvents();
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
    final state = ref.watch(eventsProvider);
    final theme = Theme.of(context);

    // Filter events by category and valid coordinates.
    final filteredEvents = state.events.where((e) {
      if (e.latitude == null || e.longitude == null) return false;
      if (_selectedCategory != null && e.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    // Fit camera bounds to markers once they load.
    if (filteredEvents.isNotEmpty && !_hasFittedBounds) {
      _hasFittedBounds = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds(filteredEvents);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(eventsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _categories.map((cat) {
                final isSelected = cat == 'All'
                    ? _selectedCategory == null
                    : _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _hasFittedBounds = false;
                        _selectedCategory = cat == 'All' ? null : cat;
                      });
                      ref
                          .read(eventsProvider.notifier)
                          .fetchEvents(category: _selectedCategory);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Map content
          Expanded(
            child: _buildMapContent(filteredEvents, state, theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'event_map_location',
        onPressed: _goToMyLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  /// Builds the map view or loading/empty/error state.
  Widget _buildMapContent(
    List<Event> events,
    EventsState state,
    ThemeData theme,
  ) {
    if (state.isLoading && state.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load events',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(eventsProvider.notifier).fetchEvents(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (events.isEmpty) {
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
              'No events with locations',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // Calculate average center from all event markers.
    final avgLat =
        events.fold<double>(0.0, (s, e) => s + e.latitude!) / events.length;
    final avgLng =
        events.fold<double>(0.0, (s, e) => s + e.longitude!) / events.length;

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
          markers: events.map((event) {
            return Marker(
              point: LatLng(event.latitude!, event.longitude!),
              width: 50,
              height: 65,
              child: GestureDetector(
                onTap: () => _openEventDetail(event),
                child: EventMapPin(imageUrl: event.imageUrl),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Fits the camera to encompass all event markers with padding.
  void _fitBounds(List<Event> events) {
    if (events.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(
      events.map((e) => LatLng(e.latitude!, e.longitude!)).toList(),
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

  /// Navigates to the event detail screen for the tapped event.
  void _openEventDetail(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: event.id),
      ),
    );
  }
}
