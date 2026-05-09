import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/clients/providers/client_list_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ClientListNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = ClientListNotifier(apiClient: mockApiClient);
  });

  group('ClientListNotifier', () {
    test('initial state has empty clients, not loading, empty search', () {
      final state = notifier.state;
      expect(state.clients, isEmpty);
      expect(state.filteredClients, isEmpty);
      expect(state.isLoading, false);
      expect(state.searchQuery, '');
      expect(state.error, isNull);
    });

    test('fetchClients sets loading true before completion', () async {
      // Real API response: {"data": {"clients": [...]}}
      when(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': {'clients': []}});

      final future = notifier.fetchClients();
      // isLoading is set synchronously before the async gap
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchClients populates list on success', () async {
      // Real API response shape: {"data": {"clients": [...]}}
      // Note: Client model expects created_at/updated_at as int (Unix timestamps)
      final mockData = <String, dynamic>{
        'data': {
          'clients': [
            {
              'id': 'client-1',
              'name': 'Alice Johnson',
              'email': 'alice@test.com',
              'status': 'active',
              'created_at': 1704067200,  // Unix timestamp
              'updated_at': 1704067200,
            },
            {
              'id': 'client-2',
              'name': 'Bob Smith',
              'email': 'bob@test.com',
              'status': 'active',
              'created_at': 1704067200,
              'updated_at': 1704067200,
            },
          ],
        },
      };
      when(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => mockData);

      await notifier.fetchClients();

      final state = notifier.state;
      expect(state.clients.length, 2);
      expect(state.clients[0].name, 'Alice Johnson');
      expect(state.clients[1].name, 'Bob Smith');
      expect(state.filteredClients.length, 2);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.searchQuery, '');
    });

    test('fetchClients passes search parameter in query', () async {
      // Real API response: {"data": {"clients": [...]}}
      when(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': {'clients': []}});

      await notifier.fetchClients(search: 'Alice');

      // Verify the search param was included
      verify(() => mockApiClient.get(
        ApiConstants.clients,
        queryParams: {
          'search': 'Alice',
          'sortBy': 'name',
        },
      )).called(1);
    });

    test('fetchClients sets error on failure', () async {
      when(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clients),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.clients),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Internal server error'},
          },
        ),
      ));

      await notifier.fetchClients();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Internal server error');
      expect(state.clients, isEmpty);
      expect(state.hasError, isTrue);
    });

    test('fetchClients handles connection timeout error', () async {
      when(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: ApiConstants.clients),
      ));

      await notifier.fetchClients();

      final state = notifier.state;
      expect(state.error, 'Connection timeout. Please try again.');
    });

    test('fetchClients handles network error', () async {
      when(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: ApiConstants.clients),
      ));

      await notifier.fetchClients();

      final state = notifier.state;
      expect(state.error, 'No internet connection. Please check your network.');
    });

    test('fetchClients handles non-Dio exception', () async {
      when(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Unexpected error'));

      await notifier.fetchClients();

      final state = notifier.state;
      expect(state.error, 'Exception: Unexpected error');
    });

    group('setSearch', () {
      setUp(() async {
        // Real API response shape: {"data": {"clients": [...]}}
        // Note: Client model expects created_at/updated_at as int (Unix timestamps)
        final mockData = <String, dynamic>{
          'data': {
            'clients': [
              {
                'id': '1',
                'name': 'Alice Johnson',
                'email': 'alice@test.com',
                'status': 'active',
                'created_at': 1704067200,
                'updated_at': 1704067200,
              },
              {
                'id': '2',
                'name': 'Bob Smith',
                'email': 'bob@test.com',
                'status': 'active',
                'created_at': 1704067200,
                'updated_at': 1704067200,
              },
              {
                'id': '3',
                'name': 'Charlie Brown',
                'email': 'charlie@test.com',
                'status': 'active',
                'created_at': 1704067200,
                'updated_at': 1704067200,
              },
            ],
          },
        };
        when(() => mockApiClient.get(
              ApiConstants.clients,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => mockData);
        await notifier.fetchClients();
      });

      test('filters by name (case-insensitive)', () {
        notifier.setSearch('alice');
        expect(notifier.state.searchQuery, 'alice');
        expect(notifier.state.filteredClients.length, 1);
        expect(notifier.state.filteredClients.first.name,
            'Alice Johnson');
      });

      test('filters by email', () {
        notifier.setSearch('bob@test.com');
        expect(notifier.state.filteredClients.length, 1);
        expect(notifier.state.filteredClients.first.name,
            'Bob Smith');
      });

      test('empty query returns all clients', () {
        notifier.setSearch('');
        expect(notifier.state.filteredClients.length, 3);
      });

      test('no match returns empty list', () {
        notifier.setSearch('zzzz');
        expect(notifier.state.filteredClients, isEmpty);
      });

      test('trims whitespace from query internally', () {
        notifier.setSearch('  Charlie  ');
        // searchQuery stores the original input; trimming happens internally
        expect(notifier.state.searchQuery, '  Charlie  ');
        // "  Charlie  " → trimmed to "charlie" → matches "Charlie Brown"
        expect(notifier.state.filteredClients.length, 1);
        expect(notifier.state.filteredClients.first.name,
            'Charlie Brown');
      });
    });
  });
}
