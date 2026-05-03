import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late CheckInNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = CheckInNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> checkInJson() => {
        'id': 'ci-1',
        'client_id': 'client-1',
        'date': DateTime(2024, 6, 1).millisecondsSinceEpoch,
        'status': 'SUBMITTED',
        'weight': 75.0,
        'waist_cm': 80.0,
        'created_at': DateTime(2024, 6, 1).millisecondsSinceEpoch,
        'updated_at': DateTime(2024, 6, 1).millisecondsSinceEpoch,
      };

  group('CheckInNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has isSubmitting false and isSuccess false', () {
      expect(notifier.state.isSubmitting, false);
      expect(notifier.state.isSuccess, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.lastCheckIn, isNull);
    });

    // ---------------------------------------------------------------------------
    // submitCheckIn – success without photo
    // ---------------------------------------------------------------------------
    test('submitCheckIn sets isSubmitting first, then isSuccess', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'data': checkInJson()});

      // Start the submission
      final future = notifier.submitCheckIn(
        date: DateTime(2024, 6, 1),
        weight: 75.0,
      );

      // During submission, isSubmitting should be true
      expect(notifier.state.isSubmitting, true);
      expect(notifier.state.isSuccess, false);

      await future;

      // After completion, isSubmitting is false and isSuccess is true
      expect(notifier.state.isSubmitting, false);
      expect(notifier.state.isSuccess, true);
      expect(notifier.state.lastCheckIn, isNotNull);
      expect(notifier.state.lastCheckIn!.id, 'ci-1');
      expect(notifier.state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // submitCheckIn – success with all optional fields
    // ---------------------------------------------------------------------------
    test('submitCheckIn accepts all optional fields', () async {
      Map<String, dynamic>? capturedBody;

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        capturedBody = invocation.namedArguments[#body] as Map<String, dynamic>?;
        return {'data': checkInJson()};
      });

      await notifier.submitCheckIn(
        date: DateTime(2024, 6, 1),
        weight: 75.0,
        waistCm: 80.0,
        sleepHours: 7.5,
        energyLevel: 8,
        stressLevel: 3,
        hungerLevel: 5,
        digestionLevel: 7,
        nutritionCompliance: 'good',
        clientNotes: 'Feeling great',
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['waist_cm'], 80.0);
      expect(capturedBody!['sleep_hours'], 7.5);
      expect(capturedBody!['energy_level'], 8);
      expect(capturedBody!['stress_level'], 3);
      expect(capturedBody!['hunger_level'], 5);
      expect(capturedBody!['digestion_level'], 7);
      expect(capturedBody!['nutrition_compliance'], 'good');
      expect(capturedBody!['client_notes'], 'Feeling great');
      expect(notifier.state.isSuccess, true);
    });

    // ---------------------------------------------------------------------------
    // submitCheckIn – failure
    // ---------------------------------------------------------------------------
    test('submitCheckIn sets error on failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenThrow(Exception('Network error'));

      await notifier.submitCheckIn(
        date: DateTime(2024, 6, 1),
        weight: 75.0,
      );

      expect(notifier.state.isSubmitting, false);
      expect(notifier.state.isSuccess, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // clearError
    // ---------------------------------------------------------------------------
    test('clearError clears the error', () async {
      // First trigger an error
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenThrow(Exception('Some error'));

      await notifier.submitCheckIn(
        date: DateTime(2024, 6, 1),
        weight: 75.0,
      );
      expect(notifier.state.error, isNotNull);

      // Clear it
      notifier.clearError();

      expect(notifier.state.error, isNull);
      expect(notifier.state.isSubmitting, false);
      expect(notifier.state.isSuccess, false);
    });

    // ---------------------------------------------------------------------------
    // clearError – no-op when no error
    // ---------------------------------------------------------------------------
    test('clearError is safe when no error exists', () {
      expect(notifier.state.error, isNull);

      notifier.clearError();

      expect(notifier.state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // reset
    // ---------------------------------------------------------------------------
    test('reset restores initial state', () async {
      // Set some state first
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'data': checkInJson()});

      await notifier.submitCheckIn(
        date: DateTime(2024, 6, 1),
        weight: 75.0,
      );
      expect(notifier.state.isSuccess, true);
      expect(notifier.state.lastCheckIn, isNotNull);

      notifier.reset();

      expect(notifier.state.isSubmitting, false);
      expect(notifier.state.isSuccess, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.lastCheckIn, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchLastCheckIn
    // ---------------------------------------------------------------------------
    test('fetchLastCheckIn sets lastCheckIn on success', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': checkInJson()});

      await notifier.fetchLastCheckIn();

      expect(notifier.state.lastCheckIn, isNotNull);
      expect(notifier.state.lastCheckIn!.id, 'ci-1');
    });

    test('fetchLastCheckIn silently ignores errors', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('fail'));

      // Should not throw
      await notifier.fetchLastCheckIn();

      expect(notifier.state.lastCheckIn, isNull);
    });
  });
}
