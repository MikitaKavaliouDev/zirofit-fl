import 'package:zirofit_fl/core/utils/json_helpers.dart';

// ---------------------------------------------------------------------------
// VolumePoint
// ---------------------------------------------------------------------------

class VolumePoint {
  final String date;
  final double volume;

  const VolumePoint({
    required this.date,
    required this.volume,
  });

  factory VolumePoint.fromJson(Map<String, dynamic> json) => VolumePoint(
        date: json['date'] as String,
        volume: (json['volume'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'volume': volume,
      };

  @override
  String toString() => 'VolumePoint(date: $date, volume: $volume)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolumePoint && date == other.date && volume == other.volume;

  @override
  int get hashCode => Object.hash(date, volume);
}

// ---------------------------------------------------------------------------
// MusclePoint
// ---------------------------------------------------------------------------

class MusclePoint {
  final String muscle;
  final int count;

  const MusclePoint({
    required this.muscle,
    required this.count,
  });

  factory MusclePoint.fromJson(Map<String, dynamic> json) => MusclePoint(
        muscle: json['muscle'] as String,
        count: json['count'] as int,
      );

  Map<String, dynamic> toJson() => {
        'muscle': muscle,
        'count': count,
      };

  @override
  String toString() => 'MusclePoint(muscle: $muscle, count: $count)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusclePoint && muscle == other.muscle && count == other.count;

  @override
  int get hashCode => Object.hash(muscle, count);
}

// ---------------------------------------------------------------------------
// PersonalRecord (lightweight analytics DTO)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// AnalyticsPersonalRecord (lightweight DTO for analytics recent PRs)
// ---------------------------------------------------------------------------

class AnalyticsPersonalRecord {
  final String exercise;
  final double value;
  final String type;
  final DateTime date;

  const AnalyticsPersonalRecord({
    required this.exercise,
    required this.value,
    required this.type,
    required this.date,
  });

  factory AnalyticsPersonalRecord.fromJson(Map<String, dynamic> json) {
    return AnalyticsPersonalRecord(
      exercise: json['exercise'] as String,
      value: (json['value'] as num).toDouble(),
      type: json['type'] as String,
      date: readDateTime(json, 'date', 'date'),
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'value': value,
        'type': type,
        'date': dateTimeToJson(date),
      };

  @override
  String toString() =>
      'AnalyticsPersonalRecord(exercise: $exercise, value: $value, '
      'type: $type, date: $date)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsPersonalRecord &&
          exercise == other.exercise &&
          value == other.value &&
          type == other.type &&
          date == other.date;

  @override
  int get hashCode => Object.hash(exercise, value, type, date);
}

// ---------------------------------------------------------------------------
// MetricPoint
// ---------------------------------------------------------------------------

class MetricPoint {
  final DateTime date;
  final double value;

  const MetricPoint({
    required this.date,
    required this.value,
  });

  factory MetricPoint.fromJson(Map<String, dynamic> json) => MetricPoint(
        date: readDateTime(json, 'date', 'date'),
        value: (json['value'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'date': dateTimeToJson(date),
        'value': value,
      };

  @override
  String toString() => 'MetricPoint(date: $date, value: $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetricPoint && date == other.date && value == other.value;

  @override
  int get hashCode => Object.hash(date, value);
}

// ---------------------------------------------------------------------------
// ExercisePerformance
// ---------------------------------------------------------------------------

class ExercisePerformance {
  final String exercise;
  final double? averageWeight;
  final double? averageReps;
  final double? maxWeight;
  final int? totalSets;
  final double? progress;

  const ExercisePerformance({
    required this.exercise,
    this.averageWeight,
    this.averageReps,
    this.maxWeight,
    this.totalSets,
    this.progress,
  });

  factory ExercisePerformance.fromJson(Map<String, dynamic> json) =>
      ExercisePerformance(
        exercise: json['exercise'] as String,
        averageWeight: (json['average_weight'] as num?)?.toDouble(),
        averageReps: (json['average_reps'] as num?)?.toDouble(),
        maxWeight: (json['max_weight'] as num?)?.toDouble(),
        totalSets: json['total_sets'] as int?,
        progress: (json['progress'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'average_weight': averageWeight,
        'average_reps': averageReps,
        'max_weight': maxWeight,
        'total_sets': totalSets,
        'progress': progress,
      };

  @override
  String toString() =>
      'ExercisePerformance(exercise: $exercise, averageWeight: $averageWeight, '
      'averageReps: $averageReps, maxWeight: $maxWeight, '
      'totalSets: $totalSets, progress: $progress)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExercisePerformance &&
          exercise == other.exercise &&
          averageWeight == other.averageWeight &&
          averageReps == other.averageReps &&
          maxWeight == other.maxWeight &&
          totalSets == other.totalSets &&
          progress == other.progress;

  @override
  int get hashCode => Object.hash(
        exercise,
        averageWeight,
        averageReps,
        maxWeight,
        totalSets,
        progress,
      );
}

// ---------------------------------------------------------------------------
// FavoriteExercise
// ---------------------------------------------------------------------------

class FavoriteExercise {
  final String exercise;
  final int count;

  const FavoriteExercise({
    required this.exercise,
    required this.count,
  });

  factory FavoriteExercise.fromJson(Map<String, dynamic> json) =>
      FavoriteExercise(
        exercise: json['exercise'] as String,
        count: json['count'] as int,
      );

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'count': count,
      };

  @override
  String toString() => 'FavoriteExercise(exercise: $exercise, count: $count)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteExercise &&
          exercise == other.exercise &&
          count == other.count;

  @override
  int get hashCode => Object.hash(exercise, count);
}

// ---------------------------------------------------------------------------
// WorstExercise
// ---------------------------------------------------------------------------

class WorstExercise {
  final String exercise;
  final double? averageWeight;
  final double? averageReps;

  const WorstExercise({
    required this.exercise,
    this.averageWeight,
    this.averageReps,
  });

  factory WorstExercise.fromJson(Map<String, dynamic> json) => WorstExercise(
        exercise: json['exercise'] as String,
        averageWeight: (json['average_weight'] as num?)?.toDouble(),
        averageReps: (json['average_reps'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'average_weight': averageWeight,
        'average_reps': averageReps,
      };

  @override
  String toString() =>
      'WorstExercise(exercise: $exercise, averageWeight: $averageWeight, '
      'averageReps: $averageReps)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorstExercise &&
          exercise == other.exercise &&
          averageWeight == other.averageWeight &&
          averageReps == other.averageReps;

  @override
  int get hashCode => Object.hash(exercise, averageWeight, averageReps);
}

// ---------------------------------------------------------------------------
// ClientAnalytics
// ---------------------------------------------------------------------------

class ClientAnalytics {
  final List<String> heatmapDates;
  final List<VolumePoint> volumeHistory;
  final List<MusclePoint> muscleDistribution;
  final List<AnalyticsPersonalRecord> recentPRs;
  final int consistency;

  const ClientAnalytics({
    required this.heatmapDates,
    required this.volumeHistory,
    required this.muscleDistribution,
    required this.recentPRs,
    required this.consistency,
  });

  factory ClientAnalytics.fromJson(Map<String, dynamic> json) =>
      ClientAnalytics(
        heatmapDates: (json['heatmapDates'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        volumeHistory: (json['volumeHistory'] as List<dynamic>?)
                ?.map((e) =>
                    VolumePoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        muscleDistribution: (json['muscleDistribution'] as List<dynamic>?)
                ?.map((e) =>
                    MusclePoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        recentPRs: (json['recentPRs'] as List<dynamic>?)
                ?.map((e) =>
                    AnalyticsPersonalRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        consistency: json['consistency'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'heatmapDates': heatmapDates,
        'volumeHistory': volumeHistory.map((e) => e.toJson()).toList(),
        'muscleDistribution':
            muscleDistribution.map((e) => e.toJson()).toList(),
        'recentPRs': recentPRs.map((e) => e.toJson()).toList(),
        'consistency': consistency,
      };

  @override
  String toString() =>
      'ClientAnalytics(heatmapDates: ${heatmapDates.length} dates, '
      'volumeHistory: ${volumeHistory.length} entries, '
      'muscleDistribution: ${muscleDistribution.length} entries, '
      'recentPRs: ${recentPRs.length} records, '
      'consistency: $consistency)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientAnalytics &&
          heatmapDates.length == other.heatmapDates.length &&
          volumeHistory.length == other.volumeHistory.length &&
          muscleDistribution.length == other.muscleDistribution.length &&
          recentPRs.length == other.recentPRs.length &&
          consistency == other.consistency;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(heatmapDates),
        Object.hashAll(volumeHistory),
        Object.hashAll(muscleDistribution),
        Object.hashAll(recentPRs),
        consistency,
      );
}

// ---------------------------------------------------------------------------
// ClientProgress
// ---------------------------------------------------------------------------

class ClientProgress {
  final List<MetricPoint> weight;
  final List<MetricPoint> bodyFat;
  final List<VolumePoint> volume;
  final List<ExercisePerformance> exercisePerformance;
  final List<FavoriteExercise> favoriteExercises;
  final List<WorstExercise> worstPerformingExercises;

  const ClientProgress({
    required this.weight,
    required this.bodyFat,
    required this.volume,
    required this.exercisePerformance,
    required this.favoriteExercises,
    required this.worstPerformingExercises,
  });

  factory ClientProgress.fromJson(Map<String, dynamic> json) =>
      ClientProgress(
        weight: (json['weight'] as List<dynamic>?)
                ?.map(
                    (e) => MetricPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        bodyFat: (json['bodyFat'] as List<dynamic>?)
                ?.map(
                    (e) => MetricPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        volume: (json['volume'] as List<dynamic>?)
                ?.map(
                    (e) => VolumePoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        exercisePerformance: (json['exercisePerformance'] as List<dynamic>?)
                ?.map((e) =>
                    ExercisePerformance.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        favoriteExercises: (json['favoriteExercises'] as List<dynamic>?)
                ?.map((e) =>
                    FavoriteExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        worstPerformingExercises:
            (json['worstPerformingExercises'] as List<dynamic>?)
                    ?.map((e) =>
                        WorstExercise.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [],
      );

  Map<String, dynamic> toJson() => {
        'weight': weight.map((e) => e.toJson()).toList(),
        'bodyFat': bodyFat.map((e) => e.toJson()).toList(),
        'volume': volume.map((e) => e.toJson()).toList(),
        'exercisePerformance':
            exercisePerformance.map((e) => e.toJson()).toList(),
        'favoriteExercises':
            favoriteExercises.map((e) => e.toJson()).toList(),
        'worstPerformingExercises':
            worstPerformingExercises.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() =>
      'ClientProgress(weight: ${weight.length} entries, '
      'bodyFat: ${bodyFat.length} entries, '
      'volume: ${volume.length} entries, '
      'exercisePerformance: ${exercisePerformance.length} entries, '
      'favoriteExercises: ${favoriteExercises.length} entries, '
      'worstPerformingExercises: ${worstPerformingExercises.length} entries)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientProgress &&
          weight.length == other.weight.length &&
          bodyFat.length == other.bodyFat.length &&
          volume.length == other.volume.length &&
          exercisePerformance.length == other.exercisePerformance.length &&
          favoriteExercises.length == other.favoriteExercises.length &&
          worstPerformingExercises.length ==
              other.worstPerformingExercises.length;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(weight),
        Object.hashAll(bodyFat),
        Object.hashAll(volume),
        Object.hashAll(exercisePerformance),
        Object.hashAll(favoriteExercises),
        Object.hashAll(worstPerformingExercises),
      );
}
