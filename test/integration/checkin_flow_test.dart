import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_provider.dart';
import 'package:zirofit_fl/features/checkin/providers/trainer_check_ins_provider.dart';
import '../helpers/provider_utils.dart';
import '../helpers/response_fixture.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

const _testTimestamp = 1700000000000;

Map<String, dynamic> _checkInJson({
  String id = 'ci-1',
  String clientId = 'test-client-id',
  String status = 'SUBMITTED',
  double weight = 80.0,
  String? trainerResponse,
}) {
  return {
    'id': id,
    'client_id': clientId,
    'date': _testTimestamp,
    'status': status,
    'weight': weight,
    'created_at': _testTimestamp,
    'updated_at': _testTimestamp,
    'trainer_response': trainerResponse,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  tearDown(() {
    container.dispose();
  });

  group('CheckInNotifier — client submits check-in', () {
    setUp(() {
      container = createTestContainer(overrides: [
        checkInProvider.overrideWith(
          (ref) => CheckInNotifier(apiClient: mockApiClient),
        ),
      ]);
    });

    test('initial state has isSubmitting=false and isSuccess=false', () {
      final state = container.read(checkInProvider);
      expect(state.isSubmitting, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNull);
      expect(state.lastCheckIn, isNull);
    });

    test('submitCheckIn succeeds and transitions to success state', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _checkInJson(id: 'ci-new'),
          });

      await container.read(checkInProvider.notifier).submitCheckIn(
            date: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
            weight: 80.0,
            sleepHours: 7.5,
            energyLevel: 7,
            stressLevel: 4,
          );

      final state = container.read(checkInProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isSubmitting, isFalse);
      expect(state.error, isNull);
      expect(state.lastCheckIn, isNotNull);
      expect(state.lastCheckIn!.id, 'ci-new');
      expect(state.lastCheckIn!.weight, 80.0);
    });

    test('submitCheckIn with optional fields includes them in request', () async {
      // Capture the body to verify optional fields
      dynamic capturedBody;
      when(() => mockApiClient.post<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
            capturedBody = invocation.namedArguments[#body];
            return <String, dynamic>{
              'data': _checkInJson(id: 'ci-detailed'),
            };
          });

      await container.read(checkInProvider.notifier).submitCheckIn(
            date: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
            weight: 82.0,
            waistCm: 90.0,
            sleepHours: 8.0,
            energyLevel: 8,
            stressLevel: 3,
            hungerLevel: 5,
            digestionLevel: 7,
            nutritionCompliance: 'Mostly clean',
            clientNotes: 'Feeling good this week',
          );

      // Verify body contains optional fields
      expect(capturedBody, isA<Map<String, dynamic>>());
      final body = capturedBody as Map<String, dynamic>;
      expect(body['weight'], 82.0);
      expect(body['waist_cm'], 90.0);
      expect(body['sleep_hours'], 8.0);
      expect(body['energy_level'], 8);
      expect(body['stress_level'], 3);
      expect(body['hunger_level'], 5);
      expect(body['digestion_level'], 7);
      expect(body['nutrition_compliance'], 'Mostly clean');
      expect(body['client_notes'], 'Feeling good this week');

      final state = container.read(checkInProvider);
      expect(state.isSuccess, isTrue);
    });

    test('submitCheckIn sets error on API failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
          )).thenThrow(Exception('API error'));

      await container.read(checkInProvider.notifier).submitCheckIn(
            date: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
            weight: 80.0,
          );

      final state = container.read(checkInProvider);
      expect(state.isSuccess, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.error, isNotNull);
    });

    test('reset clears the state', () async {
      // Submit a check-in first
      when(() => mockApiClient.post<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _checkInJson(id: 'ci-r'),
          });

      await container.read(checkInProvider.notifier).submitCheckIn(
            date: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
            weight: 80.0,
          );
      expect(container.read(checkInProvider).isSuccess, isTrue);

      // Act: reset
      container.read(checkInProvider.notifier).reset();

      // Assert
      final state = container.read(checkInProvider);
      expect(state.isSuccess, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.lastCheckIn, isNull);
    });
  });

  group('TrainerCheckInsNotifier — trainer reviews check-ins', () {
    setUp(() {
      container = createTestContainer(overrides: [
        trainerCheckInsProvider.overrideWith(
          (ref) => TrainerCheckInsNotifier(apiClient: mockApiClient),
        ),
      ]);
    });

    test('initial state has empty check-ins and is not loading', () {
      final state = container.read(trainerCheckInsProvider);
      expect(state.checkIns, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchCheckIns returns pending check-ins', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              _checkInJson(id: 'ci-pending-1', clientId: 'client-a'),
              _checkInJson(id: 'ci-pending-2', clientId: 'client-b'),
            ],
          });

      await container
          .read(trainerCheckInsProvider.notifier)
          .fetchCheckIns(status: 'SUBMITTED');

      final state = container.read(trainerCheckInsProvider);
      expect(state.checkIns, hasLength(2));
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('pendingCheckIns getter filters by SUBMITTED status', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              _checkInJson(id: 'ci-1', status: 'SUBMITTED'),
              _checkInJson(id: 'ci-2', status: 'REVIEWED', trainerResponse: 'Great!'),
              _checkInJson(id: 'ci-3', status: 'SUBMITTED'),
            ],
          });

      await container.read(trainerCheckInsProvider.notifier).fetchCheckIns();

      final state = container.read(trainerCheckInsProvider);
      expect(state.pendingCheckIns, hasLength(2));
      expect(state.reviewedCheckIns, hasLength(1));
    });

    test('fetchCheckInDetail loads a single check-in', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            '/trainer/check-ins/ci-detail',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _checkInJson(
              id: 'ci-detail',
              clientId: 'client-x',
              weight: 75.0,
            ),
          });

      await container
          .read(trainerCheckInsProvider.notifier)
          .fetchCheckInDetail('ci-detail');

      final state = container.read(trainerCheckInsProvider);
      expect(state.selectedCheckIn, isNotNull);
      expect(state.selectedCheckIn!.id, 'ci-detail');
      expect(state.selectedCheckIn!.weight, 75.0);
      expect(state.isLoadingDetail, isFalse);
    });

    test('submitReview updates check-in status to REVIEWED', () async {
      // Arrange: fetch check-ins first
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              _checkInJson(id: 'ci-review', status: 'SUBMITTED'),
            ],
          });

      await container.read(trainerCheckInsProvider.notifier).fetchCheckIns();
      expect(
        container.read(trainerCheckInsProvider).pendingCheckIns,
        hasLength(1),
      );

      // Arrange: mock review response
      when(() => mockApiClient.patch<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _checkInJson(
              id: 'ci-review',
              status: 'REVIEWED',
              trainerResponse: 'Looking good! Keep it up!',
            ),
          });

      // Act: submit review
      await container
          .read(trainerCheckInsProvider.notifier)
          .submitReview(checkInId: 'ci-review', responseText: 'Looking good! Keep it up!');

      // Assert
      final state = container.read(trainerCheckInsProvider);
      expect(state.isReviewing, isFalse);
      expect(state.reviewError, isNull);

      // Check-in should now be in reviewed list
      expect(state.pendingCheckIns, isEmpty);
      expect(state.reviewedCheckIns, hasLength(1));
      expect(state.reviewedCheckIns.first.trainerResponse,
          'Looking good! Keep it up!');
    });

    test('submitReview sets reviewError on failure', () async {
      when(() => mockApiClient.patch<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
          )).thenThrow(Exception('Review failed'));

      await container
          .read(trainerCheckInsProvider.notifier)
          .submitReview(checkInId: 'ci-fail', responseText: 'Nice!');

      final state = container.read(trainerCheckInsProvider);
      expect(state.isReviewing, isFalse);
      expect(state.reviewError, isNotNull);
    });

    // -------------------------------------------------------------------------
    // Response shape verification
    // -------------------------------------------------------------------------

    test('fetchCheckIns with error envelope sets error correctly', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerCheckIns),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerCheckIns),
          statusCode: 500,
          data: errorResponse(message: 'Internal server error'),
        ),
        type: DioExceptionType.badResponse,
      ));

      await container
          .read(trainerCheckInsProvider.notifier)
          .fetchCheckIns();

      final state = container.read(trainerCheckInsProvider);
      expect(state.error, contains('Internal server error'));
      expect(state.isLoading, isFalse);
    });

    test('fetchCheckInDetail handles missing data gracefully', () async {
      // Backend returns empty response with no data field
      when(() => mockApiClient.get<Map<String, dynamic>>(
            '/trainer/check-ins/ci-missing',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await container
          .read(trainerCheckInsProvider.notifier)
          .fetchCheckInDetail('ci-missing');

      final state = container.read(trainerCheckInsProvider);
      expect(state.selectedCheckIn, isNull);
      expect(state.isLoadingDetail, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('CheckInNotifier — client check-in response shapes', () {
    setUp(() {
      container = createTestContainer(overrides: [
        checkInProvider.overrideWith(
          (ref) => CheckInNotifier(apiClient: mockApiClient),
        ),
      ]);
    });

    test('fetchLastCheckIn parses data envelope correctly', () async {
      // Backend shape: GET /client/check-in → {"data": {"checkIn": {...}}}
      // The provider accesses result['data'] as Map<String, dynamic>?
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
          )).thenAnswer((_) async => dataResponse(
              _checkInJson(id: 'ci-last', weight: 75.0)));

      await container.read(checkInProvider.notifier).fetchLastCheckIn();

      final state = container.read(checkInProvider);
      expect(state.lastCheckIn, isNotNull);
      expect(state.lastCheckIn!.id, 'ci-last');
      expect(state.lastCheckIn!.weight, 75.0);
    });

    test('fetchLastCheckIn handles null response gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
          )).thenAnswer((_) async => dataResponse(<String, dynamic>{}));

      await container.read(checkInProvider.notifier).fetchLastCheckIn();

      final state = container.read(checkInProvider);
      expect(state.lastCheckIn, isNull);
    });

    test('fetchLastCheckIn handles DioException silently', () async {
      // Provider silently ignores errors in fetchLastCheckIn
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clientCheckIn),
        type: DioExceptionType.connectionError,
      ));

      await container.read(checkInProvider.notifier).fetchLastCheckIn();

      final state = container.read(checkInProvider);
      expect(state.lastCheckIn, isNull);
      expect(state.error, isNull); // silently ignored
    });
  });
}
