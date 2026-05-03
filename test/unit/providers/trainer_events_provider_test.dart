import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/events/providers/trainer_events_provider.dart';
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

  group('TrainerEventsNotifier', () {
    test('initial state is correct', () {
      final state = container.read(trainerEventsProvider);
      expect(state.events, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchEvents loads trainer events on success', () async {
      final eventsJson = [
        {
          'id': 'evt-1',
          'trainer_id': 'trainer-1',
          'title': 'My Yoga Class',
          'start_time': 1700000000000,
          'end_time': 1700003600000,
          'price': 49.99,
          'currency': 'PLN',
          'capacity': 20,
          'enrolled_count': 8,
          'category': 'Class',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerEvents,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': eventsJson,
          });

      await container.read(trainerEventsProvider.notifier).fetchEvents();

      final state = container.read(trainerEventsProvider);
      expect(state.events, hasLength(1));
      expect(state.events[0].title, 'My Yoga Class');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchEvents sets error on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.trainerEvents,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.trainerEvents),
          type: DioExceptionType.connectionError,
        ),
      );

      await container.read(trainerEventsProvider.notifier).fetchEvents();

      final state = container.read(trainerEventsProvider);
      expect(state.events, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('createEvent adds event to list on success', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.trainerEvents,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'evt-new',
              'trainer_id': 'trainer-1',
              'title': 'New Event',
              'start_time': 1700010000000,
              'end_time': 1700013600000,
              'price': 0,
              'capacity': 30,
              'enrolled_count': 0,
              'created_at': 1700010000000,
              'updated_at': 1700010000000,
            },
          });

      final success = await container
          .read(trainerEventsProvider.notifier)
          .createEvent({'title': 'New Event'});

      expect(success, isTrue);
      final state = container.read(trainerEventsProvider);
      expect(state.events, hasLength(1));
      expect(state.events[0].title, 'New Event');
      expect(state.isLoading, false);
    });

    test('createEvent returns false on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.trainerEvents,
            body: any(named: 'body'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.trainerEvents),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerEvents),
            statusCode: 400,
            data: {'message': 'Invalid data'},
          ),
        ),
      );

      final success = await container
          .read(trainerEventsProvider.notifier)
          .createEvent({'title': ''});

      expect(success, isFalse);
      final state = container.read(trainerEventsProvider);
      expect(state.error, isNotNull);
    });
  });
}
