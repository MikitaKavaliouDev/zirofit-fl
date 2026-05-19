import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/body_measurement.dart';
import 'package:zirofit_fl/features/clients/data/measurement_remote_source.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Shared test data
// ---------------------------------------------------------------------------

const testClientId = 'test-client-id';

Map<String, dynamic> createMeasurementJson({
  String id = 'bm_api_1',
  String type = 'chest',
  String typeName = 'Chest',
  double valueCm = 100.0,
  String unit = 'cm',
}) => {
      'id': id,
      'client_id': testClientId,
      'type': type,
      'type_name': typeName,
      'value_cm': valueCm,
      'unit': unit,
      'measured_at': 1700000000000,
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
    };

BodyMeasurement createSampleMeasurement({
  String id = 'bm_1',
  String type = 'chest',
  String typeName = 'Chest',
  double valueCm = 100.0,
}) {
  final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  return BodyMeasurement(
    id: id,
    clientId: testClientId,
    type: type,
    typeName: typeName,
    valueCm: valueCm,
    unit: 'cm',
    measuredAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late MeasurementRemoteSource remoteSource;

  setUp(() {
    mockApiClient = MockApiClient();
    remoteSource = MeasurementRemoteSource(apiClient: mockApiClient);
    SharedPreferences.setMockInitialValues({});
  });

  group('MeasurementRemoteSource', () {
    // =========================================================================
    // fetchBodyMeasurements
    // =========================================================================

    group('fetchBodyMeasurements', () {
      test('calls API first and returns measurements on success', () async {
        final apiJson = createMeasurementJson(
          id: 'bm_api_1',
          type: 'chest',
          valueCm: 100.0,
        );

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.clientBodyMeasurements(testClientId),
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {
              'data': {'measurements': [apiJson]},
            });

        final result =
            await remoteSource.fetchBodyMeasurements(clientId: testClientId);

        expect(result.length, 1);
        expect(result[0].id, 'bm_api_1');
        expect(result[0].type, 'chest');
        expect(result[0].valueCm, 100.0);

        verify(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.clientBodyMeasurements(testClientId),
              queryParams: any(named: 'queryParams'),
            )).called(1);
      });

      test('falls back to SharedPrefs when API call fails', () async {
        // Pre-populate SharedPrefs with local data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'body_measurements_$testClientId',
          '[{"id":"bm_local_1","client_id":"$testClientId","type":"waist","type_name":"Waist","value_cm":80.0,"unit":"cm","measured_at":1700000000000,"created_at":1700000000000,"updated_at":1700000000000}]',
        );

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.clientBodyMeasurements(testClientId),
              queryParams: any(named: 'queryParams'),
            )).thenThrow(Exception('Network error'));

        final result =
            await remoteSource.fetchBodyMeasurements(clientId: testClientId);

        expect(result.length, 1);
        expect(result[0].id, 'bm_local_1');
        expect(result[0].type, 'waist');
        expect(result[0].valueCm, 80.0);
      });

      test('returns empty list when API fails and no local data', () async {
        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.clientBodyMeasurements(testClientId),
              queryParams: any(named: 'queryParams'),
            )).thenThrow(Exception('Network error'));

        final result =
            await remoteSource.fetchBodyMeasurements(clientId: testClientId);

        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // createBodyMeasurement
    // =========================================================================

    group('createBodyMeasurement', () {
      test('calls POST API and returns created measurement on success',
          () async {
        final apiJson = createMeasurementJson(
          id: 'bm_new_1',
          type: 'biceps',
          valueCm: 35.0,
        );

        when(() => mockApiClient.post<Map<String, dynamic>>(
              ApiConstants.clientBodyMeasurements(testClientId),
              body: any(named: 'body'),
            )).thenAnswer((_) async => {
              'data': {'measurement': apiJson},
            });

        final result = await remoteSource.createBodyMeasurement(
          clientId: testClientId,
          type: 'biceps',
          typeName: 'Biceps',
          valueCm: 35.0,
        );

        expect(result.id, 'bm_new_1');
        expect(result.type, 'biceps');
        expect(result.valueCm, 35.0);

        verify(() => mockApiClient.post<Map<String, dynamic>>(
              ApiConstants.clientBodyMeasurements(testClientId),
              body: any(named: 'body'),
            )).called(1);
      });

      test('falls back to local storage when API call fails', () async {
        when(() => mockApiClient.post<Map<String, dynamic>>(
              ApiConstants.clientBodyMeasurements(testClientId),
              body: any(named: 'body'),
            )).thenThrow(Exception('Network error'));

        final result = await remoteSource.createBodyMeasurement(
          clientId: testClientId,
          type: 'biceps',
          typeName: 'Biceps',
          valueCm: 35.0,
        );

        // Should have a locally-generated ID
        expect(result.id, startsWith('bm_'));
        expect(result.type, 'biceps');
        expect(result.typeName, 'Biceps');
        expect(result.valueCm, 35.0);
        expect(result.unit, 'cm');

        // Verify it was persisted locally
        final fetched =
            await remoteSource.fetchBodyMeasurements(clientId: testClientId);
        expect(fetched.length, 1);
        expect(fetched[0].id, result.id);
      });
    });

    // =========================================================================
    // updateBodyMeasurement
    // =========================================================================

    group('updateBodyMeasurement', () {
      test('calls PUT API and returns updated measurement on success',
          () async {
        final apiJson = createMeasurementJson(
          id: 'bm_update_1',
          type: 'chest',
          valueCm: 105.0,
        );

        when(() => mockApiClient.put<Map<String, dynamic>>(
              ApiConstants.clientBodyMeasurement(testClientId, 'bm_update_1'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => {
              'data': {'measurement': apiJson},
            });

        final result = await remoteSource.updateBodyMeasurement(
          clientId: testClientId,
          measurementId: 'bm_update_1',
          valueCm: 105.0,
        );

        expect(result.id, 'bm_update_1');
        expect(result.valueCm, 105.0);

        verify(() => mockApiClient.put<Map<String, dynamic>>(
              ApiConstants.clientBodyMeasurement(testClientId, 'bm_update_1'),
              body: any(named: 'body'),
            )).called(1);
      });

      test('falls back to local storage when API call fails', () async {
        when(() => mockApiClient.put<Map<String, dynamic>>(
              ApiConstants.clientBodyMeasurement(testClientId, 'bm_local_1'),
              body: any(named: 'body'),
            )).thenThrow(Exception('Network error'));

        // Pre-populate local with a measurement first
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'body_measurements_$testClientId',
          '[{"id":"bm_local_1","client_id":"$testClientId","type":"waist","type_name":"Waist","value_cm":80.0,"unit":"cm","measured_at":1700000000000,"created_at":1700000000000,"updated_at":1700000000000}]',
        );

        final result = await remoteSource.updateBodyMeasurement(
          clientId: testClientId,
          measurementId: 'bm_local_1',
          valueCm: 85.0,
        );

        expect(result.id, 'bm_local_1');
        expect(result.valueCm, 85.0);

        // Verify local was updated
        final fetched =
            await remoteSource.fetchBodyMeasurements(clientId: testClientId);
        expect(fetched.length, 1);
        expect(fetched[0].valueCm, 85.0);
      });

      test('throws when measurement not found locally on fallback', () async {
        when(() => mockApiClient.put<Map<String, dynamic>>(
              any(),
              body: any(named: 'body'),
            )).thenThrow(Exception('Network error'));

        await expectLater(
          remoteSource.updateBodyMeasurement(
            clientId: testClientId,
            measurementId: 'nonexistent',
            valueCm: 90.0,
          ),
          throwsException,
        );
      });
    });

    // =========================================================================
    // deleteBodyMeasurement
    // =========================================================================

    group('deleteBodyMeasurement', () {
      test('calls DELETE API and removes locally on success', () async {
        // Pre-populate local data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'body_measurements_$testClientId',
          '[{"id":"bm_del_1","client_id":"$testClientId","type":"chest","type_name":"Chest","value_cm":100.0,"unit":"cm","measured_at":1700000000000,"created_at":1700000000000,"updated_at":1700000000000}]',
        );

        when(() => mockApiClient.delete(
              ApiConstants.clientBodyMeasurement(testClientId, 'bm_del_1'),
            )).thenAnswer((_) async => {});

        await remoteSource.deleteBodyMeasurement(
          clientId: testClientId,
          measurementId: 'bm_del_1',
        );

        verify(() => mockApiClient.delete(
              ApiConstants.clientBodyMeasurement(testClientId, 'bm_del_1'),
            )).called(1);

        // Verify it's also removed locally
        final fetched =
            await remoteSource.fetchBodyMeasurements(clientId: testClientId);
        expect(fetched, isEmpty);
      });

      test('deletes locally when API call fails (best-effort)', () async {
        // Pre-populate local data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'body_measurements_$testClientId',
          '[{"id":"bm_del_2","client_id":"$testClientId","type":"waist","type_name":"Waist","value_cm":80.0,"unit":"cm","measured_at":1700000000000,"created_at":1700000000000,"updated_at":1700000000000}]',
        );

        when(() => mockApiClient.delete(
              ApiConstants.clientBodyMeasurement(testClientId, 'bm_del_2'),
            )).thenThrow(Exception('Network error'));

        await remoteSource.deleteBodyMeasurement(
          clientId: testClientId,
          measurementId: 'bm_del_2',
        );

        // Verify it's removed locally despite API failure
        final fetched =
            await remoteSource.fetchBodyMeasurements(clientId: testClientId);
        expect(fetched, isEmpty);
      });
    });
  });
}
