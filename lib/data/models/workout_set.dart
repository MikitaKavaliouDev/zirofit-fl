import 'package:zirofit_fl/core/utils/json_helpers.dart';

/// Status of a workout set within an exercise log
enum SetStatus {
  normal,
  warmUp,
  dropSet,
  failure;

  static SetStatus fromJson(String? json) {
    if (json == null) return SetStatus.normal;
    switch (json.toUpperCase()) {
      case 'WARM_UP':
      case 'WARMUP':
        return SetStatus.warmUp;
      case 'DROP_SET':
      case 'DROPSET':
        return SetStatus.dropSet;
      case 'FAILURE':
        return SetStatus.failure;
      default:
        return SetStatus.normal;
    }
  }

  String toJson() => name;
}

/// Focus metric for tracking personal records
enum FocusMetric {
  none,
  volume,
  maxWeight,
  maxReps;

  static FocusMetric fromJson(String? json) {
    if (json == null) return FocusMetric.none;
    switch (json.toUpperCase()) {
      case 'VOLUME':
        return FocusMetric.volume;
      case 'MAX_WEIGHT':
      case 'MAXWEIGHT':
        return FocusMetric.maxWeight;
      case 'MAX_REPS':
      case 'MAXREPS':
        return FocusMetric.maxReps;
      default:
        return FocusMetric.none;
    }
  }

  String toJson() => name;
}

/// Individual set within an exercise log
class WorkoutSet {
  final String id;
  final String logId;
  final int? reps;
  final double? weight;
  final double? rpe;
  final bool isCompleted;
  final SetStatus status;
  final int? restDuration;
  final FocusMetric focusMetric;
  final DateTime? completedAt;

  const WorkoutSet({
    required this.id,
    required this.logId,
    this.reps,
    this.weight,
    this.rpe,
    this.isCompleted = false,
    this.status = SetStatus.normal,
    this.restDuration,
    this.focusMetric = FocusMetric.none,
    this.completedAt,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        id: json['id'] as String? ?? json['exerciseId'] as String? ?? '',
        logId: json['log_id'] as String? ?? json['logId'] as String? ?? '',
        reps: json['reps'] as int?,
        weight: (json['weight'] as num?)?.toDouble(),
        rpe: (json['rpe'] as num?)?.toDouble(),
        isCompleted: json['is_completed'] as bool? ?? json['isCompleted'] as bool? ?? false,
        status: SetStatus.fromJson(json['status'] as String?),
        restDuration: json['rest_duration'] as int? ?? json['restDuration'] as int?,
        focusMetric: FocusMetric.fromJson(json['focus_metric'] as String?),
        completedAt: readDateTimeOrNull(json, 'completed_at', 'completedAt'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'log_id': logId,
        if (reps != null) 'reps': reps,
        if (weight != null) 'weight': weight,
        if (rpe != null) 'rpe': rpe,
        'is_completed': isCompleted,
        'status': status.toJson(),
        if (restDuration != null) 'rest_duration': restDuration,
        'focus_metric': focusMetric.toJson(),
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      };

  WorkoutSet copyWith({
    String? id,
    String? logId,
    int? reps,
    double? weight,
    double? rpe,
    bool? isCompleted,
    SetStatus? status,
    int? restDuration,
    FocusMetric? focusMetric,
    DateTime? completedAt,
  }) =>
      WorkoutSet(
        id: id ?? this.id,
        logId: logId ?? this.logId,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        rpe: rpe ?? this.rpe,
        isCompleted: isCompleted ?? this.isCompleted,
        status: status ?? this.status,
        restDuration: restDuration ?? this.restDuration,
        focusMetric: focusMetric ?? this.focusMetric,
        completedAt: completedAt ?? this.completedAt,
      );

  /// Check if set has valid data (weight or reps)
  bool get hasData => (reps != null && reps! > 0) || (weight != null && weight! > 0);

  /// Check if set can be completed
  bool get canComplete => hasData;
}