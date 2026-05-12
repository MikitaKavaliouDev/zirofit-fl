import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';

// ---------------------------------------------------------------------------
// Map marker model
// ---------------------------------------------------------------------------

enum MapMarkerType { trainer, event }

class MapMarker {
  final String id;
  final MapMarkerType type;
  final double latitude;
  final double longitude;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? trainerId;
  final String? eventId;

  const MapMarker({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.trainerId,
    this.eventId,
  });
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Derives map marker data from [ExploreState].
///
/// - Trainers with valid `latitude`/`longitude` → trainer markers
/// - Events with a matching city (by [ExploreEvent.cityId] ↔ [ExploreCity.id])
///   that has valid coordinates → event markers
final mapMarkersProvider = Provider<List<MapMarker>>((ref) {
  final state = ref.watch(exploreProvider);
  final markers = <MapMarker>[];

  // ── Trainer markers ─────────────────────────────────────────────────
  for (final trainer in state.trainers) {
    final lat = trainer.latitude;
    final lng = trainer.longitude;
    if (lat == null || lng == null) continue;

    markers.add(MapMarker(
      id: 'trainer-${trainer.id}',
      type: MapMarkerType.trainer,
      latitude: lat,
      longitude: lng,
      title: trainer.aboutMe ?? trainer.userId,
      subtitle: trainer.location ?? trainer.specialties.take(3).join(', '),
      imageUrl: trainer.profilePhotoPath,
      trainerId: trainer.id,
    ));
  }

  // ── Event markers ───────────────────────────────────────────────────
  // Build a lookup map for fast city resolution.
  final cityById = <String, ExploreCity>{};
  for (final city in state.cities) {
    cityById[city.id] = city;
  }

  for (final event in state.upcomingEvents) {
    if (event.cityId == null) continue;

    final city = cityById[event.cityId];
    final lat = city?.latitude;
    final lng = city?.longitude;
    if (lat == null || lng == null) continue;

    markers.add(MapMarker(
      id: 'event-${event.id}',
      type: MapMarkerType.event,
      latitude: lat,
      longitude: lng,
      title: event.title,
      subtitle: event.locationName ?? city?.name,
      imageUrl: event.imageUrl,
      eventId: event.id,
      trainerId: event.hostId,
    ));
  }

  return markers;
});

// ---------------------------------------------------------------------------
// Map filter mode
// ---------------------------------------------------------------------------

enum MapFilterMode { all, trainers, events }

final mapFilterModeProvider = StateProvider<MapFilterMode>((ref) => MapFilterMode.all);

/// Filters [mapMarkersProvider] by [mapFilterModeProvider].
final mapFilteredMarkersProvider = Provider<List<MapMarker>>((ref) {
  final markers = ref.watch(mapMarkersProvider);
  final mode = ref.watch(mapFilterModeProvider);

  switch (mode) {
    case MapFilterMode.all:
      return markers;
    case MapFilterMode.trainers:
      return markers.where((m) => m.type == MapMarkerType.trainer).toList();
    case MapFilterMode.events:
      return markers.where((m) => m.type == MapMarkerType.event).toList();
  }
});
