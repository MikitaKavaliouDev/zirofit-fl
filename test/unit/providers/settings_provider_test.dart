import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/settings/providers/settings_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late SettingsNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = SettingsNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  test('initial state has expected defaults', () {
    expect(notifier.state.isLoading, false);
    expect(notifier.state.isSaving, false);
    expect(notifier.state.defaultCheckInDay, 0);
    expect(notifier.state.defaultCheckInHour, 9);
    expect(notifier.state.weightUnit, 'KG');
    expect(notifier.state.error, isNull);
    expect(notifier.state.successMessage, isNull);
  });

  // ---------------------------------------------------------------------------
  // loadSettings – success
  // ---------------------------------------------------------------------------

  test('loadSettings populates state on success', () async {
    final responseData = <String, dynamic>{
      'data': <String, dynamic>{
        'defaultCheckInDay': 2,
        'defaultCheckInHour': 14,
        'weightUnit': 'LB',
      },
    };

    when(() => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.profileMe,
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => responseData);

    await notifier.loadSettings();

    expect(notifier.state.isLoading, false);
    expect(notifier.state.defaultCheckInDay, 2);
    expect(notifier.state.defaultCheckInHour, 14);
    expect(notifier.state.weightUnit, 'LB');
    expect(notifier.state.error, isNull);
  });

  test('loadSettings uses defaults when response fields are missing', () async {
    final responseData = <String, dynamic>{
      'data': <String, dynamic>{},
    };

    when(() => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.profileMe,
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => responseData);

    await notifier.loadSettings();

    expect(notifier.state.isLoading, false);
    expect(notifier.state.defaultCheckInDay, 0); // default
    expect(notifier.state.defaultCheckInHour, 9); // default
    expect(notifier.state.weightUnit, 'KG'); // default
  });

  test('loadSettings handles direct response without data wrapper', () async {
    final responseData = <String, dynamic>{
      'defaultCheckInDay': 5,
      'defaultCheckInHour': 10,
      'weightUnit': 'LB',
    };

    when(() => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.profileMe,
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => responseData);

    await notifier.loadSettings();

    expect(notifier.state.defaultCheckInDay, 5);
    expect(notifier.state.defaultCheckInHour, 10);
    expect(notifier.state.weightUnit, 'LB');
  });

  // ---------------------------------------------------------------------------
  // loadSettings – failure
  // ---------------------------------------------------------------------------

  test('loadSettings sets error on failure', () async {
    when(() => mockApiClient.get<Map<String, dynamic>>(
          ApiConstants.profileMe,
          queryParams: any(named: 'queryParams'),
        )).thenThrow(Exception('Server error'));

    await notifier.loadSettings();

    expect(notifier.state.isLoading, false);
    expect(notifier.state.error, isNotNull);
  });

  // ---------------------------------------------------------------------------
  // saveCheckInDefaults
  // ---------------------------------------------------------------------------

  test('saveCheckInDefaults saves and updates state on success', () async {
    when(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.trainerSettings,
          body: any(named: 'body'),
        )).thenAnswer((_) async => <String, dynamic>{});

    await notifier.saveCheckInDefaults(3, 10);

    expect(notifier.state.isSaving, false);
    expect(notifier.state.defaultCheckInDay, 3);
    expect(notifier.state.defaultCheckInHour, 10);
    expect(notifier.state.successMessage, isNotNull);
    expect(notifier.state.error, isNull);

    verify(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.trainerSettings,
          body: {
            'defaultCheckInDay': 3,
            'defaultCheckInHour': 10,
          },
        )).called(1);
  });

  test('saveCheckInDefaults sets error on failure', () async {
    when(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.trainerSettings,
          body: any(named: 'body'),
        )).thenThrow(Exception('Save failed'));

    await notifier.saveCheckInDefaults(1, 8);

    expect(notifier.state.isSaving, false);
    expect(notifier.state.error, isNotNull);
    expect(notifier.state.successMessage, isNull);
  });

  test('saveCheckInDefaults preserves day/hour in state even on failure', () async {
    when(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.trainerSettings,
          body: any(named: 'body'),
        )).thenThrow(Exception('Save failed'));

    await notifier.saveCheckInDefaults(5, 20);

    // State should still reflect the attempted values optimistically
    expect(notifier.state.defaultCheckInDay, 5);
    expect(notifier.state.defaultCheckInHour, 20);
    expect(notifier.state.error, isNotNull);
  });

  // ---------------------------------------------------------------------------
  // toggleWeightUnit
  // ---------------------------------------------------------------------------

  test('toggleWeightUnit updates to LB on success', () async {
    when(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.trainerSettings,
          body: any(named: 'body'),
        )).thenAnswer((_) async => <String, dynamic>{});

    await notifier.toggleWeightUnit('LB');

    expect(notifier.state.isSaving, false);
    expect(notifier.state.weightUnit, 'LB');
    expect(notifier.state.successMessage, isNotNull);
    expect(notifier.state.error, isNull);

    verify(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.trainerSettings,
          body: {
            'weightUnit': 'LB',
          },
        )).called(1);
  });

  test('toggleWeightUnit updates to KG on success', () async {
    // Start with LB
    when(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.trainerSettings,
          body: any(named: 'body'),
        )).thenAnswer((_) async => <String, dynamic>{});

    await notifier.toggleWeightUnit('KG');

    expect(notifier.state.weightUnit, 'KG');
    expect(notifier.state.successMessage, 'Weight unit updated to KG');
  });

  test('toggleWeightUnit sets error on failure', () async {
    when(() => mockApiClient.put<Map<String, dynamic>>(
          ApiConstants.trainerSettings,
          body: any(named: 'body'),
        )).thenThrow(Exception('Toggle failed'));

    await notifier.toggleWeightUnit('LB');

    expect(notifier.state.isSaving, false);
    expect(notifier.state.weightUnit, 'LB'); // optimistic update still applied
    expect(notifier.state.error, isNotNull);
    expect(notifier.state.successMessage, isNull);
  });
}
