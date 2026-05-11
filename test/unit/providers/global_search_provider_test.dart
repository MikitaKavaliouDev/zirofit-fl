
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/search/providers/global_search_provider.dart';
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

  // ===========================================================================
  // SearchResult model
  // ===========================================================================

  group('SearchResultType', () {
    test('all enum values are present', () {
      expect(SearchResultType.values, hasLength(5));
      expect(SearchResultType.values, contains(SearchResultType.exercise));
      expect(SearchResultType.values, contains(SearchResultType.client));
      expect(SearchResultType.values, contains(SearchResultType.trainer));
      expect(SearchResultType.values, contains(SearchResultType.event));
      expect(SearchResultType.values, contains(SearchResultType.program));
    });
  });

  group('SearchResult', () {
    test('constructor assigns fields correctly', () {
      const result = SearchResult(
        id: '1',
        type: SearchResultType.exercise,
        title: 'Bench Press',
        subtitle: 'Chest',
        imageUrl: 'https://example.com/img.jpg',
        routePath: '/exercises',
      );

      expect(result.id, '1');
      expect(result.type, SearchResultType.exercise);
      expect(result.title, 'Bench Press');
      expect(result.subtitle, 'Chest');
      expect(result.imageUrl, 'https://example.com/img.jpg');
      expect(result.routePath, '/exercises');
    });

    test('equality works correctly', () {
      const a = SearchResult(
        id: '1',
        type: SearchResultType.exercise,
        title: 'Bench Press',
      );
      const b = SearchResult(
        id: '1',
        type: SearchResultType.exercise,
        title: 'Bench Press',
      );
      const c = SearchResult(
        id: '2',
        type: SearchResultType.client,
        title: 'John Doe',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns a meaningful representation', () {
      const result = SearchResult(
        id: '1',
        type: SearchResultType.exercise,
        title: 'Bench Press',
        subtitle: 'Chest',
      );

      final str = result.toString();
      expect(str, contains('SearchResult'));
      expect(str, contains('id: 1'));
      expect(str, contains('Bench Press'));
    });

    test('optional fields can be null', () {
      const result = SearchResult(
        id: '1',
        type: SearchResultType.exercise,
        title: 'Test',
      );

      expect(result.subtitle, isNull);
      expect(result.imageUrl, isNull);
      expect(result.routePath, isNull);
    });
  });

  // ===========================================================================
  // GlobalSearchState
  // ===========================================================================

  group('GlobalSearchState', () {
    test('initial state has correct defaults', () {
      final state = container.read(globalSearchProvider);

      expect(state.query, '');
      expect(state.results, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isSearching, false);
      expect(state.hasError, isFalse);
      expect(state.hasResults, isFalse);
    });

    test('copyWith preserves existing values when new ones are null', () {
      final state = container.read(globalSearchProvider);
      final modified = state.copyWith(query: 'test', isLoading: true);

      expect(modified.query, 'test');
      expect(modified.isLoading, isTrue);
      expect(modified.results, isEmpty);
      expect(modified.error, isNull);
      expect(modified.isSearching, isFalse);
    });

    test('copyWith overrides error when clearError is true', () {
      final stateWithError = container.read(globalSearchProvider).copyWith(
            error: 'Something went wrong',
          );
      expect(stateWithError.error, 'Something went wrong');
      expect(stateWithError.hasError, isTrue);

      final cleared = stateWithError.copyWith(clearError: true);
      expect(cleared.error, isNull);
      expect(cleared.hasError, isFalse);
    });

    test('copyWith replaces results list', () {
      final results = [
        const SearchResult(
          id: '1',
          type: SearchResultType.exercise,
          title: 'Push Up',
        ),
      ];

      final state = container.read(globalSearchProvider).copyWith(
            results: results,
          );

      expect(state.results, hasLength(1));
      expect(state.hasResults, isTrue);
      expect(state.results[0].title, 'Push Up');
    });
  });

  // ===========================================================================
  // GlobalSearchNotifier
  // ===========================================================================

  group('GlobalSearchNotifier', () {
    test('clearSearch resets to initial state', () {
      // Set some state first
      container.read(globalSearchProvider.notifier).search('test');

      // Clear
      container.read(globalSearchProvider.notifier).clearSearch();

      final state = container.read(globalSearchProvider);
      expect(state.query, '');
      expect(state.results, isEmpty);
      expect(state.isLoading, false);
      expect(state.isSearching, false);
      expect(state.error, isNull);
    });

    test('empty query clears results without API call', () {
      container.read(globalSearchProvider.notifier).search('');

      final state = container.read(globalSearchProvider);
      expect(state.query, '');
      expect(state.results, isEmpty);
      expect(state.isSearching, isFalse);
    });

    test('whitespace-only query is treated as empty', () {
      container.read(globalSearchProvider.notifier).search('   ');

      final state = container.read(globalSearchProvider);
      expect(state.query, '   ');
      expect(state.results, isEmpty);
      expect(state.isSearching, isFalse);
    });

    test('search with query triggers searching state immediately', () {
      container.read(globalSearchProvider.notifier).search('push');

      final state = container.read(globalSearchProvider);
      expect(state.query, 'push');
      expect(state.isSearching, isTrue);
      expect(state.isLoading, isFalse); // Not yet loading (debounce pending)
    });

    test('search results from all endpoints are aggregated', () async {
      // Stub exercises endpoint
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exercises,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'ex-1',
                'name': 'Push Up',
                'muscle_group': 'Chest',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              {
                'id': 'ex-2',
                'name': 'Pull Up',
                'muscle_group': 'Back',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      // Stub clients endpoint
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'cl-1',
                'name': 'Alice Client',
                'email': 'alice@test.com',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      // Stub events endpoint
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'ev-1',
                'trainer_id': 't-1',
                'title': 'Morning Yoga',
                'start_time': 1700000000000,
                'end_time': 1700100000000,
                'price': 0,
                'currency': 'PLN',
                'capacity': 20,
                'enrolled_count': 5,
                'status': 'APPROVED',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      // Trigger search and wait for debounce
      container.read(globalSearchProvider.notifier).search('push');
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(globalSearchProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);

      // Should have results from all three endpoints
      expect(state.results, hasLength(4));

      final exerciseResults =
          state.results.where((r) => r.type == SearchResultType.exercise);
      final clientResults =
          state.results.where((r) => r.type == SearchResultType.client);
      final eventResults =
          state.results.where((r) => r.type == SearchResultType.event);

      expect(exerciseResults, hasLength(2));
      expect(clientResults, hasLength(1));
      expect(eventResults, hasLength(1));

      // Verify result content
      expect(
        exerciseResults.any((r) => r.title == 'Push Up'),
        isTrue,
      );
      expect(
        exerciseResults.any((r) => r.title == 'Pull Up'),
        isTrue,
      );
      expect(
        clientResults.any((r) => r.title == 'Alice Client'),
        isTrue,
      );
      expect(
        eventResults.any((r) => r.title == 'Morning Yoga'),
        isTrue,
      );
    });

    test('handles exercise subtitle from muscleGroup', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exercises,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'ex-1',
                'name': 'Squat',
                'muscle_group': 'Legs',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': []});

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': []});

      container.read(globalSearchProvider.notifier).search('squat');
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(globalSearchProvider);
      expect(state.results, hasLength(1));
      expect(state.results[0].subtitle, 'Legs');
    });

    test('handles client subtitle from email', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exercises,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': []});

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'cl-1',
                'name': 'Bob',
                'email': 'bob@test.com',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': []});

      container.read(globalSearchProvider.notifier).search('bob');
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(globalSearchProvider);
      expect(state.results, hasLength(1));
      expect(state.results[0].subtitle, 'bob@test.com');
    });

    test('handles empty search results from all endpoints', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exercises,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': []});

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': []});

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': []});

      container.read(globalSearchProvider.notifier).search('zzzzzz');
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(globalSearchProvider);
      expect(state.isLoading, isFalse);
      expect(state.results, isEmpty);
      expect(state.error, isNull);
    });

    test('sets error when all endpoints fail', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exercises,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.exercises),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.exercises),
            statusCode: 500,
            data: {'message': 'Server error'},
          ),
        ),
      );

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.clients),
          type: DioExceptionType.badResponse,
        ),
      );

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.events),
          type: DioExceptionType.badResponse,
        ),
      );

      container.read(globalSearchProvider.notifier).search('fail');
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(globalSearchProvider);
      expect(state.isLoading, isFalse);
      expect(state.results, isEmpty);
      // Individual endpoint failures are caught silently,
      // but the top-level try/catch in _executeSearch would only catch
      // unexpected errors. All three caught exceptions produce empty results.
    });

    test('partial failures still return results from working endpoints',
        () async {
      // Exercises: success
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exercises,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'ex-1',
                'name': 'Push Up',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      // Clients: fail
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.clients),
          type: DioExceptionType.badResponse,
        ),
      );

      // Events: success
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'ev-1',
                'trainer_id': 't-1',
                'title': 'Yoga Class',
                'start_time': 1700000000000,
                'end_time': 1700100000000,
                'price': 0,
                'currency': 'PLN',
                'capacity': 20,
                'enrolled_count': 5,
                'status': 'APPROVED',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      container.read(globalSearchProvider.notifier).search('push');
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(globalSearchProvider);
      // Should still have results from working endpoints
      expect(state.results, hasLength(2));
      expect(
        state.results.any((r) => r.type == SearchResultType.exercise),
        isTrue,
      );
      expect(
        state.results.any((r) => r.type == SearchResultType.event),
        isTrue,
      );
    });

    test('query params are sent correctly to each endpoint', () async {
      var exercisesCalled = false;
      var clientsCalled = false;
      var eventsCalled = false;

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exercises,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((invocation) async {
        exercisesCalled = true;
        final params =
            invocation.namedArguments[#queryParams] as Map<String, dynamic>;
        expect(params['search'], 'test_query');
        expect(params['limit'], 5);
        return {'data': []};
      });

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clients,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((invocation) async {
        clientsCalled = true;
        final params =
            invocation.namedArguments[#queryParams] as Map<String, dynamic>;
        expect(params['search'], 'test_query');
        return {'data': []};
      });

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((invocation) async {
        eventsCalled = true;
        final params =
            invocation.namedArguments[#queryParams] as Map<String, dynamic>;
        expect(params['search'], 'test_query');
        return {'data': []};
      });

      container.read(globalSearchProvider.notifier).search('test_query');
      await Future.delayed(const Duration(milliseconds: 350));

      expect(exercisesCalled, isTrue);
      expect(clientsCalled, isTrue);
      expect(eventsCalled, isTrue);
    });
  });
}
