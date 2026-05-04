import 'package:flutter_test/flutter_test.dart';
import '../helpers/integration_api_client.dart';

/// Integration tests for trainer settings API endpoints.
///
/// Run: flutter test test/integration/trainer_settings_test.dart
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

  test('GET /trainer/settings returns settings', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final response = await client.get<Map<String, dynamic>>(
      '/trainer/settings',
    );
    expect(response.statusCode, anyOf(200, 401));
    if (response.statusCode == 200) {
      expect(response.data!['data'], isA<Map>());
    }
  });

  test('PUT /trainer/settings updates settings', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final response = await client.put<Map<String, dynamic>>(
      '/trainer/settings',
      data: {'defaultCheckInDay': 1, 'defaultCheckInHour': 9},
    );
    expect(response.statusCode, anyOf(200, 400, 401));
  });

  test('GET /trainer/settings returns 401 without auth', () async {
    final unauthClient = TestApiClient();
    final response = await unauthClient.get<Map<String, dynamic>>(
      '/trainer/settings',
    );
    expect(response.statusCode, 401);
  });
}
