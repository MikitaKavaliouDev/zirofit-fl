import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/events/providers/events_provider.dart';
import 'package:zirofit_fl/features/events/providers/trainer_events_provider.dart';
import '../helpers/provider_utils.dart';
import '../helpers/response_fixture.dart';

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

  group('Event Flow', () {
    test('create event → list appears → join event', () async {
      // -----------------------------------------------------------------------
      // 1. Trainer creates an event
      // Backend shape: POST /trainer/events → {"data": {event fields}}
      // -----------------------------------------------------------------------
      final newEventData = {
        'id': 'evt-created',
        'trainer_id': 'trainer-1',
        'title': 'Test Competition',
        'start_time': 1700000000000,
        'end_time': 1700003600000,
        'price': 0,
        'capacity': 30,
        'enrolled_count': 0,
        'category': 'Competition',
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
      };

      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.trainerEvents,
            body: any(named: 'body'),
          )).thenAnswer((_) async => dataResponse(newEventData));

      final createSuccess = await container
          .read(trainerEventsProvider.notifier)
          .createEvent({'title': 'Test Competition', 'capacity': 30});

      expect(createSuccess, isTrue);

      var trainerState = container.read(trainerEventsProvider);
      expect(trainerState.events, hasLength(1));
      expect(trainerState.events[0].title, 'Test Competition');
      expect(trainerState.events[0].capacity, 30);
      expect(trainerState.events[0].enrolledCount, 0);

      // -----------------------------------------------------------------------
      // 2. Client fetches events and sees the created event
      // Backend shape: GET /events → {"data": [event, ...], "hasMore": false}
      // -----------------------------------------------------------------------
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [newEventData],
            'hasMore': false,
          });

      await container.read(eventsProvider.notifier).fetchEvents();

      var clientState = container.read(eventsProvider);
      expect(clientState.events, hasLength(1));
      expect(clientState.events[0].title, 'Test Competition');
      expect(clientState.events[0].enrolledCount, 0);

      // -----------------------------------------------------------------------
      // 3. Client joins the event
      // Backend shape: POST /events/[id]/join → {"data": {"message": "..."}}
      // -----------------------------------------------------------------------
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.eventJoin('evt-created'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => dataResponse({'message': 'Joined'}));

      final joinSuccess =
          await container.read(eventsProvider.notifier).joinEvent('evt-created');

      expect(joinSuccess, isTrue);

      // Verify enrolled count increased
      clientState = container.read(eventsProvider);
      expect(clientState.events[0].enrolledCount, 1);

      // -----------------------------------------------------------------------
      // 4. Verify trainer also sees the updated count after refresh
      // -----------------------------------------------------------------------
      // Re-mock trainer events to show updated data
      final updatedEventData = {...newEventData, 'enrolled_count': 1};
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerEvents,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': [updatedEventData]});

      await container.read(trainerEventsProvider.notifier).refresh();

      trainerState = container.read(trainerEventsProvider);
      expect(trainerState.events[0].enrolledCount, 1);
    });

    // -------------------------------------------------------------------------
    // Response shape & error handling tests
    // -------------------------------------------------------------------------

    test('fetchEvents handles empty list from backend', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': <dynamic>[],
            'hasMore': false,
          });

      await container.read(eventsProvider.notifier).fetchEvents();

      final state = container.read(eventsProvider);
      expect(state.events, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchEvents sets error on API failure with error envelope', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.events,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.events),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.events),
          statusCode: 500,
          data: errorResponse(message: 'Server error'),
        ),
        type: DioExceptionType.badResponse,
      ));

      await container.read(eventsProvider.notifier).fetchEvents();

      final state = container.read(eventsProvider);
      expect(state.error, contains('Server error'));
      expect(state.isLoading, isFalse);
    });

    test('createEvent sets error on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.trainerEvents,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerEvents),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerEvents),
          statusCode: 422,
          data: errorResponse(message: 'Validation failed'),
        ),
        type: DioExceptionType.badResponse,
      ));

      final success = await container
          .read(trainerEventsProvider.notifier)
          .createEvent({'title': ''});

      expect(success, isFalse);
      final state = container.read(trainerEventsProvider);
      expect(state.error, contains('Validation failed'));
    });

    test('trainerEvents handles empty response', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerEvents,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await container.read(trainerEventsProvider.notifier).fetchEvents();

      final state = container.read(trainerEventsProvider);
      expect(state.events, isEmpty);
      expect(state.isLoading, isFalse);
    });
  });
}
