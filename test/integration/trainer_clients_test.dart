import 'package:flutter_test/flutter_test.dart';
import '../helpers/integration_api_client.dart';

/// Integration tests for trainer clients API endpoints.
///
/// Prerequisites:
/// - Next.js server running on localhost:3321
/// - Database seeded with test data (trainer with linked clients)
///
/// Run with: flutter test test/integration/trainer_clients_test.dart
void main() {
  late TestApiClient client;

  setUpAll(() async {
    client = TestApiClient();
    await client.loginAsTrainer();
  });

  tearDownAll(() {
    client.logout();
  });

  group('GET /api/trainer/clients', () {
    test('returns clients list for authenticated trainer', () async {
      final response = await client.get<Map<String, dynamic>>(
        '/trainer/clients',
      );

      expect(response.statusCode, 200);
      final data = response.data;
      expect(data, isNotNull);
      expect(data!['data'], isA<List>());
    });

    test('returns 401 without authentication', () async {
      final unauthClient = TestApiClient();

      final response = await unauthClient.get<Map<String, dynamic>>(
        '/trainer/clients',
      );

      expect(response.statusCode, 401);
    });
  });

  group('GET /api/trainer/clients/:id', () {
    test('returns client details with valid id', () async {
      // First get the list to find a client ID
      final listResponse = await client.get<Map<String, dynamic>>(
        '/trainer/clients',
      );
      expect(listResponse.statusCode, 200);

      final clients = listResponse.data?['data'] as List?;
      if (clients != null && clients.isNotEmpty) {
        final clientId = clients.first['id'] as String;

        final response = await client.get<Map<String, dynamic>>(
          '/trainer/clients/$clientId',
        );

        expect(response.statusCode, 200);
        final data = response.data;
        expect(data, isNotNull);
        expect(data!['data'], isA<Map>());
      }
    });
  });

  group('GET /api/trainer/clients/:id/assign-program', () {
    test('returns assign program data for valid client', () async {
      // First get the list to find a client ID
      final listResponse = await client.get<Map<String, dynamic>>(
        '/trainer/clients',
      );
      expect(listResponse.statusCode, 200);

      final clients = listResponse.data?['data'] as List?;
      if (clients != null && clients.isNotEmpty) {
        final clientId = clients.first['id'] as String;

        final response = await client.get<Map<String, dynamic>>(
          '/trainer/clients/$clientId/assign-program',
        );

        expect(response.statusCode, 200);
        final data = response.data;
        expect(data, isNotNull);
        expect(data!['data'], isA<Map>());
      }
    });
  });
}
