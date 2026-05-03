import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/events/providers/events_provider.dart';
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

  group('EventsNotifier', () {
    test('initial state is correct', () {
      final state = container.read(eventsProvider);
      expect(state.events, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasMore, true);
      expect(state.currentPage, 1);
    });

    test('fetchEvents loads events on success', () async {
      final eventsJson = [
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
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': eventsJson,
            'hasMore': false,
          });

      await container.read(eventsProvider.notifier).fetchEvents();

      final state = container.read(eventsProvider);
      expect(state.events, hasLength(2));
      expect(state.events[0].title, 'Morning Yoga');
      expect(state.events[1].title, 'HIIT Session');
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasMore, false);
    });

    test('fetchEvents sets error on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.events),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.events),
            statusCode: 500,
            data: {'message': 'Server error'},
          ),
        ),
      );

      await container.read(eventsProvider.notifier).fetchEvents();

      final state = container.read(eventsProvider);
      expect(state.events, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('joinEvent increments enrolled count on success', () async {
      // First load events
      final eventsJson = [
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
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': eventsJson,
            'hasMore': false,
          });

      await container.read(eventsProvider.notifier).fetchEvents();

      // Stub join event POST
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.eventJoin('evt-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'data': {'message': 'Joined'}});

      // Act
      final success =
          await container.read(eventsProvider.notifier).joinEvent('evt-1');

      // Assert
      expect(success, isTrue);
      final state = container.read(eventsProvider);
      expect(state.events.first.enrolledCount, 6);
    });

    test('joinEvent returns false on failure', () async {
      // First load events
      final eventsJson = [
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
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': eventsJson,
            'hasMore': false,
          });

      await container.read(eventsProvider.notifier).fetchEvents();

      // Stub join event POST to fail
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.eventJoin('evt-1'),
            body: any(named: 'body'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.eventJoin('evt-1')),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act
      final success =
          await container.read(eventsProvider.notifier).joinEvent('evt-1');

      // Assert
      expect(success, isFalse);
    });

    test('loadMore does nothing when hasMore is false', () async {
      final eventsJson = [
        {
          'id': 'evt-1',
          'trainer_id': 'trainer-1',
          'title': 'Yoga',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'price': 0,
          'capacity': 20,
          'enrolled_count': 5,
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': eventsJson,
            'hasMore': false,
          });

      await container.read(eventsProvider.notifier).fetchEvents();
      expect(container.read(eventsProvider).hasMore, false);

      // Try to load more – should not call API
      await container.read(eventsProvider.notifier).loadMore();

      // Still only 1 event (no API call for page 2)
      expect(container.read(eventsProvider).events, hasLength(1));
    });

    test('loadMore fetches next page when hasMore is true', () async {
      final page1Json = [
        {
          'id': 'evt-1',
          'trainer_id': 'trainer-1',
          'title': 'Event 1',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'price': 0,
          'capacity': 20,
          'enrolled_count': 0,
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];
      final page2Json = [
        {
          'id': 'evt-2',
          'trainer_id': 'trainer-1',
          'title': 'Event 2',
          'start_time': 1700007200000,
          'end_time': 1700010800000,
          'price': 10,
          'capacity': 10,
          'enrolled_count': 3,
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      // Return page 1 on first call, page 2 on second
      var callCount = 0;
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return {'data': page1Json, 'hasMore': true};
        }
        return {'data': page2Json, 'hasMore': false};
      });

      await container.read(eventsProvider.notifier).fetchEvents();
      expect(container.read(eventsProvider).events, hasLength(1));
      expect(container.read(eventsProvider).hasMore, true);

      await container.read(eventsProvider.notifier).loadMore();

      final state = container.read(eventsProvider);
      expect(state.events, hasLength(2));
      expect(state.hasMore, false);
    });
  });
}
