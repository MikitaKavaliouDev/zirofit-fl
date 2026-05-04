import 'package:flutter_test/flutter_test.dart';
import '../helpers/integration_api_client.dart';

/// Integration tests for trainer events API endpoints.
///
/// Prerequisites:
/// - Next.js server running on localhost:3321
/// - Database seeded with test data
///
/// Run with: flutter test test/integration/trainer_events_test.dart
void main() {
  late TestApiClient client;

  setUpAll(() async {
    client = TestApiClient();
    await client.loginAsTrainer();
  });

  tearDownAll(() {
    client.logout();
  });

  group('GET /api/trainer/events', () {
    test('returns events list for authenticated trainer', () async {
      final response = await client.get<Map<String, dynamic>>(
        '/trainer/events',
      );

      expect(response.statusCode, 200);
      final data = response.data;
      expect(data, isNotNull);
      expect(data!['data'], isA<Map>());
    });

    test('returns events with expected structure', () async {
      final response = await client.get<Map<String, dynamic>>(
        '/trainer/events',
      );

      expect(response.statusCode, 200);
      final data = response.data;
      expect(data, isNotNull);
      // Events should have 'events' array
      expect(data!['data']['events'], isA<List>());
    });

    test('returns 401 without authentication', () async {
      final unauthClient = TestApiClient();

      final response = await unauthClient.get<Map<String, dynamic>>(
        '/trainer/events',
      );

      expect(response.statusCode, 401);
    });
  });

  group('POST /api/trainer/events', () {
    test('creates new event with valid data', () async {
      final eventData = {
        'title': 'Test Event',
        'startTime': '2025-06-01T10:00:00Z',
        'endTime': '2025-06-01T11:00:00Z',
        'price': 50.0,
        'capacity': 10,
        'locationName': 'Test Gym',
        'address': '123 Test St',
      };

      final response = await client.post<Map<String, dynamic>>(
        '/trainer/events',
        data: eventData,
      );

      expect(response.statusCode, 201);
      final data = response.data;
      expect(data, isNotNull);
      expect(data!['data'], isA<Map>());
    });

    test('returns 400 with invalid data', () async {
      final invalidData = {
        'title': 'Test Event',
        // Missing required fields
      };

      final response = await client.post<Map<String, dynamic>>(
        '/trainer/events',
        data: invalidData,
      );

      expect(response.statusCode, 400);
    });
  });
}
