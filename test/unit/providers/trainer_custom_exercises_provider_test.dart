import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/data/sync/sync_engine.dart';
import 'package:zirofit_fl/features/trainer/providers/custom_exercises_provider.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late MockApiClient mockApiClient;
  late TrainerCustomExercisesNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    final mockSyncEngine = MockSyncEngine();
    notifier = TrainerCustomExercisesNotifier(apiClient: mockApiClient, syncEngine: mockSyncEngine);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Exercise createExercise({
    String id = 'ex-1',
    String name = 'Bench Press',
    String? muscleGroup = 'Chest',
    String? equipment = 'Barbell',
    String? description,
    String? videoUrl,
  }) =>
      Exercise(
        id: id,
        name: name,
        muscleGroup: muscleGroup,
        equipment: equipment,
        description: description,
        videoUrl: videoUrl,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

  List<Exercise> createExercises() => [
        createExercise(
          id: 'ex-1',
          name: 'Bench Press',
          muscleGroup: 'Chest',
          equipment: 'Barbell',
        ),
        createExercise(
          id: 'ex-2',
          name: 'Squat',
          muscleGroup: 'Legs',
          equipment: 'Barbell',
          description: 'Full range of motion',
          videoUrl: 'https://youtube.com/watch?v=abc',
        ),
      ];

  group('TrainerCustomExercisesNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('Test 1: fetchExercises populates list', () async {
      final exercises = createExercises();

      when(() => mockApiClient.get<List<Exercise>>(
            ApiConstants.trainerCustomExercises,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => exercises);

      await notifier.fetchExercises();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.exercises.length, 2);
      expect(notifier.state.exercises[0].name, 'Bench Press');
      expect(notifier.state.exercises[1].name, 'Squat');
    });

    // ---------------------------------------------------------------------------
    // Create exercise
    // ---------------------------------------------------------------------------
    test('Test 2: createExercise adds exercise', () async {
      final newExercise = createExercise(
        id: 'ex-3',
        name: 'Deadlift',
        muscleGroup: 'Back',
        equipment: 'Barbell',
      );

      final data = {
        'name': 'Deadlift',
        'muscleGroup': 'Back',
        'equipment': 'Barbell',
      };

      when(() => mockApiClient.post<Exercise>(
            ApiConstants.trainerCustomExercises,
            body: data,
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => newExercise);

      await notifier.createExercise(data);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.exercises.length, 1);
      expect(notifier.state.exercises[0].name, 'Deadlift');
    });

    // ---------------------------------------------------------------------------
    // Update exercise
    // ---------------------------------------------------------------------------
    test('Test 3: updateExercise modifies exercise', () async {
      // Start with one exercise in state
      final initialExercise = createExercise(
        id: 'ex-1',
        name: 'Old Name',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
      );

      when(() => mockApiClient.post<Exercise>(
            ApiConstants.trainerCustomExercises,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => initialExercise);

      await notifier
          .createExercise({'name': 'Old Name', 'muscleGroup': 'Chest', 'equipment': 'Barbell'});

      // Now update it
      final updatedExercise = createExercise(
        id: 'ex-1',
        name: 'Updated Name',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
      );

      final updateData = {
        'name': 'Updated Name',
        'muscleGroup': 'Shoulders',
        'equipment': 'Dumbbell',
      };

      when(() => mockApiClient.put<Exercise>(
            '${ApiConstants.trainerCustomExercises}/ex-1',
            body: updateData,
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => updatedExercise);

      await notifier.updateExercise('ex-1', updateData);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.exercises.length, 1);
      expect(notifier.state.exercises[0].name, 'Updated Name');
      expect(notifier.state.exercises[0].muscleGroup, 'Shoulders');
      expect(notifier.state.exercises[0].equipment, 'Dumbbell');
    });

    // ---------------------------------------------------------------------------
    // Delete exercise
    // ---------------------------------------------------------------------------
    test('Test 4: deleteExercise removes exercise', () async {
      // Start with two exercises
      final exercises = createExercises();

      when(() => mockApiClient.get<List<Exercise>>(
            ApiConstants.trainerCustomExercises,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => exercises);

      await notifier.fetchExercises();
      expect(notifier.state.exercises.length, 2);

      // Delete one
      when(() => mockApiClient.delete(
            '${ApiConstants.trainerCustomExercises}/ex-1',
          )).thenAnswer((_) async => {});

      await notifier.deleteExercise('ex-1');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.exercises.length, 1);
      expect(notifier.state.exercises[0].id, 'ex-2');
    });

    // ---------------------------------------------------------------------------
    // Error states
    // ---------------------------------------------------------------------------
    test('Test 5: error states are handled', () async {
      when(() => mockApiClient.get<List<Exercise>>(
            ApiConstants.trainerCustomExercises,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Network failure'));

      await notifier.fetchExercises();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.exercises, isEmpty);
    });
  });
}
