import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/checkin/providers/trainer_check_ins_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TrainerCheckInsNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = TrainerCheckInsNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> checkInJson({
    String id = 'ci-1',
    String status = 'SUBMITTED',
    String? trainerResponse,
  }) => {
        'id': id,
        'client_id': 'client-1',
        'date': DateTime(2024, 6, 1).millisecondsSinceEpoch,
        'status': status,
        'weight': 75.0,
        'trainer_response': trainerResponse,
        'created_at': DateTime(2024, 6, 1).millisecondsSinceEpoch,
        'updated_at': DateTime(2024, 6, 1).millisecondsSinceEpoch,
      };

  group('TrainerCheckInsNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has empty checkIns and isLoading false', () {
      expect(notifier.state.checkIns, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.selectedCheckIn, isNull);
      expect(notifier.state.pendingCheckIns, isEmpty);
      expect(notifier.state.reviewedCheckIns, isEmpty);
    });

    // ---------------------------------------------------------------------------
    // fetchCheckIns – success
    // ---------------------------------------------------------------------------
    test('fetchCheckIns populates list on success', () async {
      final checkInsJson = [
        checkInJson(id: 'ci-1'),
        checkInJson(id: 'ci-2'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerCheckIns,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': checkInsJson});

      await notifier.fetchCheckIns();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.checkIns.length, 2);
      expect(notifier.state.checkIns[0].id, 'ci-1');
      expect(notifier.state.checkIns[1].id, 'ci-2');
    });

    // ---------------------------------------------------------------------------
    // fetchCheckIns – with status filter
    // ---------------------------------------------------------------------------
    test('fetchCheckIns passes status query param', () async {
      Map<String, dynamic>? capturedParams;

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerCheckIns,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((invocation) async {
        capturedParams =
            invocation.namedArguments[#queryParams] as Map<String, dynamic>?;
        return {'data': <Map<String, dynamic>>[]};
      });

      await notifier.fetchCheckIns(status: 'SUBMITTED');

      expect(capturedParams, isNotNull);
      expect(capturedParams!['status'], 'SUBMITTED');
    });

    // ---------------------------------------------------------------------------
    // fetchCheckIns – failure
    // ---------------------------------------------------------------------------
    test('fetchCheckIns sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerCheckIns,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Failed to load'));

      await notifier.fetchCheckIns();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.checkIns, isEmpty);
    });

    // ---------------------------------------------------------------------------
    // fetchCheckInDetail – success
    // ---------------------------------------------------------------------------
    test('fetchCheckInDetail sets selectedCheckIn', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerCheckInDetail('ci-1'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': checkInJson(id: 'ci-1')});

      await notifier.fetchCheckInDetail('ci-1');

      expect(notifier.state.isLoadingDetail, false);
      expect(notifier.state.selectedCheckIn, isNotNull);
      expect(notifier.state.selectedCheckIn!.id, 'ci-1');
    });

    // ---------------------------------------------------------------------------
    // fetchCheckInDetail – null data
    // ---------------------------------------------------------------------------
    test('fetchCheckInDetail sets error when data is null', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerCheckInDetail('ci-1'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.fetchCheckInDetail('ci-1');

      expect(notifier.state.isLoadingDetail, false);
      expect(notifier.state.error, 'Failed to parse check-in detail');
    });

    // ---------------------------------------------------------------------------
    // fetchCheckInDetail – failure
    // ---------------------------------------------------------------------------
    test('fetchCheckInDetail sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerCheckInDetail('ci-1'),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Detail load failed'));

      await notifier.fetchCheckInDetail('ci-1');

      expect(notifier.state.isLoadingDetail, false);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.selectedCheckIn, isNull);
    });

    // ---------------------------------------------------------------------------
    // submitReview – success
    // ---------------------------------------------------------------------------
    test('submitReview posts review text', () async {
      // Pre-populate list
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerCheckIns,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              checkInJson(id: 'ci-1'),
            ],
          });

      await notifier.fetchCheckIns();
      expect(notifier.state.checkIns.length, 1);
      expect(notifier.state.checkIns.first.trainerResponse, isNull);

      // Stub the review PATCH
      final reviewedJson = checkInJson(
        id: 'ci-1',
        status: 'REVIEWED',
        trainerResponse: 'Great progress! Keep it up!',
      );

      when(() => mockApiClient.patch<Map<String, dynamic>>(
            ApiConstants.trainerCheckInReview('ci-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'data': reviewedJson});

      await notifier.submitReview(
        checkInId: 'ci-1',
        responseText: 'Great progress! Keep it up!',
      );

      expect(notifier.state.isReviewing, false);
      expect(notifier.state.reviewError, isNull);

      // Check-in in list should be updated
      expect(notifier.state.checkIns.first.trainerResponse,
          'Great progress! Keep it up!');
      // selectedCheckIn should also be updated
      expect(notifier.state.selectedCheckIn, isNotNull);
      expect(notifier.state.selectedCheckIn!.trainerResponse,
          'Great progress! Keep it up!');
    });

    // ---------------------------------------------------------------------------
    // submitReview – failure
    // ---------------------------------------------------------------------------
    test('submitReview sets reviewError on failure', () async {
      when(() => mockApiClient.patch<Map<String, dynamic>>(
            ApiConstants.trainerCheckInReview('ci-1'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Review failed'));

      await notifier.submitReview(
        checkInId: 'ci-1',
        responseText: 'Good work',
      );

      expect(notifier.state.isReviewing, false);
      expect(notifier.state.reviewError, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // clearError
    // ---------------------------------------------------------------------------
    test('clearError clears the error', () async {
      // Trigger an error
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerCheckIns,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Fail'));

      await notifier.fetchCheckIns();
      expect(notifier.state.error, isNotNull);

      notifier.clearError();

      expect(notifier.state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // clearReviewError
    // ---------------------------------------------------------------------------
    test('clearReviewError clears the review error', () async {
      when(() => mockApiClient.patch<Map<String, dynamic>>(
            ApiConstants.trainerCheckInReview('ci-1'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Review fail'));

      await notifier.submitReview(checkInId: 'ci-1', responseText: 'x');
      expect(notifier.state.reviewError, isNotNull);

      notifier.clearReviewError();

      expect(notifier.state.reviewError, isNull);
    });

    // ---------------------------------------------------------------------------
    // pendingCheckIns / reviewedCheckIns computed getters
    // ---------------------------------------------------------------------------
    test('pendingCheckIns returns only SUBMITTED check-ins', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerCheckIns,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              checkInJson(id: 'ci-1', status: 'SUBMITTED'),
              checkInJson(id: 'ci-2', status: 'REVIEWED'),
              checkInJson(id: 'ci-3', status: 'SUBMITTED'),
            ],
          });

      await notifier.fetchCheckIns();

      expect(notifier.state.pendingCheckIns.length, 2);
      expect(notifier.state.reviewedCheckIns.length, 1);
      expect(notifier.state.pendingCheckIns.every((c) => c.status == 'SUBMITTED'),
          true);
      expect(notifier.state.reviewedCheckIns.every((c) => c.status == 'REVIEWED'),
          true);
    });
  });
}
