import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/support_ticket.dart';
import 'package:zirofit_fl/features/support/providers/support_ticket_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late SupportTicketNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = SupportTicketNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------

  Map<String, dynamic> ticketJson() => {
        'id': 'ticket-1',
        'user_id': 'user-1',
        'category': 'bug_report',
        'message': 'Test message',
        'status': 'OPEN',
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
      };

  // ===========================================================================
  // SupportTicketsState
  // ===========================================================================

  group('SupportTicketsState', () {
    test('initial state has default values', () {
      expect(notifier.state.tickets, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.isSending, false);
    });

    test('copyWith clearError removes error', () {
      const state = SupportTicketsState(error: 'Some error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });
  });

  // ===========================================================================
  // fetchTickets
  // ===========================================================================

  group('fetchTickets', () {
    test('sets isLoading to true during call then populates tickets on success',
        () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenAnswer((_) async => {
            'data': [ticketJson()],
          });

      final future = notifier.fetchTickets();

      // During call
      expect(notifier.state.isLoading, true);

      await future;

      // After success
      expect(notifier.state.isLoading, false);
      expect(notifier.state.tickets.length, 1);
      expect(notifier.state.tickets[0].id, 'ticket-1');
      expect(notifier.state.tickets[0].message, 'Test message');
      expect(notifier.state.error, isNull);

      // Verify correct endpoint was called
      verify(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).called(1);
    });

    test('keeps tickets empty when response has empty data list', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenAnswer((_) async => {
            'data': [],
          });

      await notifier.fetchTickets();

      expect(notifier.state.tickets, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('sets error on DioException without response data', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      await notifier.fetchTickets();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Network error. Please try again.');
      expect(notifier.state.tickets, isEmpty);
    });

    test('sets error on generic Exception', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenThrow(Exception('Unexpected failure'));

      await notifier.fetchTickets();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Exception: Unexpected failure');
      expect(notifier.state.tickets, isEmpty);
    });
  });

  // ===========================================================================
  // createTicket
  // ===========================================================================

  group('createTicket', () {
    test('sets isSending to true then prepends ticket and returns true on success',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.supportTickets,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {
            'data': ticketJson(),
          });

      final future = notifier.createTicket('bug_report', 'Test message');

      // During call
      expect(notifier.state.isSending, true);

      final result = await future;

      expect(result, true);
      expect(notifier.state.isSending, false);
      expect(notifier.state.tickets.length, 1);
      expect(notifier.state.tickets[0].id, 'ticket-1');
      expect(notifier.state.tickets[0].category.toJson(), 'BUG_REPORT');
      expect(notifier.state.tickets[0].message, 'Test message');
      expect(notifier.state.error, isNull);
    });

    test('returns true and does not prepend when response has no data', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.supportTickets,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {});

      final result = await notifier.createTicket('bug_report', 'Test message');

      expect(result, true);
      expect(notifier.state.isSending, false);
      expect(notifier.state.tickets, isEmpty);
    });

    test('sets error and returns false on DioException', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.supportTickets,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      final result = await notifier.createTicket('bug_report', 'Test');

      expect(result, false);
      expect(notifier.state.isSending, false);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.tickets, isEmpty);
    });

    test('sets error and returns false on generic Exception', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.supportTickets,
            body: any(named: 'body'),
          )).thenThrow(Exception('Create failed'));

      final result = await notifier.createTicket('bug_report', 'Test');

      expect(result, false);
      expect(notifier.state.isSending, false);
      expect(notifier.state.error, 'Exception: Create failed');
      expect(notifier.state.tickets, isEmpty);
    });

    test('sends correct endpoint and request body', () async {
      Map<String, dynamic>? capturedBody;

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.supportTickets,
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        capturedBody = invocation.namedArguments[#body] as Map<String, dynamic>?;
        return {'data': ticketJson()};
      });

      await notifier.createTicket('feature_request', 'Need a new feature');

      // Verify endpoint
      verify(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.supportTickets,
            body: any(named: 'body'),
          )).called(1);

      // Verify body content
      expect(capturedBody, isNotNull);
      expect(capturedBody!['category'], 'feature_request');
      expect(capturedBody!['message'], 'Need a new feature');
    });
  });

  // ===========================================================================
  // _extractErrorMessage (tested indirectly via fetchTickets)
  // ===========================================================================

  group('_extractErrorMessage', () {
    test('extracts nested error map message from DioException', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 400,
          data: {'error': {'message': 'Structured error message'}},
        ),
      ));

      await notifier.fetchTickets();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Structured error message');
    });

    test('extracts flat message field from DioException', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 400,
          data: {'message': 'Flat error message'},
        ),
      ));

      await notifier.fetchTickets();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Flat error message');
    });

    test('uses toString for non-Dio exception', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenThrow(42);

      await notifier.fetchTickets();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, '42');
    });
  });
}
