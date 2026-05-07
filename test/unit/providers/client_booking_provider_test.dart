import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/bookings/providers/client_booking_provider.dart';
import '../../helpers/provider_utils.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;
  late ClientBookingNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      apiClientProvider.overrideWithValue(mockApiClient as ApiClient),
    ]);
    notifier = container.read(clientBookingProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('ClientBookingNotifier', () {
    // ---------------------------------------------------------------------------
    // Test 1: Initial state
    // ---------------------------------------------------------------------------
    test('initial state is correct', () {
      final state = container.read(clientBookingProvider);
      expect(state.selectedDate, isNull);
      expect(state.availableSlots, isEmpty);
      expect(state.trainerInfo, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.pendingBooking, false);
    });

    // ---------------------------------------------------------------------------
    // Test 2: fetchTrainerAvailability populates slots and trainer info
    // ---------------------------------------------------------------------------
    test('fetchTrainerAvailability populates slots and trainer info on success',
        () async {
      const trainerId = 'trainer-1';
      final date = DateTime(2026, 5, 10);

      final scheduleJson = {
        'data': {
          'trainer': {
            'id': trainerId,
            'name': 'John Doe',
            'avatar_url': 'https://example.com/avatar.jpg',
          },
          'slots': [
            {
              'start_time': 1700000000000,
              'end_time': 1700003600000,
            },
            {
              'start_time': 1700007200000,
              'end_time': 1700010800000,
            },
          ],
        },
      };

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerSchedule(trainerId),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => scheduleJson);

      await notifier.fetchTrainerAvailability(trainerId, date);

      final state = container.read(clientBookingProvider);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.selectedDate, date);
      expect(state.trainerInfo, isNotNull);
      expect(state.trainerInfo!.id, trainerId);
      expect(state.trainerInfo!.name, 'John Doe');
      expect(state.trainerInfo!.avatarUrl, 'https://example.com/avatar.jpg');
      expect(state.availableSlots, hasLength(2));
      expect(state.availableSlots[0].start,
          DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(state.availableSlots[0].end,
          DateTime.fromMillisecondsSinceEpoch(1700003600000));
      expect(state.availableSlots[1].start,
          DateTime.fromMillisecondsSinceEpoch(1700007200000));
      expect(state.availableSlots[1].end,
          DateTime.fromMillisecondsSinceEpoch(1700010800000));
    });

    // ---------------------------------------------------------------------------
    // Test 3: selectDate updates date and fetches slots for stored trainer
    // ---------------------------------------------------------------------------
    test('selectDate updates date and re-fetches slots for stored trainer',
        () async {
      const trainerId = 'trainer-1';
      final initialDate = DateTime(2026, 5, 10);
      final newDate = DateTime(2026, 5, 11);

      // First, load the trainer
      final initialSchedule = {
        'data': {
          'trainer': {
            'id': trainerId,
            'name': 'John Doe',
          },
          'slots': [
            {
              'start_time': 1700000000000,
              'end_time': 1700003600000,
            },
          ],
        },
      };

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerSchedule(trainerId),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => initialSchedule);

      await notifier.fetchTrainerAvailability(trainerId, initialDate);

      // Verify initial state
      expect(container.read(clientBookingProvider).selectedDate, initialDate);

      // Stub second call for the new date
      final newSchedule = {
        'data': {
          'trainer': {
            'id': trainerId,
            'name': 'John Doe',
          },
          'slots': [
            {
              'start_time': 1700007200000,
              'end_time': 1700010800000,
            },
          ],
        },
      };

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerSchedule(trainerId),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => newSchedule);

      await notifier.selectDate(newDate);

      final state = container.read(clientBookingProvider);
      expect(state.selectedDate, newDate);
      expect(state.availableSlots, hasLength(1));
      expect(state.availableSlots[0].start,
          DateTime.fromMillisecondsSinceEpoch(1700007200000));
      expect(state.isLoading, false);
    });

    test(
        'selectDate only updates date when no trainer is loaded (no fetch)',
        () async {
      final date = DateTime(2026, 5, 10);

      await notifier.selectDate(date);

      final state = container.read(clientBookingProvider);
      expect(state.selectedDate, date);
      // No API call should have been made
      verifyNever<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            any(),
            queryParams: any(named: 'queryParams'),
          ));
    });

    // ---------------------------------------------------------------------------
    // Test 4: requestBooking sends POST and tracks pending booking
    // ---------------------------------------------------------------------------
    test('requestBooking sends POST and tracks pendingBooking', () async {
      const trainerId = 'trainer-1';
      final slot = TimeSlot(
        start: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        end: DateTime.fromMillisecondsSinceEpoch(1700003600000),
      );

      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookings,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'data': {'id': 'bkg-new'}});

      // Verify pendingBooking is true during the call
      final future = notifier.requestBooking(trainerId, slot);

      // Check intermediate state (pendingBooking = true)
      // Note: This runs after the notifier sets pendingBooking but before the
      // API response completes. We use expectLater for the completion.
      expect(container.read(clientBookingProvider).pendingBooking, true);

      final bookingId = await future;

      expect(bookingId, 'bkg-new');
      final state = container.read(clientBookingProvider);
      expect(state.pendingBooking, false);
      expect(state.error, isNull);

      // Verify the API was called with correct body
      verify<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookings,
            body: {
              'trainer_id': trainerId,
              'start_time': 1700000000000,
              'end_time': 1700003600000,
            },
          )).called(1);
    });

    // ---------------------------------------------------------------------------
    // Test 5: cancelBooking sends POST
    // ---------------------------------------------------------------------------
    test('cancelBooking sends POST to cancel endpoint on success', () async {
      const bookingId = 'bkg-1';

      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookingCancel(bookingId),
          )).thenAnswer((_) async => {'data': {'message': 'Cancelled'}});

      final success = await notifier.cancelBooking(bookingId);

      expect(success, isTrue);
      final state = container.read(clientBookingProvider);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // Test 6: Error handling for all methods
    // ---------------------------------------------------------------------------
    test('fetchTrainerAvailability sets error on failure', () async {
      const trainerId = 'trainer-1';
      final date = DateTime(2026, 5, 10);

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerSchedule(trainerId),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.trainerSchedule(trainerId)),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions:
                RequestOptions(path: ApiConstants.trainerSchedule(trainerId)),
            statusCode: 500,
            data: {'message': 'Server error'},
          ),
        ),
      );

      await notifier.fetchTrainerAvailability(trainerId, date);

      final state = container.read(clientBookingProvider);
      expect(state.availableSlots, isEmpty);
      expect(state.trainerInfo, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('requestBooking returns false on failure', () async {
      const trainerId = 'trainer-1';
      final slot = TimeSlot(
        start: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        end: DateTime.fromMillisecondsSinceEpoch(1700003600000),
      );

      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookings,
            body: any(named: 'body'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.bookings),
          type: DioExceptionType.badResponse,
        ),
      );

      final bookingId = await notifier.requestBooking(trainerId, slot);

      expect(bookingId, isNull);
      final state = container.read(clientBookingProvider);
      expect(state.pendingBooking, false);
      expect(state.error, isNotNull);
    });

    test('cancelBooking returns false on failure', () async {
      const bookingId = 'bkg-1';

      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookingCancel(bookingId),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.bookingCancel(bookingId)),
          type: DioExceptionType.badResponse,
        ),
      );

      final success = await notifier.cancelBooking(bookingId);

      expect(success, isFalse);
      final state = container.read(clientBookingProvider);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });
  });
}
