import 'package:flutter_test/flutter_test.dart';
import '../helpers/integration_api_client.dart';

/// Integration tests for trainer calendar API endpoints.
///
/// Prerequisites:
/// - Next.js server running on localhost:3321
/// - Database seeded with test data
///
/// Run with: flutter test test/integration/trainer_calendar_test.dart
void main() {
  late TestApiClient client;

  setUpAll(() async {
    client = TestApiClient();
    await client.loginAsTrainer();
  });

  tearDownAll(() {
    client.logout();
  });

  group('GET /api/trainer/calendar', () {
    test('returns calendar events for valid date range', () async {
      final response = await client.get<Map<String, dynamic>>(
        '/trainer/calendar',
        queryParams: {
          'startDate': '2025-01-01T00:00:00Z',
          'endDate': '2025-01-31T23:59:59Z',
        },
      );

      expect(response.statusCode, 200);
      final data = response.data;
      expect(data, isNotNull);
      expect(data!['data'], isA<Map>());
    });

    test('returns 400 without date parameters', () async {
      final response = await client.get<Map<String, dynamic>>(
        '/trainer/calendar',
      );

      expect(response.statusCode, 400);
    });

    test('returns 401 without authentication', () async {
      final unauthClient = TestApiClient();

      final response = await unauthClient.get<Map<String, dynamic>>(
        '/trainer/calendar',
        queryParams: {
          'startDate': '2025-01-01T00:00:00Z',
          'endDate': '2025-01-31T23:59:59Z',
        },
      );

      expect(response.statusCode, 401);
    });
  });

  group('GET /api/trainer/calendar/clients-summary', () {
    test('returns clients summary data', () async {
      final response = await client.get<Map<String, dynamic>>(
        '/trainer/calendar/clients-summary',
      );

      expect(response.statusCode, 200);
      final data = response.data;
      expect(data, isNotNull);
      expect(data!['data'], isA<Map>());
    });
  });

  group('GET /api/trainer/session-creation-data', () {
    test('returns session creation data', () async {
      final response = await client.get<Map<String, dynamic>>(
        '/trainer/session-creation-data',
      );

      expect(response.statusCode, 200);
      final data = response.data;
      expect(data, isNotNull);
      expect(data!['data'], isA<Map>());
    });
  });
}
