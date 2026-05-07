import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/settings/providers/data_sharing_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late DataSharingNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = DataSharingNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Test 1: Initial state has all sharing enabled
  // ---------------------------------------------------------------------------

  test('initial state has all sharing enabled with forever expiration', () {
    expect(notifier.state.shareWorkouts, true);
    expect(notifier.state.shareMeasurements, true);
    expect(notifier.state.sharePhotos, true);
    expect(notifier.state.shareCheckIns, true);
    expect(notifier.state.expirationType, 'forever');
    expect(notifier.state.expirationDate, isNull);
    expect(notifier.state.isSaving, false);
    expect(notifier.state.error, isNull);
  });

  // ---------------------------------------------------------------------------
  // Test 2: fetchSettings populates from API
  // ---------------------------------------------------------------------------

  test('fetchSettings populates state from API on success', () async {
    final responseData = <String, dynamic>{
      'data': <String, dynamic>{
        'shareWorkouts': false,
        'shareMeasurements': true,
        'sharePhotos': false,
        'shareCheckIns': true,
        'expirationType': 'date',
        'expirationDate': '2026-12-31T23:59:59.000Z',
      },
    };

    when(() => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => responseData);

    await notifier.fetchSettings();

    expect(notifier.state.isSaving, false);
    expect(notifier.state.shareWorkouts, false);
    expect(notifier.state.shareMeasurements, true);
    expect(notifier.state.sharePhotos, false);
    expect(notifier.state.shareCheckIns, true);
    expect(notifier.state.expirationType, 'date');
    expect(notifier.state.expirationDate, isNotNull);
    expect(notifier.state.error, isNull);
  });

  test('fetchSettings handles direct response without data wrapper', () async {
    final responseData = <String, dynamic>{
      'shareWorkouts': false,
      'shareMeasurements': true,
      'sharePhotos': true,
      'shareCheckIns': false,
      'expirationType': 'forever',
    };

    when(() => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => responseData);

    await notifier.fetchSettings();

    expect(notifier.state.shareWorkouts, false);
    expect(notifier.state.shareMeasurements, true);
    expect(notifier.state.shareCheckIns, false);
  });

  test('fetchSettings uses defaults when response fields are missing', () async {
    final responseData = <String, dynamic>{
      'data': <String, dynamic>{},
    };

    when(() => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => responseData);

    await notifier.fetchSettings();

    expect(notifier.state.isSaving, false);
    expect(notifier.state.shareWorkouts, true); // default
    expect(notifier.state.shareMeasurements, true); // default
    expect(notifier.state.sharePhotos, true); // default
    expect(notifier.state.shareCheckIns, true); // default
    expect(notifier.state.expirationType, 'forever'); // default
  });

  // ---------------------------------------------------------------------------
  // Test 3: toggleCategory flips a specific category
  // ---------------------------------------------------------------------------

  test('toggleCategory flips shareWorkouts', () {
    expect(notifier.state.shareWorkouts, true);
    notifier.toggleCategory('workouts');
    expect(notifier.state.shareWorkouts, false);
    notifier.toggleCategory('workouts');
    expect(notifier.state.shareWorkouts, true);
  });

  test('toggleCategory flips shareMeasurements', () {
    expect(notifier.state.shareMeasurements, true);
    notifier.toggleCategory('measurements');
    expect(notifier.state.shareMeasurements, false);
  });

  test('toggleCategory flips sharePhotos', () {
    expect(notifier.state.sharePhotos, true);
    notifier.toggleCategory('photos');
    expect(notifier.state.sharePhotos, false);
  });

  test('toggleCategory flips shareCheckIns', () {
    expect(notifier.state.shareCheckIns, true);
    notifier.toggleCategory('checkIns');
    expect(notifier.state.shareCheckIns, false);
  });

  test('toggleCategory does not affect other categories', () {
    notifier.toggleCategory('workouts');
    expect(notifier.state.shareWorkouts, false);
    expect(notifier.state.shareMeasurements, true);
    expect(notifier.state.sharePhotos, true);
    expect(notifier.state.shareCheckIns, true);
  });

  // ---------------------------------------------------------------------------
  // Test 4: setExpiration stores type and optional date
  // ---------------------------------------------------------------------------

  test('setExpiration with forever type clears date', () {
    notifier.setExpiration('date', DateTime(2026, 12, 31));
    expect(notifier.state.expirationType, 'date');
    expect(notifier.state.expirationDate, DateTime(2026, 12, 31));

    notifier.setExpiration('forever');
    expect(notifier.state.expirationType, 'forever');
    expect(notifier.state.expirationDate, isNull);
  });

  test('setExpiration with date type stores the date', () {
    final date = DateTime(2027, 6, 15);
    notifier.setExpiration('date', date);
    expect(notifier.state.expirationType, 'date');
    expect(notifier.state.expirationDate, date);
  });

  test('setExpiration without date defaults to null expirationDate', () {
    notifier.setExpiration('date');
    expect(notifier.state.expirationType, 'date');
    expect(notifier.state.expirationDate, isNull);
  });

  // ---------------------------------------------------------------------------
  // Test 5: saveSettings sends PUT with all fields
  // ---------------------------------------------------------------------------

  test('saveSettings sends PUT with current state and clears isSaving', () async {
    // Set up some state
    notifier.toggleCategory('workouts');
    notifier.toggleCategory('photos');
    notifier.setExpiration('date', DateTime(2026, 12, 31));

    when(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          body: any(named: 'body'),
        )).thenAnswer((_) async => <String, dynamic>{});

    await notifier.saveSettings();

    expect(notifier.state.isSaving, false);
    expect(notifier.state.error, isNull);

    verify(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          body: {
            'shareWorkouts': false,
            'shareMeasurements': true,
            'sharePhotos': false,
            'shareCheckIns': true,
            'expirationType': 'date',
            'expirationDate': DateTime(2026, 12, 31).toIso8601String(),
          },
        )).called(1);
  });

  test('saveSettings does not include expirationDate when type is forever',
      () async {
    when(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          body: any(named: 'body'),
        )).thenAnswer((_) async => <String, dynamic>{});

    await notifier.saveSettings();

    verify(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          body: {
            'shareWorkouts': true,
            'shareMeasurements': true,
            'sharePhotos': true,
            'shareCheckIns': true,
            'expirationType': 'forever',
          },
        )).called(1);
  });

  // ---------------------------------------------------------------------------
  // Test 6: resetToDefaults restores defaults
  // ---------------------------------------------------------------------------

  test('resetToDefaults restores all fields to initial values', () {
    // Change some state first
    notifier.toggleCategory('workouts');
    notifier.toggleCategory('photos');
    notifier.setExpiration('date', DateTime(2026, 12, 31));

    // Verify it changed
    expect(notifier.state.shareWorkouts, false);
    expect(notifier.state.sharePhotos, false);
    expect(notifier.state.expirationType, 'date');

    // Reset
    notifier.resetToDefaults();

    // Verify defaults restored
    expect(notifier.state.shareWorkouts, true);
    expect(notifier.state.shareMeasurements, true);
    expect(notifier.state.sharePhotos, true);
    expect(notifier.state.shareCheckIns, true);
    expect(notifier.state.expirationType, 'forever');
    expect(notifier.state.expirationDate, isNull);
    expect(notifier.state.isSaving, false);
    expect(notifier.state.error, isNull);
  });

  // ---------------------------------------------------------------------------
  // Test 7: Error handling
  // ---------------------------------------------------------------------------

  test('fetchSettings sets error on failure', () async {
    when(() => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          queryParams: any(named: 'queryParams'),
        )).thenThrow(Exception('Server error'));

    await notifier.fetchSettings();

    expect(notifier.state.isSaving, false);
    expect(notifier.state.error, isNotNull);
  });

  test('saveSettings sets error on failure', () async {
    when(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          body: any(named: 'body'),
        )).thenThrow(Exception('Save failed'));

    await notifier.saveSettings();

    expect(notifier.state.isSaving, false);
    expect(notifier.state.error, isNotNull);
  });

  test('saveSettings preserves optimistic state on failure', () async {
    notifier.toggleCategory('workouts');
    notifier.setExpiration('date', DateTime(2026, 12, 31));

    when(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          body: any(named: 'body'),
        )).thenThrow(Exception('Save failed'));

    await notifier.saveSettings();

    // State should still reflect the optimistic values
    expect(notifier.state.shareWorkouts, false);
    expect(notifier.state.expirationType, 'date');
    expect(notifier.state.error, isNotNull);
  });

  test('fetchSettings clears previous error before fetching', () async {
    // First make it fail to set an error
    when(() => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          queryParams: any(named: 'queryParams'),
        )).thenThrow(Exception('First error'));

    await notifier.fetchSettings();
    expect(notifier.state.error, isNotNull);

    // Now make it succeed
    when(() => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.clientSharing,
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => <String, dynamic>{
          'data': <String, dynamic>{
            'shareWorkouts': true,
            'shareMeasurements': true,
            'sharePhotos': true,
            'shareCheckIns': true,
            'expirationType': 'forever',
          },
        });

    await notifier.fetchSettings();
    expect(notifier.state.error, isNull);
  });
}
