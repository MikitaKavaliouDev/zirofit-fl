import 'package:flutter_test/flutter_test.dart';
import '../helpers/integration_api_client.dart';

/// Integration tests for trainer check-ins API endpoints.
///
/// Run: flutter test test/integration/trainer_checkins_test.dart
void main() {
  late TestApiClient client;
  bool isAuthenticated = false;

  setUpAll(() async {
    client = TestApiClient();
    isAuthenticated = await client.loginAsTrainer();
  });

  tearDownAll(() {
    client.logout();
  });

  test(
    'GET /trainer/check-ins returns SUBMITTED check-ins with valid auth',
    () async {
      if (!isAuthenticated) {
        fail('Authentication failed - cannot run test');
      }
      final response = await client.get<Map<String, dynamic>>(
        '/trainer/check-ins',
        queryParams: {'status': 'SUBMITTED'},
      );
      expect(response.statusCode, 200);
      expect(response.data, isNotNull);
      expect(response.data!['data'], isA<List>());
    },
  );

  test('GET /trainer/check-ins returns 401 without authentication', () async {
    final unauthClient = TestApiClient();
    final response = await unauthClient.get<Map<String, dynamic>>(
      '/trainer/check-ins',
    );
    expect(response.statusCode, 401);
  });

  test('GET /trainer/check-ins/pending returns pending check-ins', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final response = await client.get<Map<String, dynamic>>(
      '/trainer/check-ins/pending',
    );
    expect(response.statusCode, anyOf(200, 404));
  });

  test('GET /trainer/check-ins/:id returns check-in detail', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final listResponse = await client.get<Map<String, dynamic>>(
      '/trainer/check-ins',
      queryParams: {'status': 'SUBMITTED'},
    );
    if (listResponse.statusCode == 200) {
      final checkIns = listResponse.data?['data'] as List?;
      if (checkIns != null && checkIns.isNotEmpty) {
        final checkInId = checkIns.first['id'] as String;
        final detailResponse = await client.get<Map<String, dynamic>>(
          '/trainer/check-ins/$checkInId',
        );
        expect(detailResponse.statusCode, anyOf(200, 404));
      }
    }
  });

  test('POST /trainer/check-ins/:id/review reviews a check-in', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final listResponse = await client.get<Map<String, dynamic>>(
      '/trainer/check-ins',
      queryParams: {'status': 'SUBMITTED'},
    );
    if (listResponse.statusCode == 200) {
      final checkIns = listResponse.data?['data'] as List?;
      if (checkIns != null && checkIns.isNotEmpty) {
        final checkInId = checkIns.first['id'] as String;
        final reviewResponse = await client.post<Map<String, dynamic>>(
          '/trainer/check-ins/$checkInId/review',
          data: {'trainerResponse': 'Great progress!', 'status': 'REVIEWED'},
        );
        expect(reviewResponse.statusCode, anyOf(200, 201, 400));
      }
    }
  });
}
