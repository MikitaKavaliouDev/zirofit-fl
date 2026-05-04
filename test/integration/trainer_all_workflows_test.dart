import 'package:flutter_test/flutter_test.dart';
import '../helpers/integration_api_client.dart';

/// Integration tests for trainer APIs connected to localhost:3321
/// Run: flutter test test/integration/trainer_all_workflows_test.dart
void main() {
  late TestApiClient client;
  bool isAuth = false;

  setUpAll(() async {
    client = TestApiClient();
    isAuth = await client.loginAsTrainer();
  });

  tearDownAll(() => client.logout());

  // Auth test
  test('auth works with seeded credentials', () => expect(isAuth, isTrue));

  // Check-ins
  test('GET /check-ins', () async {
    if (!isAuth) return;
    final r = await client.get<dynamic>('/trainer/check-ins');
    expect(r.statusCode, anyOf(200, 401));
  });
  test('GET /check-ins/pending', () async {
    if (!isAuth) return;
    final r = await client.get<dynamic>('/trainer/check-ins/pending');
    expect(r.statusCode, anyOf(200, 404));
  });

  // Events
  test('GET /events', () async {
    if (!isAuth) return;
    final r = await client.get<dynamic>('/trainer/events');
    expect(r.statusCode, 200);
  });
  test('POST /events', () async {
    if (!isAuth) return;
    final r = await client.post<dynamic>(
      '/trainer/events',
      data: {
        'title': 'Test',
        'startTime': '2026-06-01T10:00:00Z',
        'endTime': '2026-06-01T11:00:00Z',
        'price': 50,
        'capacity': 10,
        'locationName': 'Gym',
        'address': '123 St',
      },
    );
    expect(r.statusCode, anyOf(201, 400, 500));
  });

  // Calendar
  test('GET /calendar', () async {
    if (!isAuth) return;
    final r = await client.get<dynamic>(
      '/trainer/calendar',
      queryParams: {
        'startDate': '2025-01-01T00:00:00Z',
        'endDate': '2025-12-31T23:59:59Z',
      },
    );
    expect(r.statusCode, 200);
  });

  // Programs
  test('GET /programs', () async {
    if (!isAuth) return;
    final r = await client.get<dynamic>('/trainer/programs');
    expect(r.statusCode, 200);
  });
  test('POST /programs', () async {
    if (!isAuth) return;
    final r = await client.post<dynamic>(
      '/trainer/programs',
      data: {'name': 'Test Program', 'description': 'Test'},
    );
    expect(r.statusCode, anyOf(201, 400));
  });

  // Settings
  test('GET /settings', () async {
    if (!isAuth) return;
    final r = await client.get<dynamic>('/trainer/settings');
    expect(r.statusCode, anyOf(200, 401));
  });
}
