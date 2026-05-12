import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/explore_event.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/explore/providers/map_markers_provider.dart';
import '../../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class _FakeExploreNotifier extends ExploreNotifier {
  _FakeExploreNotifier(ExploreState overriddenState) : super() {
    state = overriddenState;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _createContainer(ExploreState state) {
  return ProviderContainer(
    overrides: [
      exploreProvider
          .overrideWith((ref) => _FakeExploreNotifier(state)),
    ],
  );
}

Profile _profile({
  required String id,
  String? aboutMe,
  double? latitude,
  double? longitude,
  String? profilePhotoPath,
  String? location,
  List<String> specialties = const [],
}) {
  return Profile(
    id: id,
    userId: 'user-$id',
    aboutMe: aboutMe,
    latitude: latitude,
    longitude: longitude,
    profilePhotoPath: profilePhotoPath,
    location: location,
    specialties: specialties,
    businessCurrency: 'PLN',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('mapMarkersProvider', () {
    // =====================================================================
    // Test: Trainers WITH lat/lng produce markers
    // =====================================================================
    test('trainers WITH lat/lng produce trainer markers', () {
      final trainers = [
        _profile(
          id: 't1',
          aboutMe: 'Trainer Alpha',
          latitude: 40.7128,
          longitude: -74.0060,
          specialties: ['Yoga', 'Pilates'],
        ),
        _profile(
          id: 't2',
          aboutMe: 'Trainer Beta',
          latitude: 34.0522,
          longitude: -118.2437,
          specialties: ['HIIT'],
        ),
      ];

      final container = _createContainer(
        ExploreState(trainers: trainers),
      );
      addTearDown(() => container.dispose());

      final markers = container.read(mapMarkersProvider);

      expect(markers.length, 2);
      expect(
        markers.every((m) => m.type == MapMarkerType.trainer),
        isTrue,
      );

      // Verify marker data mapped correctly
      expect(markers[0].id, 'trainer-t1');
      expect(markers[0].latitude, 40.7128);
      expect(markers[0].longitude, -74.0060);
      expect(markers[0].title, 'Trainer Alpha');
      expect(markers[0].trainerId, 't1');

      expect(markers[1].id, 'trainer-t2');
      expect(markers[1].latitude, 34.0522);
      expect(markers[1].longitude, -118.2437);
      expect(markers[1].title, 'Trainer Beta');
      expect(markers[1].trainerId, 't2');
    });

    // =====================================================================
    // Test: Trainers WITHOUT lat/lng are EXCLUDED
    // =====================================================================
    test('trainers WITHOUT lat/lng are excluded', () {
      final trainers = [
        _profile(id: 't1', aboutMe: 'Has coords', latitude: 40.0, longitude: -74.0),
        _profile(id: 't2', aboutMe: 'No lat', longitude: -118.0),
        _profile(id: 't3', aboutMe: 'No lng', latitude: 34.0),
        _profile(id: 't4', aboutMe: 'Neither'),
      ];

      final container = _createContainer(
        ExploreState(trainers: trainers),
      );
      addTearDown(() => container.dispose());

      final markers = container.read(mapMarkersProvider);

      // Only t1 has both lat and lng
      expect(markers.length, 1);
      expect(markers[0].trainerId, 't1');
    });

    // =====================================================================
    // Test: Events WITH matching city produce markers
    // =====================================================================
    test('events WITH matching city with coordinates produce event markers', () {
      final cities = [
        const ExploreCity(
          id: 'city-nyc',
          name: 'New York',
          latitude: 40.7128,
          longitude: -74.0060,
        ),
        const ExploreCity(
          id: 'city-la',
          name: 'Los Angeles',
          latitude: 34.0522,
          longitude: -118.2437,
        ),
      ];

      final events = [
        ExploreEvent(
          id: 'evt-1',
          title: 'Yoga in the Park',
          startTime: DateTime(2024, 6, 1),
          endTime: DateTime(2024, 6, 1, 1),
          cityId: 'city-nyc',
          hostId: 'host-1',
          imageUrl: 'https://example.com/yoga.jpg',
        ),
        ExploreEvent(
          id: 'evt-2',
          title: 'Beach HIIT',
          startTime: DateTime(2024, 6, 2),
          endTime: DateTime(2024, 6, 2, 1),
          cityId: 'city-la',
          hostId: 'host-2',
        ),
      ];

      final container = _createContainer(
        ExploreState(cities: cities, upcomingEvents: events),
      );
      addTearDown(() => container.dispose());

      final markers = container.read(mapMarkersProvider);

      expect(markers.length, 2);
      expect(
        markers.every((m) => m.type == MapMarkerType.event),
        isTrue,
      );

      // Verify marker data mapped correctly
      expect(markers[0].id, 'event-evt-1');
      expect(markers[0].latitude, 40.7128);
      expect(markers[0].longitude, -74.0060);
      expect(markers[0].title, 'Yoga in the Park');
      expect(markers[0].eventId, 'evt-1');
      expect(markers[0].trainerId, 'host-1');
      expect(markers[0].imageUrl, 'https://example.com/yoga.jpg');

      expect(markers[1].id, 'event-evt-2');
      expect(markers[1].latitude, 34.0522);
      expect(markers[1].longitude, -118.2437);
      expect(markers[1].title, 'Beach HIIT');
      expect(markers[1].eventId, 'evt-2');
      expect(markers[1].trainerId, 'host-2');
    });

    // =====================================================================
    // Test: Events WITHOUT matching city are EXCLUDED
    // =====================================================================
    test('events WITHOUT matching city are excluded', () {
      final cities = [
        const ExploreCity(
          id: 'city-nyc',
          name: 'New York',
          latitude: 40.7128,
          longitude: -74.0060,
        ),
      ];

      final events = [
        // Event with null cityId
        ExploreEvent(
          id: 'evt-1',
          title: 'No City',
          startTime: DateTime(2024, 6, 1),
          endTime: DateTime(2024, 6, 1, 1),
          cityId: null,
        ),
        // Event with cityId matching no known city
        ExploreEvent(
          id: 'evt-2',
          title: 'Unknown City',
          startTime: DateTime(2024, 6, 2),
          endTime: DateTime(2024, 6, 2, 1),
          cityId: 'city-unknown',
        ),
        // Event with matching city but city has no coordinates
        ExploreEvent(
          id: 'evt-3',
          title: 'City Without Coords',
          startTime: DateTime(2024, 6, 3),
          endTime: DateTime(2024, 6, 3, 1),
          cityId: 'city-no-coords',
        ),
      ];

      final citiesWithMissing = [
        ...cities,
        const ExploreCity(
          id: 'city-no-coords',
          name: 'Nowhere',
          latitude: null,
          longitude: null,
        ),
      ];

      final container = _createContainer(
        ExploreState(cities: citiesWithMissing, upcomingEvents: events),
      );
      addTearDown(() => container.dispose());

      final markers = container.read(mapMarkersProvider);

      expect(markers.length, 0);
    });

    // =====================================================================
    // Test: Empty state — no markers when no data
    // =====================================================================
    test('empty state produces no markers', () {
      final container = _createContainer(const ExploreState());
      addTearDown(() => container.dispose());

      final markers = container.read(mapMarkersProvider);

      expect(markers, isEmpty);
    });

    // =====================================================================
    // Test: Mixed trainers + events
    // =====================================================================
    test('produces both trainer and event markers when both are present', () {
      final trainers = [
        _profile(
          id: 't1',
          aboutMe: 'A Trainer',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      ];

      final cities = [
        const ExploreCity(
          id: 'city-lon',
          name: 'London',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      ];

      final events = [
        ExploreEvent(
          id: 'evt-1',
          title: 'London Event',
          startTime: DateTime(2024, 7, 1),
          endTime: DateTime(2024, 7, 1, 2),
          cityId: 'city-lon',
        ),
      ];

      final container = _createContainer(
        ExploreState(trainers: trainers, cities: cities, upcomingEvents: events),
      );
      addTearDown(() => container.dispose());

      final markers = container.read(mapMarkersProvider);

      expect(markers.length, 2);

      final trainerMarkers =
          markers.where((m) => m.type == MapMarkerType.trainer).toList();
      final eventMarkers =
          markers.where((m) => m.type == MapMarkerType.event).toList();

      expect(trainerMarkers.length, 1);
      expect(trainerMarkers[0].trainerId, 't1');
      expect(eventMarkers.length, 1);
      expect(eventMarkers[0].eventId, 'evt-1');
    });

    // =====================================================================
    // Test: Trainer uses aboutMe as title, location or specialties as subtitle
    // =====================================================================
    test('trainer marker uses aboutMe as title and location/specialties as subtitle', () {
      final trainers = [
        _profile(
          id: 't1',
          aboutMe: 'John Doe',
          latitude: 40.0,
          longitude: -74.0,
          location: 'New York',
          specialties: ['Yoga', 'Pilates', 'HIIT'],
        ),
        _profile(
          id: 't2',
          aboutMe: null,
          latitude: 34.0,
          longitude: -118.0,
          location: null,
          specialties: ['Strength'],
        ),
      ];

      final container = _createContainer(
        ExploreState(trainers: trainers),
      );
      addTearDown(() => container.dispose());

      final markers = container.read(mapMarkersProvider);

      expect(markers.length, 2);

      // Trainer with aboutMe → uses aboutMe as title
      expect(markers[0].title, 'John Doe');
      // Subtitle: location when available
      expect(markers[0].subtitle, 'New York');

      // Trainer without aboutMe → uses userId as title
      expect(markers[1].title, 'user-t2');
      // Subtitle: specialties when no location (limited to 3)
      expect(markers[1].subtitle, 'Strength');
    });
  });
}
