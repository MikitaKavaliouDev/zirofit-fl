import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/support_ticket.dart';
import 'package:zirofit_fl/features/support/providers/support_ticket_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _testTimestamp = 1700000000000;

Map<String, dynamic> _ticketJson({
  String id = 'ticket-1',
  String status = 'OPEN',
  String category = 'BUG_REPORT',
}) => {
      'id': id,
      'user_id': 'user-1',
      'category': category,
      'message': 'Test message',
      'app_version': '1.0.0',
      'os_version': 'Android 14',
      'status': status,
      'created_at': _testTimestamp,
      'updated_at': _testTimestamp,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      supportTicketsProvider.overrideWith(
        (ref) => SupportTicketNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('SupportTicketNotifier', () {
    test('initial state has empty tickets, not loading, no error', () {
      final state = container.read(supportTicketsProvider);
      expect(state.tickets, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSending, isFalse);
    });

    test('fetchTickets populates the ticket list', () async {
      final ticketListJson = [
        _ticketJson(id: 't-1', status: 'OPEN'),
        _ticketJson(id: 't-2', status: 'RESOLVED'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': ticketListJson,
          });

      await container.read(supportTicketsProvider.notifier).fetchTickets();

      final state = container.read(supportTicketsProvider);
      expect(state.tickets, hasLength(2));
      expect(state.tickets[0].id, 't-1');
      expect(state.tickets[0].status, 'OPEN');
      expect(state.tickets[1].status, 'RESOLVED');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchTickets handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[],
          });

      await container.read(supportTicketsProvider.notifier).fetchTickets();

      final state = container.read(supportTicketsProvider);
      expect(state.tickets, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchTickets handles null data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': null,
          });

      await container.read(supportTicketsProvider.notifier).fetchTickets();

      final state = container.read(supportTicketsProvider);
      expect(state.tickets, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchTickets sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.supportTickets,
          )).thenThrow(Exception('API error'));

      await container.read(supportTicketsProvider.notifier).fetchTickets();

      final state = container.read(supportTicketsProvider);
      expect(state.tickets, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('createTicket adds ticket to state and returns true', () async {
      final newTicketJson = _ticketJson(id: 't-new');

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.supportTickets,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': newTicketJson,
          });

      final success = await container
          .read(supportTicketsProvider.notifier)
          .createTicket('BUG_REPORT', 'Found a bug');

      expect(success, isTrue);

      final state = container.read(supportTicketsProvider);
      expect(state.tickets, hasLength(1));
      expect(state.tickets.first.id, 't-new');
      expect(state.tickets.first.category.name, 'bugReport');
      expect(state.isSending, isFalse);
    });

    test('createTicket handles null data in response', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.supportTickets,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': null,
          });

      final success = await container
          .read(supportTicketsProvider.notifier)
          .createTicket('FEATURE_REQUEST', 'Add new feature');

      expect(success, isTrue);

      final state = container.read(supportTicketsProvider);
      expect(state.tickets, isEmpty);
      expect(state.isSending, isFalse);
    });

    test('createTicket sets error on API failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.supportTickets,
            body: any(named: 'body'),
          )).thenThrow(Exception('Create failed'));

      final success = await container
          .read(supportTicketsProvider.notifier)
          .createTicket('GENERAL_SUPPORT', 'Help');

      expect(success, isFalse);

      final state = container.read(supportTicketsProvider);
      expect(state.isSending, isFalse);
      expect(state.error, isNotNull);
    });
  });
}
