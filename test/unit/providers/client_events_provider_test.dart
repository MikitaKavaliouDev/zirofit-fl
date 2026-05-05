import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/events/providers/client_events_provider.dart';
import '../../helpers/provider_utils.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      apiClientProvider.overrideWithValue(mockApiClient as ApiClient),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('ClientEventsNotifier', () {
    test('initial state is correct', () {
      final state = container.read(clientEventsProvider);
      expect(state.bookedEvents, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.joinSuccess, false);
    });

    test('fetchBookedEvents loads events on success', () async {
      final bookedEventsJson = [
        {
          'id': 'evt-1',
          'trainer_id': 'trainer-1',
          'title': 'Morning Yoga',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'price': 0,
          'capacity': 20,
          'enrolled_count': 5,
          'category': 'Class',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
          'booking_id': 'bk-101',
        },
        {
          'id': 'evt-2',
          'trainer_id': 'trainer-1',
          'title': 'HIIT Session',
          'start_time': 1700007200000,
          'end_time': 1700010800000,
          'price': 29.99,
          'currency': 'PLN',
          'capacity': 15,
          'enrolled_count': 10,
          'category': 'Workshop',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
          'booking_id': 'bk-102',
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientEvents,
          )).thenAnswer((_) async => {
            'data': bookedEventsJson,
          });

      await container.read(clientEventsProvider.notifier).fetchBookedEvents();

      final state = container.read(clientEventsProvider);
      expect(state.bookedEvents, hasLength(2));
      expect(state.bookedEvents[0].title, 'Morning Yoga');
      expect(state.bookedEvents[1].title, 'HIIT Session');
      expect(state.isLoading, false);
      expect(state.error, isNull);

      // Verify booking IDs were stored
      final notifier = container.read(clientEventsProvider.notifier);
      expect(notifier.getBookingId('evt-1'), 'bk-101');
      expect(notifier.getBookingId('evt-2'), 'bk-102');
    });

    test('fetchBookedEvents sets error on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientEvents,
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.clientEvents),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.clientEvents),
            statusCode: 500,
            data: {'message': 'Server error'},
          ),
        ),
      );

      await container.read(clientEventsProvider.notifier).fetchBookedEvents();

      final state = container.read(clientEventsProvider);
      expect(state.bookedEvents, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('joinEvent sets joinSuccess on success', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.eventJoin('evt-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => {
            'booking_id': 'bk-201',
          });

      final success =
          await container.read(clientEventsProvider.notifier).joinEvent('evt-1');

      expect(success, isTrue);
      final state = container.read(clientEventsProvider);
      expect(state.joinSuccess, isTrue);
      expect(state.isLoading, false);
      expect(state.error, isNull);

      // Verify booking ID was stored
      final notifier = container.read(clientEventsProvider.notifier);
      expect(notifier.getBookingId('evt-1'), 'bk-201');
    });

    test('joinEvent returns false on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.eventJoin('evt-1'),
            body: any(named: 'body'),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.eventJoin('evt-1')),
          type: DioExceptionType.badResponse,
        ),
      );

      final success =
          await container.read(clientEventsProvider.notifier).joinEvent('evt-1');

      expect(success, isFalse);
      final state = container.read(clientEventsProvider);
      expect(state.joinSuccess, isFalse);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('cancelBooking removes event from bookedEvents on success', () async {
      // First, load booked events (to set up state with booking IDs)
      final bookedEventsJson = [
        {
          'id': 'evt-1',
          'trainer_id': 'trainer-1',
          'title': 'Morning Yoga',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'price': 0,
          'capacity': 20,
          'enrolled_count': 5,
          'category': 'Class',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
          'booking_id': 'bk-101',
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientEvents,
          )).thenAnswer((_) async => {
            'data': bookedEventsJson,
          });

      await container.read(clientEventsProvider.notifier).fetchBookedEvents();

      // Verify state before cancellation
      expect(container.read(clientEventsProvider).bookedEvents, hasLength(1));

      // Stub cancel endpoint
      when(() => mockApiClient.put(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      // Act
      final success = await container
          .read(clientEventsProvider.notifier)
          .cancelBooking('bk-101');

      // Assert
      expect(success, isTrue);
      final state = container.read(clientEventsProvider);
      expect(state.bookedEvents, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);

      // Verify booking ID was removed
      final notifier = container.read(clientEventsProvider.notifier);
      expect(notifier.getBookingId('evt-1'), isNull);
    });

    test('cancelBooking returns false on failure', () async {
      // First, load booked events
      final bookedEventsJson = [
        {
          'id': 'evt-1',
          'trainer_id': 'trainer-1',
          'title': 'Morning Yoga',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'price': 0,
          'capacity': 20,
          'enrolled_count': 5,
          'category': 'Class',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
          'booking_id': 'bk-101',
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientEvents,
          )).thenAnswer((_) async => {
            'data': bookedEventsJson,
          });

      await container.read(clientEventsProvider.notifier).fetchBookedEvents();

      // Stub cancel endpoint to fail
      when(() => mockApiClient.put(
            any(),
            body: any(named: 'body'),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.clientEventCancel('bk-101')),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act
      final success = await container
          .read(clientEventsProvider.notifier)
          .cancelBooking('bk-101');

      // Assert
      expect(success, isFalse);
      final state = container.read(clientEventsProvider);
      expect(state.bookedEvents, hasLength(1)); // Event not removed
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });
  });
}
