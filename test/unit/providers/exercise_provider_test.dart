import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/data/models/api_response.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/data/exercise_remote_source.dart';
import 'package:zirofit_fl/features/exercises/providers/exercise_provider.dart';

class MockExerciseRemoteSource extends Mock implements ExerciseRemoteSource {}

void main() {
  late MockExerciseRemoteSource mockRemoteSource;
  late ExerciseListNotifier notifier;

  setUp(() {
    mockRemoteSource = MockExerciseRemoteSource();
    notifier = ExerciseListNotifier(mockRemoteSource);
  });

  group('ExerciseListNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has empty exercises, initial status, and empty search', () {
      expect(notifier.state.exercises, isEmpty);
      expect(notifier.state.status, ExerciseListStatus.initial);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.search, '');
      expect(notifier.state.hasMore, true);
      expect(notifier.state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchExercises – success
    // ---------------------------------------------------------------------------
    test('fetchExercises populates list on success', () async {
      final exercises = [
        Exercise(
          id: '1',
          name: 'Bench Press',
          muscleGroup: 'Chest',
          category: 'Strength',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        Exercise(
          id: '2',
          name: 'Squat',
          muscleGroup: 'Legs',
          category: 'Strength',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      when(() => mockRemoteSource.searchExercises(
            search: any(named: 'search'),
            category: any(named: 'category'),
            muscleGroup: any(named: 'muscleGroup'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => ApiResponse(data: exercises));

      await notifier.fetchExercises();

      expect(notifier.state.status, ExerciseListStatus.loaded);
      expect(notifier.state.exercises, exercises);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.page, 1);
    });

    // ---------------------------------------------------------------------------
    // fetchExercises – failure
    // ---------------------------------------------------------------------------
    test('fetchExercises sets error on failure', () async {
      when(() => mockRemoteSource.searchExercises(
            search: any(named: 'search'),
            category: any(named: 'category'),
            muscleGroup: any(named: 'muscleGroup'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const ApiResponse<List<Exercise>>(
                errorMessage: 'Failed to load exercises',
              ));

      await notifier.fetchExercises();

      expect(notifier.state.status, ExerciseListStatus.error);
      expect(notifier.state.error, 'Failed to load exercises');
    });

    // ---------------------------------------------------------------------------
    // fetchExercises – exception
    // ---------------------------------------------------------------------------
    test('fetchExercises sets error on exception', () async {
      when(() => mockRemoteSource.searchExercises(
            search: any(named: 'search'),
            category: any(named: 'category'),
            muscleGroup: any(named: 'muscleGroup'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenThrow(Exception('Network error'));

      await notifier.fetchExercises();

      expect(notifier.state.status, ExerciseListStatus.error);
      expect(notifier.state.error, contains('Network error'));
    });

    // ---------------------------------------------------------------------------
    // fetchExercises with search query
    // ---------------------------------------------------------------------------
    test('fetchExercises with search updates query and returns filtered results',
        () async {
      final filtered = [
        Exercise(
          id: '3',
          name: 'Squat',
          muscleGroup: 'Legs',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      when(() => mockRemoteSource.searchExercises(
            search: any(named: 'search'),
            category: any(named: 'category'),
            muscleGroup: any(named: 'muscleGroup'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((invocation) async {
        final search = invocation.namedArguments[#search] as String?;
        if (search == 'squat') {
          return ApiResponse(data: filtered);
        }
        return const ApiResponse(data: <Exercise>[]);
      });

      await notifier.fetchExercises(search: 'squat');

      expect(notifier.state.search, 'squat');
      expect(notifier.state.exercises, filtered);
      expect(notifier.state.status, ExerciseListStatus.loaded);
    });

    // ---------------------------------------------------------------------------
    // loadMore – appends when hasMore
    // ---------------------------------------------------------------------------
    test('loadMore appends exercises when hasMore is true', () async {
      final page1 = List.generate(
        50,
        (i) => Exercise(
          id: 'ex_$i',
          name: 'Exercise $i',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      );
      final page2 = List.generate(
        25,
        (i) => Exercise(
          id: 'ex_${i + 50}',
          name: 'Exercise ${i + 50}',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      );

      when(() => mockRemoteSource.searchExercises(
            search: any(named: 'search'),
            category: any(named: 'category'),
            muscleGroup: any(named: 'muscleGroup'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#page] as int? ?? 1;
        if (page == 1) return ApiResponse(data: page1);
        return ApiResponse(data: page2);
      });

      await notifier.fetchExercises();
      expect(notifier.state.exercises.length, 50);
      // hasMore should be true because page1 has >= 50 items
      expect(notifier.state.hasMore, true);

      await notifier.loadMore();
      expect(notifier.state.exercises.length, 75);
      expect(notifier.state.status, ExerciseListStatus.loaded);
      expect(notifier.state.page, 2);
    });

    // ---------------------------------------------------------------------------
    // loadMore – does nothing when hasMore is false
    // ---------------------------------------------------------------------------
    test('loadMore does nothing when hasMore is false', () async {
      final exercises = List.generate(
        25,
        (i) => Exercise(
          id: 'ex_$i',
          name: 'Exercise $i',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      );

      when(() => mockRemoteSource.searchExercises(
            search: any(named: 'search'),
            category: any(named: 'category'),
            muscleGroup: any(named: 'muscleGroup'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => ApiResponse(data: exercises));

      await notifier.fetchExercises();
      // hasMore is false because fetched < 50 items
      expect(notifier.state.hasMore, false);

      await notifier.loadMore();
      // list stays unchanged
      expect(notifier.state.exercises.length, 25);
    });

    // ---------------------------------------------------------------------------
    // loadMore – no-op when already loadingMore
    // ---------------------------------------------------------------------------
    test('loadMore does nothing when already loadingMore', () async {
      final page1 = List.generate(
        50,
        (i) => Exercise(
          id: 'ex_$i',
          name: 'Exercise $i',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      );

      when(() => mockRemoteSource.searchExercises(
            search: any(named: 'search'),
            category: any(named: 'category'),
            muscleGroup: any(named: 'muscleGroup'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async {
        // Simulate slow network
        await Future.delayed(const Duration(milliseconds: 50));
        return ApiResponse(data: page1);
      });

      await notifier.fetchExercises();

      // Start first loadMore
      final firstLoad = notifier.loadMore();
      // Try a second loadMore while first is in-flight
      notifier.loadMore(); // should be ignored

      await firstLoad;

      // Only one page load happened
      verify(() => mockRemoteSource.searchExercises(
            search: any(named: 'search'),
            category: any(named: 'category'),
            muscleGroup: any(named: 'muscleGroup'),
            page: 2,
            limit: any(named: 'limit'),
          )).called(1);
    });
  });
}
