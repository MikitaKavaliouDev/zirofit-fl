import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/bookings/providers/bookings_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _testTimestamp = 1700000000000;

Map<String, dynamic> _bookingJson({
  String id = 'booking-1',
  String status = 'PENDING',
  String? clientName,
}) => {
      'id': id,
      'start_time': _testTimestamp,
      'end_time': _testTimestamp + 3600000,
      'status': status,
      'trainer_id': 'trainer-1',
      'client_id': 'client-1',
      'client_name': clientName ?? 'John Doe',
      'client_email': 'john@test.com',
      'client_notes': null,
      'data_sharing_approved': null,
      'data_sharing_approved_at': null,
      'created_at': _testTimestamp,
      'updated_at': _testTimestamp,
      'deleted_at': null,
    };

Map<String, dynamic> _responseWithData(List<Map<String, dynamic>> items) =>
    <String, dynamic>{'data': items};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      bookingsProvider.overrideWith(
        (ref) => BookingsNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('BookingsNotifier', () {
    test('initial state has empty bookings and is not loading', () {
      final state = container.read(bookingsProvider);
      expect(state.bookings, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchBookings populates the booking list', () async {
      final bookingListJson = [
        _bookingJson(id: 'b-1', clientName: 'Alice'),
        _bookingJson(id: 'b-2', clientName: 'Bob'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _responseWithData(bookingListJson));

      await container.read(bookingsProvider.notifier).fetchBookings();

      final state = container.read(bookingsProvider);
      expect(state.bookings, hasLength(2));
      expect(state.bookings[0].id, 'b-1');
      expect(state.bookings[0].clientName, 'Alice');
      expect(state.bookings[1].clientName, 'Bob');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchBookings handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _responseWithData([]));

      await container.read(bookingsProvider.notifier).fetchBookings();

      final state = container.read(bookingsProvider);
      expect(state.bookings, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('confirmBooking updates status to confirmed', () async {
      // Pre-populate with a pending booking
      final bookingJson = _bookingJson(id: 'b-1', status: 'PENDING');
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _responseWithData([bookingJson]));

      await container.read(bookingsProvider.notifier).fetchBookings();
      expect(
        container.read(bookingsProvider).bookings[0].status.name,
        'pending',
      );

      // Mock confirm endpoint
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.bookingConfirm('b-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      final success =
          await container.read(bookingsProvider.notifier).confirmBooking('b-1');

      expect(success, isTrue);
      final state = container.read(bookingsProvider);
      expect(state.bookings[0].status.name, 'confirmed');
      expect(state.error, isNull);
    });

    test('declineBooking updates status to cancelled', () async {
      // Pre-populate with a pending booking
      final bookingJson = _bookingJson(id: 'b-1', status: 'PENDING');
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _responseWithData([bookingJson]));

      await container.read(bookingsProvider.notifier).fetchBookings();
      expect(
        container.read(bookingsProvider).bookings[0].status.name,
        'pending',
      );

      // Mock decline endpoint
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.bookingDecline('b-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      final success =
          await container.read(bookingsProvider.notifier).declineBooking('b-1');

      expect(success, isTrue);
      final state = container.read(bookingsProvider);
      expect(state.bookings[0].status.name, 'cancelled');
      expect(state.error, isNull);
    });

    test('fetchBookings sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.bookings,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('API error'));

      await container.read(bookingsProvider.notifier).fetchBookings();

      final state = container.read(bookingsProvider);
      expect(state.bookings, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('confirmBooking sets error on API failure', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.bookingConfirm('b-1'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Confirm failed'));

      final success =
          await container.read(bookingsProvider.notifier).confirmBooking('b-1');

      expect(success, isFalse);
      final state = container.read(bookingsProvider);
      expect(state.error, isNotNull);
    });

    test('declineBooking returns false on API failure', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.bookingDecline('b-1'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Decline failed'));

      final success =
          await container.read(bookingsProvider.notifier).declineBooking('b-1');

      expect(success, isFalse);
      final state = container.read(bookingsProvider);
      expect(state.error, isNotNull);
    });
  });
}
