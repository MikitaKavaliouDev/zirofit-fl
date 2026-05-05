import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/habits/providers/habits_provider.dart';
import '../helpers/provider_utils.dart';
import '../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures — snake_case keys matching backend wire format
// ---------------------------------------------------------------------------

const _ts = 1704067200000;

Map<String, dynamic> _habitJson({
  String id = 'habit-1',
  String title = 'Drink 8 glasses of water',
  String? description,
}) => {
      'id': id,
      'client_id': 'client-1',
      'trainer_id': 'trainer-1',
      'title': title,
      'description': description ?? 'Stay hydrated throughout the day',
      'frequency': 'DAILY',
      'is_active': true,
      'created_at': _ts,
      'updated_at': _ts,
    };

Map<String, dynamic> _responseWithData(List<Map<String, dynamic>> items) =>
    <String, dynamic>{'data': items};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      habitsProvider.overrideWith(
        (ref) => HabitsNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() => container.dispose());

  group('HabitsNotifier', () {
    test('initial state has empty habits and is not loading', () {
      final state = container.read(habitsProvider);
      expect(state.habits, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isSaving, isFalse);
      expect(state.error, isNull);
    });

    test('fetchHabits populates the habit list', () async {
      final habitsJson = [
        _habitJson(id: 'habit-1', title: 'Drink water'),
        _habitJson(id: 'habit-2', title: 'Walk 10k steps'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientHabits,
          )).thenAnswer((_) async => _responseWithData(habitsJson));

      await container.read(habitsProvider.notifier).fetchHabits();

      final state = container.read(habitsProvider);
      expect(state.habits, hasLength(2));
      expect(state.habits[0].id, 'habit-1');
      expect(state.habits[0].title, 'Drink water');
      expect(state.habits[1].title, 'Walk 10k steps');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchHabits handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientHabits,
          )).thenAnswer((_) async => _responseWithData([]));

      await container.read(habitsProvider.notifier).fetchHabits();

      final state = container.read(habitsProvider);
      expect(state.habits, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchHabits sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientHabits,
          )).thenThrow(Exception('API error'));

      await container.read(habitsProvider.notifier).fetchHabits();

      final state = container.read(habitsProvider);
      expect(state.habits, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('logHabit sends POST and clears isSaving on success', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.logHabit('habit-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'log': {'id': 'log-1', 'habit_id': 'habit-1'}},
          });

      await container.read(habitsProvider.notifier).logHabit(
            'habit-1',
            DateTime.fromMillisecondsSinceEpoch(_ts),
            true,
          );

      final state = container.read(habitsProvider);
      expect(state.isSaving, isFalse);
      expect(state.error, isNull);
    });

    test('logHabit sets error on API failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.logHabit('habit-1'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Log failed'));

      await container.read(habitsProvider.notifier).logHabit(
            'habit-1',
            DateTime.fromMillisecondsSinceEpoch(_ts),
            true,
          );

      final state = container.read(habitsProvider);
      expect(state.isSaving, isFalse);
      expect(state.error, isNotNull);
    });
  });
}
