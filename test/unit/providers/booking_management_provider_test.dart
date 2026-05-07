import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/bookings/providers/booking_management_provider.dart';
import '../../helpers/provider_utils.dart';

class MockApiClient extends Mock implements ApiClient {}

/// Helper to create a booking JSON map with proper field types.
Map<String, dynamic> _bookingJson({
  required String id,
  required String clientName,
  required String status,
  String clientEmail = 'test@example.com',
  int startTime = 1700000000000,
  int endTime = 1700003600000,
}) {
  return {
    'id': id,
    'trainer_id': 'trainer-1',
    'client_id': 'client-$id',
    'client_name': clientName,
    'client_email': clientEmail,
    'start_time': startTime,
    'end_time': endTime,
    'status': status,
    'created_at': 1700000000000,
    'updated_at': 1700000000000,
  };
}

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

  group('BookingManagementNotifier', () {
    test('initial state is correct', () {
      final state = container.read(bookingManagementProvider);
      expect(state.pendingBookings, isEmpty);
      expect(state.confirmedBookings, isEmpty);
      expect(state.declinedBookings, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isActionInProgress, false);
    });

    // -----------------------------------------------------------------------
    // Test 1: fetchAll returns pending/confirmed/declined bookings
    // -----------------------------------------------------------------------
    test('fetchAll loads and categorizes bookings', () async {
      int callIdx = 0;
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerBookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async {
        callIdx++;
        if (callIdx == 1) {
          return {
            'data': [
              _bookingJson(
                  id: 'bkg-p1',
                  clientName: 'John Pending',
                  status: 'PENDING'),
            ],
          };
        } else if (callIdx == 2) {
          return {
            'data': [
              _bookingJson(
                  id: 'bkg-c1',
                  clientName: 'Jane Confirmed',
                  status: 'CONFIRMED'),
            ],
          };
        } else {
          return {
            'data': [
              _bookingJson(
                  id: 'bkg-d1',
                  clientName: 'Bob Declined',
                  status: 'CANCELLED'),
            ],
          };
        }
      });

      await container.read(bookingManagementProvider.notifier).fetchAll();

      final state = container.read(bookingManagementProvider);
      expect(state.pendingBookings, hasLength(1));
      expect(state.pendingBookings[0].clientName, 'John Pending');
      expect(state.pendingBookings[0].status, BookingStatus.pending);

      expect(state.confirmedBookings, hasLength(1));
      expect(state.confirmedBookings[0].clientName, 'Jane Confirmed');
      expect(state.confirmedBookings[0].status, BookingStatus.confirmed);

      expect(state.declinedBookings, hasLength(1));
      expect(state.declinedBookings[0].clientName, 'Bob Declined');
      expect(state.declinedBookings[0].status, BookingStatus.cancelled);

      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // -----------------------------------------------------------------------
    // Test 2: approveBooking changes status locally and calls POST
    // -----------------------------------------------------------------------
    test('approveBooking moves booking from pending to confirmed locally',
        () async {
      // Seed state with one pending booking — fetchAll returns different data
      // per status so only the pending list gets populated.
      int fetchCallIdx = 0;
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerBookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async {
        fetchCallIdx++;
        if (fetchCallIdx == 1) {
          return {
            'data': [
              _bookingJson(
                  id: 'bkg-p1',
                  clientName: 'John Pending',
                  status: 'PENDING'),
            ],
          };
        }
        return {'data': <Map<String, dynamic>>[]};
      });

      await container.read(bookingManagementProvider.notifier).fetchAll();
      expect(
          container.read(bookingManagementProvider).pendingBookings.length, 1);
      expect(
          container.read(bookingManagementProvider).confirmedBookings, isEmpty);
      expect(
          container.read(bookingManagementProvider).declinedBookings, isEmpty);

      // Stub POST approve endpoint
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookingApprove('bkg-p1'),
          )).thenAnswer((_) async => {'data': {'message': 'Approved'}});

      // Act
      final success = await container
          .read(bookingManagementProvider.notifier)
          .approveBooking('bkg-p1');

      // Assert
      expect(success, isTrue);
      final state = container.read(bookingManagementProvider);
      expect(state.pendingBookings, isEmpty);
      expect(state.confirmedBookings, hasLength(1));
      expect(state.confirmedBookings[0].id, 'bkg-p1');
      expect(state.confirmedBookings[0].status, BookingStatus.confirmed);
      expect(state.isActionInProgress, false);
      expect(state.error, isNull);

      verify<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookingApprove('bkg-p1'),
          )).called(1);
    });

    // -----------------------------------------------------------------------
    // Test 3: declineBooking changes status locally and calls POST
    // -----------------------------------------------------------------------
    test('declineBooking moves booking from pending to declined locally',
        () async {
      // Seed state with one pending booking
      int fetchCallIdx = 0;
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerBookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async {
        fetchCallIdx++;
        if (fetchCallIdx == 1) {
          return {
            'data': [
              _bookingJson(
                  id: 'bkg-p1',
                  clientName: 'John Pending',
                  status: 'PENDING'),
            ],
          };
        }
        return {'data': <Map<String, dynamic>>[]};
      });

      await container.read(bookingManagementProvider.notifier).fetchAll();
      expect(
          container.read(bookingManagementProvider).pendingBookings.length, 1);
      expect(
          container.read(bookingManagementProvider).declinedBookings, isEmpty);

      // Stub POST decline endpoint
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookingDecline('bkg-p1'),
          )).thenAnswer((_) async => {'data': {'message': 'Declined'}});

      // Act
      final success = await container
          .read(bookingManagementProvider.notifier)
          .declineBooking('bkg-p1');

      // Assert
      expect(success, isTrue);
      final state = container.read(bookingManagementProvider);
      expect(state.pendingBookings, isEmpty);
      expect(state.declinedBookings, hasLength(1));
      expect(state.declinedBookings[0].id, 'bkg-p1');
      expect(state.declinedBookings[0].status, BookingStatus.cancelled);
      expect(state.isActionInProgress, false);

      verify<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookingDecline('bkg-p1'),
          )).called(1);
    });

    // -----------------------------------------------------------------------
    // Test 4: error handling
    // -----------------------------------------------------------------------
    test('fetchAll sets error on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerBookings,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.trainerBookings),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions:
                RequestOptions(path: ApiConstants.trainerBookings),
            statusCode: 500,
            data: {'message': 'Server error'},
          ),
        ),
      );

      await container.read(bookingManagementProvider.notifier).fetchAll();

      final state = container.read(bookingManagementProvider);
      expect(state.pendingBookings, isEmpty);
      expect(state.confirmedBookings, isEmpty);
      expect(state.declinedBookings, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('approveBooking returns false on API failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookingApprove('bkg-1'),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.bookingApprove('bkg-1')),
          type: DioExceptionType.badResponse,
        ),
      );

      final success = await container
          .read(bookingManagementProvider.notifier)
          .approveBooking('bkg-1');

      expect(success, isFalse);
      final state = container.read(bookingManagementProvider);
      expect(state.isActionInProgress, false);
      expect(state.error, isNotNull);
    });

    test('declineBooking returns false on API failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookingDecline('bkg-1'),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.bookingDecline('bkg-1')),
          type: DioExceptionType.badResponse,
        ),
      );

      final success = await container
          .read(bookingManagementProvider.notifier)
          .declineBooking('bkg-1');

      expect(success, isFalse);
      final state = container.read(bookingManagementProvider);
      expect(state.isActionInProgress, false);
      expect(state.error, isNotNull);
    });

    test('approveBooking sets isActionInProgress during the call', () async {
      final completer = Completer<Map<String, dynamic>>();

      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.bookingApprove('bkg-1'),
          )).thenAnswer((_) => completer.future);

      // Seed pending bookings so the local move can find the booking
      int fetchCallIdx = 0;
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerBookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async {
        fetchCallIdx++;
        if (fetchCallIdx == 1) {
          return {
            'data': [
              _bookingJson(
                  id: 'bkg-1',
                  clientName: 'John Pending',
                  status: 'PENDING'),
            ],
          };
        }
        return {'data': <Map<String, dynamic>>[]};
      });

      await container.read(bookingManagementProvider.notifier).fetchAll();

      final future = container
          .read(bookingManagementProvider.notifier)
          .approveBooking('bkg-1');

      expect(
          container.read(bookingManagementProvider).isActionInProgress, isTrue);

      completer.complete({'data': {'message': 'Approved'}});

      await future;

      expect(container.read(bookingManagementProvider).isActionInProgress,
          isFalse);
    });
  });
}
