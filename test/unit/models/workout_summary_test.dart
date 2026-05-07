import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/workout_summary.dart';
import 'package:zirofit_fl/data/models/new_record.dart';

void main() {
  group('WorkoutSummaryData', () {
    final baseJson = <String, dynamic>{
      'session_id': 'sess-1',
      'session_name': 'Morning Workout',
      'start_time': 1700000000000,
      'end_time': 1700003600000,
      'duration_seconds': 3600,
      'total_volume': 12000.0,
      'total_sets': 12,
      'exercises_completed': 5,
      'calories_burned': 350,
      'exercises': [],
      'new_records': [
        {
          'record_type': 'weight',
          'exercise_id': 'ex-1',
          'exercise_name': 'Bench Press',
          'new_record': 105.0,
        }
      ],
      'best_set': {
        'exercise_id': 'ex-1',
        'exercise_name': 'Bench Press',
        'weight': 105.0,
        'reps': 8,
      },
    };

    test('fromJson parses all fields correctly', () {
      final summary = WorkoutSummaryData.fromJson(baseJson);

      expect(summary.sessionId, 'sess-1');
      expect(summary.sessionName, 'Morning Workout');
      expect(summary.durationSeconds, 3600);
      expect(summary.totalVolume, 12000.0);
      expect(summary.totalSets, 12);
      expect(summary.exercisesCompleted, 5);
      expect(summary.caloriesBurned, 350);
    });

    test('formattedDuration returns hours and minutes', () {
      final summary = WorkoutSummaryData.fromJson(baseJson);
      expect(summary.formattedDuration, '1h 0m');
    });

    test('formattedDuration returns minutes for short workouts', () {
      final shortJson = {...baseJson, 'duration_seconds': 2700};
      final summary = WorkoutSummaryData.fromJson(shortJson);
      expect(summary.formattedDuration, '45m 0s');
    });

    test('formattedVolume returns correct format', () {
      final summary = WorkoutSummaryData.fromJson(baseJson);
      expect(summary.formattedVolume, '12000 kg');
    });
  });

  group('ExerciseSummary', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'exercise_id': 'ex-1',
        'exercise_name': 'Squat',
        'sets_completed': 5,
        'total_reps': 40,
        'total_volume': 4000.0,
        'best_weight': 100.0,
      };

      final exercise = ExerciseSummary.fromJson(json);

      expect(exercise.exerciseId, 'ex-1');
      expect(exercise.exerciseName, 'Squat');
      expect(exercise.setsCompleted, 5);
      expect(exercise.totalReps, 40);
      expect(exercise.totalVolume, 4000.0);
      expect(exercise.bestWeight, 100.0);
    });
  });

  group('BestSetSummary', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'exercise_id': 'ex-1',
        'exercise_name': 'Deadlift',
        'weight': 150.0,
        'reps': 5,
      };

      final best = BestSetSummary.fromJson(json);

      expect(best.exerciseId, 'ex-1');
      expect(best.exerciseName, 'Deadlift');
      expect(best.weight, 150.0);
      expect(best.reps, 5);
    });

    test('formatted returns correct string', () {
      final best = BestSetSummary(
        exerciseId: 'ex-1',
        exerciseName: 'Deadlift',
        weight: 150.0,
        reps: 5,
      );

      expect(best.formatted, '150.0 kg × 5 reps');
    });
  });

  group('WorkoutSummaryResponse', () {
    test('fromJson parses session and counts', () {
      final json = <String, dynamic>{
        'session': {
          'session_id': 'sess-1',
          'duration_seconds': 3600,
        },
        'total_workouts': 50,
        'new_records_count': 3,
      };

      final response = WorkoutSummaryResponse.fromJson(json);

      expect(response.session.sessionId, 'sess-1');
      expect(response.totalWorkouts, 50);
      expect(response.newRecordsCount, 3);
    });

    test('fromJson handles flat response', () {
      final json = <String, dynamic>{
        'session_id': 'sess-1',
        'duration_seconds': 3600,
        'total_workouts': 50,
        'new_records_count': 3,
      };

      final response = WorkoutSummaryResponse.fromJson(json);

      expect(response.session.sessionId, 'sess-1');
      expect(response.totalWorkouts, 50);
    });
  });
}