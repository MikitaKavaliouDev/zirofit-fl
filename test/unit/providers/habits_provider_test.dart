import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/habits/providers/habits_provider.dart';
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

  group('HabitsNotifier', () {
    test('initial state is correct', () {
      final state = container.read(habitsProvider);
      expect(state.habits, isEmpty);
      expect(state.isLoading, false);
      expect(state.isSaving, false);
      expect(state.error, isNull);
    });

    test('fetchHabits loads habits on success', () async {
      final habitsJson = [
        {
          'id': 'habit-1',
          'client_id': 'client-1',
          'trainer_id': 'trainer-1',
          'title': 'Drink 8 glasses of water',
          'description': 'Stay hydrated throughout the day',
          'frequency': 'DAILY',
          'is_active': true,
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
        {
          'id': 'habit-2',
          'client_id': 'client-1',
          'trainer_id': 'trainer-1',
          'title': 'Walk 10,000 steps',
          'frequency': 'DAILY',
          'is_active': true,
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientHabits,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': habitsJson,
          });

      await container.read(habitsProvider.notifier).fetchHabits();

      final state = container.read(habitsProvider);
      expect(state.habits, hasLength(2));
      expect(state.habits[0].title, 'Drink 8 glasses of water');
      expect(state.habits[1].title, 'Walk 10,000 steps');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchHabits sets error on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.clientHabits,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.clientHabits),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.clientHabits),
            statusCode: 500,
            data: {'message': 'Server error'},
          ),
        ),
      );

      await container.read(habitsProvider.notifier).fetchHabits();

      final state = container.read(habitsProvider);
      expect(state.habits, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('logHabit sends POST and updates isSaving state', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.logHabit('habit-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => {
            'data': {'message': 'Logged'},
          });

      final notifier = container.read(habitsProvider.notifier);

      // Start saving
      expect(container.read(habitsProvider).isSaving, false);

      await notifier.logHabit(
        'habit-1',
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
        true,
      );

      final state = container.read(habitsProvider);
      expect(state.isSaving, false);
      expect(state.error, isNull);
    });

    test('logHabit sets error on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.logHabit('habit-1'),
            body: any(named: 'body'),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.logHabit('habit-1')),
          type: DioExceptionType.badResponse,
        ),
      );

      final notifier = container.read(habitsProvider.notifier);

      await notifier.logHabit(
        'habit-1',
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
        true,
      );

      final state = container.read(habitsProvider);
      expect(state.isSaving, false);
      expect(state.error, isNotNull);
    });

    test('logHabit includes optional note in request body', () async {
      final capturedBody = <dynamic>[];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
            ApiConstants.logHabit('habit-1'),
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        capturedBody.add(invocation.namedArguments[#body]);
        return {'data': {'message': 'Logged'}};
      });

      await container.read(habitsProvider.notifier).logHabit(
            'habit-1',
            DateTime.fromMillisecondsSinceEpoch(1700000000000),
            true,
            note: 'Feeling great!',
          );

      expect(capturedBody, isNotEmpty);
      final body = capturedBody.first as Map<String, dynamic>;
      expect(body['isCompleted'], true);
      expect(body['note'], 'Feeling great!');
      expect(body['date'], '2023-11-14');
    });
  });
}
