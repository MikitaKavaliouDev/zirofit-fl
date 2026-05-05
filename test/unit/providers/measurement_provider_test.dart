import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/body_measurement.dart';
import 'package:zirofit_fl/features/clients/data/measurement_remote_source.dart';
import 'package:zirofit_fl/features/clients/providers/measurement_provider.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

class MockMeasurementRemoteSource extends Mock
    implements MeasurementRemoteSource {}

// ---------------------------------------------------------------------------
// Shared test data
// ---------------------------------------------------------------------------

const testClientId = 'test-client-id';

// Use a fixed DateTime for reproducible tests.
final _now = DateTime(2025, 1, 15, 10, 0, 0);

List<BodyMeasurement> createSampleBodyMeasurements() => [
      BodyMeasurement(
        id: 'bm_1',
        clientId: testClientId,
        type: 'chest',
        typeName: 'Chest',
        valueCm: 100.0,
        unit: 'cm',
        measuredAt: _now,
        createdAt: _now,
        updatedAt: _now,
      ),
      BodyMeasurement(
        id: 'bm_2',
        clientId: testClientId,
        type: 'waist',
        typeName: 'Waist',
        valueCm: 80.0,
        unit: 'cm',
        measuredAt: _now,
        createdAt: _now,
        updatedAt: _now,
      ),
    ];

/// Default empty progress response used by multiple tests.
Map<String, dynamic> _emptyProgressResponse() => <String, dynamic>{
      'data': <String, dynamic>{
        'weight': <dynamic>[],
        'bodyFat': <dynamic>[],
        'volume': <dynamic>[],
        'exercisePerformance': <dynamic>[],
        'favoriteExercises': <dynamic>[],
        'worstPerformingExercises': <dynamic>[],
      },
    };

// =============================================================================
// ClientMeasurementNotifier
// =============================================================================

void main() {
  group('ClientMeasurementNotifier', () {
    late MockApiClient mockApiClient;
    late ClientMeasurementNotifier notifier;

    setUp(() {
      mockApiClient = MockApiClient();
      notifier = ClientMeasurementNotifier(apiClient: mockApiClient);
    });

    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------

    test('initial state has empty measurements, isLoading=false, error=null',
        () {
      final state = notifier.state;
      expect(state.measurements, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchMeasurements
    // ---------------------------------------------------------------------------

    test('fetchMeasurements sets isLoading true before completion', () async {
      when(() => mockApiClient.get(
            ApiConstants.clientProgress,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _emptyProgressResponse());

      final future = notifier.fetchMeasurements();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchMeasurements populates measurements on success', () async {
      when(() => mockApiClient.get(
            ApiConstants.clientProgress,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': <String, dynamic>{
          'weight': <dynamic>[
            <String, dynamic>{'date': 1700000000000, 'value': 75.0},
            <String, dynamic>{'date': 1700086400000, 'value': 74.5},
          ],
          'bodyFat': <dynamic>[
            <String, dynamic>{'date': 1700000000000, 'value': 15.0},
          ],
          'volume': <dynamic>[],
          'exercisePerformance': <dynamic>[],
          'favoriteExercises': <dynamic>[],
          'worstPerformingExercises': <dynamic>[],
        },
      });

      await notifier.fetchMeasurements();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.measurements.length, 2);
      // Sorted newest-first: 1700086400000 is Nov 15 > Nov 14 (1700000000000)
      expect(state.measurements[0].weightKg, 74.5);
      expect(state.measurements[0].bodyFatPercentage, isNull);
      expect(state.measurements[1].weightKg, 75.0);
      expect(state.measurements[1].bodyFatPercentage, 15.0);
    });

    test('fetchMeasurements handles empty response', () async {
      when(() => mockApiClient.get(
            ApiConstants.clientProgress,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _emptyProgressResponse());

      await notifier.fetchMeasurements();

      expect(notifier.state.measurements, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('fetchMeasurements sets error on failure', () async {
      when(() => mockApiClient.get(
            ApiConstants.clientProgress,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.clientProgress),
        type: DioExceptionType.connectionTimeout,
      ));

      await notifier.fetchMeasurements();

      expect(notifier.state.isLoading, false);
      expect(
          notifier.state.error, 'Connection timeout. Please try again.');
    });

    test('fetchMeasurements sets error on malformed data', () async {
      when(() => mockApiClient.get(
            ApiConstants.clientProgress,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': <String, dynamic>{
          'weight': 'not-a-list',
          'bodyFat': null,
          'volume': <dynamic>[],
          'exercisePerformance': <dynamic>[],
          'favoriteExercises': <dynamic>[],
          'worstPerformingExercises': <dynamic>[],
        },
      });

      await notifier.fetchMeasurements();

      expect(notifier.state.measurements, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // addMeasurement
    // ---------------------------------------------------------------------------

    test('addMeasurement posts and re-fetches measurements', () async {
      // Mock the POST
      when(() => mockApiClient.post(
            '${ApiConstants.clients}/_current/measurements',
            body: any(named: 'body'),
          )).thenAnswer(
          (_) async => <String, dynamic>{'data': {'id': 'm-new'}});

      // Mock the subsequent GET from fetchMeasurements
      when(() => mockApiClient.get(
            ApiConstants.clientProgress,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': <String, dynamic>{
          'weight': <dynamic>[
            <String, dynamic>{'date': 1700000000000, 'value': 80.0},
          ],
          'bodyFat': <dynamic>[
            <String, dynamic>{'date': 1700000000000, 'value': 18.0},
          ],
          'volume': <dynamic>[],
          'exercisePerformance': <dynamic>[],
          'favoriteExercises': <dynamic>[],
          'worstPerformingExercises': <dynamic>[],
        },
      });

      final result = await notifier.addMeasurement(
        weightKg: 80.0,
        bodyFatPercentage: 18.0,
        measurementDate: DateTime(2025, 1, 15),
        notes: 'Test measurement',
      );

      expect(result, isNull);
      expect(notifier.state.measurements.length, 1);
      expect(notifier.state.measurements.first.weightKg, 80.0);
      expect(notifier.state.measurements.first.bodyFatPercentage, 18.0);
    });

    test('addMeasurement returns error on failure', () async {
      when(() => mockApiClient.post(
            '${ApiConstants.clients}/_current/measurements',
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: '${ApiConstants.clients}/_current/measurements'),
        response: Response(
          requestOptions: RequestOptions(
              path: '${ApiConstants.clients}/_current/measurements'),
          statusCode: 400,
          data: <String, dynamic>{
            'error': {'message': 'Invalid measurement data'},
          },
        ),
      ));

      final result = await notifier.addMeasurement(
        weightKg: -1,
        bodyFatPercentage: null,
      );

      expect(result, 'Invalid measurement data');
    });
  });

  // ===========================================================================
  // BodyMeasurementNotifier
  // ===========================================================================

  group('BodyMeasurementNotifier', () {
    late MockMeasurementRemoteSource mockRemoteSource;
    late BodyMeasurementNotifier notifier;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      mockRemoteSource = MockMeasurementRemoteSource();
      notifier = BodyMeasurementNotifier(remoteSource: mockRemoteSource);
    });

    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------

    test('initial state has empty measurements, isLoading=false, error=null',
        () {
      final state = notifier.state;
      expect(state.measurements, isEmpty);
      expect(state.historyByType, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchMeasurements
    // ---------------------------------------------------------------------------

    test('fetchMeasurements loads measurements from remote source', () async {
      final samples = createSampleBodyMeasurements();
      when(() => mockRemoteSource.fetchBodyMeasurements(
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => samples);

      await notifier.fetchMeasurements(clientId: testClientId);

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.measurements.length, 2);
      expect(state.historyByType.containsKey('chest'), isTrue);
      expect(state.historyByType.containsKey('waist'), isTrue);
      expect(state.historyByType['chest']!.length, 1);
      expect(state.historyByType['waist']!.length, 1);
    });

    test('fetchMeasurements handles empty list', () async {
      when(() => mockRemoteSource.fetchBodyMeasurements(
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => []);

      await notifier.fetchMeasurements(clientId: testClientId);

      expect(notifier.state.measurements, isEmpty);
      expect(notifier.state.historyByType, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchMeasurements sets error on failure', () async {
      when(() => mockRemoteSource.fetchBodyMeasurements(
            clientId: any(named: 'clientId'),
          )).thenThrow(Exception('Failed to load'));

      await notifier.fetchMeasurements(clientId: testClientId);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('Failed to load'));
    });

    // ---------------------------------------------------------------------------
    // addMeasurement
    // ---------------------------------------------------------------------------

    test('addMeasurement creates and adds to state', () async {
      when(() => mockRemoteSource.createBodyMeasurement(
            clientId: any(named: 'clientId'),
            type: any(named: 'type'),
            typeName: any(named: 'typeName'),
            valueCm: any(named: 'valueCm'),
            unit: any(named: 'unit'),
          )).thenAnswer((_) async => BodyMeasurement(
                id: 'bm_new',
                clientId: testClientId,
                type: 'chest',
                typeName: 'Chest',
                valueCm: 105.0,
                unit: 'cm',
                measuredAt: _now,
                createdAt: _now,
                updatedAt: _now,
              ));

      final result = await notifier.addMeasurement(
        clientId: testClientId,
        type: 'chest',
        typeName: 'Chest',
        valueCm: 105.0,
      );

      expect(result, isNull);
      expect(notifier.state.measurements.length, 1);
      expect(notifier.state.measurements.first.valueCm, 105.0);
      expect(notifier.state.historyByType.containsKey('chest'), isTrue);
    });

    test('addMeasurement returns error on failure', () async {
      when(() => mockRemoteSource.createBodyMeasurement(
            clientId: any(named: 'clientId'),
            type: any(named: 'type'),
            typeName: any(named: 'typeName'),
            valueCm: any(named: 'valueCm'),
            unit: any(named: 'unit'),
          )).thenThrow(Exception('Storage full'));

      final result = await notifier.addMeasurement(
        clientId: testClientId,
        type: 'chest',
        typeName: 'Chest',
        valueCm: 105.0,
      );

      expect(result, contains('Storage full'));
    });

    // ---------------------------------------------------------------------------
    // updateMeasurement
    // ---------------------------------------------------------------------------

    test('updateMeasurement updates existing measurement', () async {
      // Seed initial state
      final samples = createSampleBodyMeasurements();
      when(() => mockRemoteSource.fetchBodyMeasurements(
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => samples);
      await notifier.fetchMeasurements(clientId: testClientId);

      // Mock the update
      when(() => mockRemoteSource.updateBodyMeasurement(
            clientId: any(named: 'clientId'),
            measurementId: any(named: 'measurementId'),
            valueCm: any(named: 'valueCm'),
          )).thenAnswer((_) async => BodyMeasurement(
                id: 'bm_1',
                clientId: testClientId,
                type: 'chest',
                typeName: 'Chest',
                valueCm: 110.0,
                unit: 'cm',
                measuredAt: _now,
                createdAt: _now,
                updatedAt: _now,
              ));

      final result = await notifier.updateMeasurement(
        clientId: testClientId,
        measurementId: 'bm_1',
        valueCm: 110.0,
      );

      expect(result, isNull);
      expect(notifier.state.measurements.length, 2);
      expect(
          notifier.state.measurements.firstWhere((m) => m.id == 'bm_1').valueCm,
          110.0);
    });

    test('updateMeasurement returns error on failure', () async {
      when(() => mockRemoteSource.updateBodyMeasurement(
            clientId: any(named: 'clientId'),
            measurementId: any(named: 'measurementId'),
            valueCm: any(named: 'valueCm'),
          )).thenThrow(Exception('Not found'));

      final result = await notifier.updateMeasurement(
        clientId: testClientId,
        measurementId: 'nonexistent',
        valueCm: 110.0,
      );

      expect(result, contains('Not found'));
    });

    // ---------------------------------------------------------------------------
    // deleteMeasurement
    // ---------------------------------------------------------------------------

    test('deleteMeasurement removes measurement from state', () async {
      // Seed initial state
      final samples = createSampleBodyMeasurements();
      when(() => mockRemoteSource.fetchBodyMeasurements(
            clientId: any(named: 'clientId'),
          )).thenAnswer((_) async => samples);
      await notifier.fetchMeasurements(clientId: testClientId);

      // Mock the delete
      when(() => mockRemoteSource.deleteBodyMeasurement(
            clientId: any(named: 'clientId'),
            measurementId: any(named: 'measurementId'),
          )).thenAnswer((_) async {});

      final result = await notifier.deleteMeasurement(
        clientId: testClientId,
        measurementId: 'bm_1',
      );

      expect(result, isNull);
      expect(notifier.state.measurements.length, 1);
      expect(notifier.state.measurements.first.id, 'bm_2');
      expect(notifier.state.historyByType.containsKey('chest'), isFalse);
      expect(notifier.state.historyByType.containsKey('waist'), isTrue);
    });

    test('deleteMeasurement returns error on failure', () async {
      when(() => mockRemoteSource.deleteBodyMeasurement(
            clientId: any(named: 'clientId'),
            measurementId: any(named: 'measurementId'),
          )).thenThrow(Exception('Delete failed'));

      final result = await notifier.deleteMeasurement(
        clientId: testClientId,
        measurementId: 'bm_1',
      );

      expect(result, contains('Delete failed'));
    });
  });
}
