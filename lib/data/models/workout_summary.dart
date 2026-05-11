import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/new_record.dart';

/// Summary data for a completed workout
class WorkoutSummaryData {
  final String sessionId;
  final String sessionName;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double totalVolume;
  final int totalSets;
  final int exercisesCompleted;
  final int caloriesBurned;
  final List<ExerciseSummary> exercises;
  final List<NewRecord> newRecords;
  final BestSetSummary? bestSet;

  const WorkoutSummaryData({
    required this.sessionId,
    required this.sessionName,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.totalVolume,
    required this.totalSets,
    required this.exercisesCompleted,
    required this.caloriesBurned,
    required this.exercises,
    required this.newRecords,
    this.bestSet,
  });

  factory WorkoutSummaryData.fromJson(Map<String, dynamic> json) => WorkoutSummaryData(
        sessionId: json['session_id'] as String? ?? json['sessionId'] as String? ?? '',
        sessionName: json['session_name'] as String? ?? json['sessionName'] as String? ?? 'Workout',
        startTime: readDateTimeOrNull(json, 'start_time', 'startTime') ?? DateTime.now(),
        endTime: readDateTimeOrNull(json, 'end_time', 'endTime') ?? DateTime.now(),
        durationSeconds: json['duration_seconds'] as int? ?? json['durationSeconds'] as int? ?? 0,
        totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
        totalSets: json['total_sets'] as int? ?? json['totalSets'] as int? ?? 0,
        exercisesCompleted: json['exercises_completed'] as int? ?? json['exercisesCompleted'] as int? ?? 0,
        caloriesBurned: json['calories_burned'] as int? ?? json['caloriesBurned'] as int? ?? 0,
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) => ExerciseSummary.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        newRecords: (json['new_records'] as List<dynamic>?)
                ?.map((e) => NewRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        bestSet: json['best_set'] != null
            ? BestSetSummary.fromJson(json['best_set'] as Map<String, dynamic>)
            : null,
      );

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedVolume => '${totalVolume.toStringAsFixed(0)} kg';
}

/// Summary for a single exercise in a workout
class ExerciseSummary {
  final String exerciseId;
  final String exerciseName;
  final int setsCompleted;
  final int totalReps;
  final double totalVolume;
  final double? bestWeight;

  const ExerciseSummary({
    required this.exerciseId,
    required this.exerciseName,
    required this.setsCompleted,
    required this.totalReps,
    required this.totalVolume,
    this.bestWeight,
  });

  factory ExerciseSummary.fromJson(Map<String, dynamic> json) => ExerciseSummary(
        exerciseId: json['exercise_id'] as String? ?? json['exerciseId'] as String? ?? '',
        exerciseName: json['exercise_name'] as String? ?? json['exerciseName'] as String? ?? 'Exercise',
        setsCompleted: json['sets_completed'] as int? ?? json['setsCompleted'] as int? ?? 0,
        totalReps: json['total_reps'] as int? ?? json['totalReps'] as int? ?? 0,
        totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
        bestWeight: (json['best_weight'] as num?)?.toDouble(),
      );
}

/// Best set during a workout
class BestSetSummary {
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;

  const BestSetSummary({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
  });

  factory BestSetSummary.fromJson(Map<String, dynamic> json) => BestSetSummary(
        exerciseId: json['exercise_id'] as String? ?? json['exerciseId'] as String? ?? '',
        exerciseName: json['exercise_name'] as String? ?? json['exerciseName'] as String? ?? 'Exercise',
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        reps: json['reps'] as int? ?? json['reps'] as int? ?? 0,
      );

  String get formatted => '${weight.toStringAsFixed(1)} kg × $reps reps';
}

/// API response for workout summary
class WorkoutSummaryResponse {
  final WorkoutSummaryData session;
  final int totalWorkouts;
  final int newRecordsCount;

  const WorkoutSummaryResponse({
    required this.session,
    required this.totalWorkouts,
    required this.newRecordsCount,
  });

  factory WorkoutSummaryResponse.fromJson(Map<String, dynamic> json) => WorkoutSummaryResponse(
        session: WorkoutSummaryData.fromJson(json['session'] as Map<String, dynamic>? ?? json),
        totalWorkouts: json['total_workouts'] as int? ?? json['totalWorkouts'] as int? ?? 0,
        newRecordsCount: json['new_records_count'] as int? ?? json['newRecordsCount'] as int? ?? 0,
      );
}