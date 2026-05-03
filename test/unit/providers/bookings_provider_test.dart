import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/bookings/providers/bookings_provider.dart';
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

  group('BookingsNotifier', () {
    test('initial state is correct', () {
      final state = container.read(bookingsProvider);
      expect(state.bookings, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchBookings loads bookings on success', () async {
      final bookingsJson = [
        {
          'id': 'bkg-1',
          'trainer_id': 'trainer-1',
          'client_id': 'client-1',
          'client_name': 'John Doe',
          'client_email': 'john@example.com',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'status': 'PENDING',
          'client_notes': 'Looking forward to it',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
        {
          'id': 'bkg-2',
          'trainer_id': 'trainer-1',
          'client_id': 'client-2',
          'client_name': 'Jane Smith',
          'start_time': 1700007200000,
          'end_time': 1700010800000,
          'status': 'CONFIRMED',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': bookingsJson,
          });

      await container.read(bookingsProvider.notifier).fetchBookings();

      final state = container.read(bookingsProvider);
      expect(state.bookings, hasLength(2));
      expect(state.bookings[0].clientName, 'John Doe');
      expect(state.bookings[0].status, BookingStatus.pending);
      expect(state.bookings[1].clientName, 'Jane Smith');
      expect(state.bookings[1].status, BookingStatus.confirmed);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchBookings sets error on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.bookings),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.bookings),
            statusCode: 500,
            data: {'message': 'Server error'},
          ),
        ),
      );

      await container.read(bookingsProvider.notifier).fetchBookings();

      final state = container.read(bookingsProvider);
      expect(state.bookings, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('confirmBooking updates status to confirmed on success', () async {
      // First load bookings
      final bookingsJson = [
        {
          'id': 'bkg-1',
          'trainer_id': 'trainer-1',
          'client_id': 'client-1',
          'client_name': 'John Doe',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'status': 'PENDING',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': bookingsJson,
          });

      await container.read(bookingsProvider.notifier).fetchBookings();

      // Stub confirm booking PUT
      when<Future<Map<String, dynamic>>>(() => mockApiClient.put(
            ApiConstants.bookingConfirm('bkg-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'data': {'message': 'Confirmed'}});

      // Act
      final success =
          await container.read(bookingsProvider.notifier).confirmBooking('bkg-1');

      // Assert
      expect(success, isTrue);
      final state = container.read(bookingsProvider);
      expect(state.bookings.first.status, BookingStatus.confirmed);
    });

    test('confirmBooking returns false on failure', () async {
      // First load bookings
      final bookingsJson = [
        {
          'id': 'bkg-1',
          'trainer_id': 'trainer-1',
          'client_id': 'client-1',
          'client_name': 'John Doe',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'status': 'PENDING',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': bookingsJson,
          });

      await container.read(bookingsProvider.notifier).fetchBookings();

      // Stub confirm to fail
      when<Future<Map<String, dynamic>>>(() => mockApiClient.put(
            ApiConstants.bookingConfirm('bkg-1'),
            body: any(named: 'body'),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.bookingConfirm('bkg-1')),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act
      final success =
          await container.read(bookingsProvider.notifier).confirmBooking('bkg-1');

      // Assert
      expect(success, isFalse);
      final state = container.read(bookingsProvider);
      expect(state.bookings.first.status, BookingStatus.pending);
    });

    test('declineBooking updates status to cancelled on success', () async {
      // First load bookings
      final bookingsJson = [
        {
          'id': 'bkg-1',
          'trainer_id': 'trainer-1',
          'client_id': 'client-1',
          'client_name': 'John Doe',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'status': 'PENDING',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': bookingsJson,
          });

      await container.read(bookingsProvider.notifier).fetchBookings();

      // Stub decline booking PUT
      when<Future<Map<String, dynamic>>>(() => mockApiClient.put(
            ApiConstants.bookingDecline('bkg-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'data': {'message': 'Declined'}});

      // Act
      final success =
          await container.read(bookingsProvider.notifier).declineBooking('bkg-1');

      // Assert
      expect(success, isTrue);
      final state = container.read(bookingsProvider);
      expect(state.bookings.first.status, BookingStatus.cancelled);
    });

    test('declineBooking returns false on failure', () async {
      // First load bookings
      final bookingsJson = [
        {
          'id': 'bkg-1',
          'trainer_id': 'trainer-1',
          'client_id': 'client-1',
          'client_name': 'John Doe',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'status': 'PENDING',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': bookingsJson,
          });

      await container.read(bookingsProvider.notifier).fetchBookings();

      // Stub decline to fail
      when<Future<Map<String, dynamic>>>(() => mockApiClient.put(
            ApiConstants.bookingDecline('bkg-1'),
            body: any(named: 'body'),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.bookingDecline('bkg-1')),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act
      final success =
          await container.read(bookingsProvider.notifier).declineBooking('bkg-1');

      // Assert
      expect(success, isFalse);
      final state = container.read(bookingsProvider);
      expect(state.bookings.first.status, BookingStatus.pending);
    });
  });
}
