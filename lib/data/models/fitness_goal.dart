import 'package:zirofit_fl/core/utils/json_helpers.dart';

/// Type of fitness goal.
///
/// Wire values: `"SESSIONS"`, `"VOLUME"`, `"PR"`
enum GoalType {
  sessions,
  volume,
  pr;

  factory GoalType.fromJson(String value) =>
      GoalType.values.firstWhere((e) => e.name == value.toLowerCase());

  String toJson() => name.toUpperCase();
}

/// A fitness goal stored locally on the device.
///
/// Goals are persisted as JSON in SharedPreferences since there is no
/// dedicated backend endpoint for them.
class FitnessGoal {
  final String id;
  final GoalType type;
  final double targetValue;
  final double currentValue;
  final DateTime startDate;
  final DateTime? endDate;
  final String? exerciseName;

  const FitnessGoal({
    required this.id,
    required this.type,
    required this.targetValue,
    this.currentValue = 0.0,
    required this.startDate,
    this.endDate,
    this.exerciseName,
  });

  /// Progress toward the goal, clamped between 0.0 and 1.0.
  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  factory FitnessGoal.fromJson(Map<String, dynamic> json) => FitnessGoal(
        id: json['id'] as String,
        type: GoalType.fromJson(json['type'] as String),
        targetValue: (json['target_value'] as num).toDouble(),
        currentValue: (json['current_value'] as num?)?.toDouble() ?? 0.0,
        startDate: dateTimeFromJson(json['start_date'] as int),
        endDate: dateTimeFromJsonOrNull(json['end_date'] as int?),
        exerciseName: json['exercise_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'target_value': targetValue,
        'current_value': currentValue,
        'start_date': dateTimeToJson(startDate),
        'end_date': dateTimeToJson(endDate),
        'exercise_name': exerciseName,
      };

  /// Returns a copy with the given fields replaced.
  FitnessGoal copyWith({
    String? id,
    GoalType? type,
    double? targetValue,
    double? currentValue,
    DateTime? startDate,
    DateTime? endDate,
    String? exerciseName,
  }) =>
      FitnessGoal(
        id: id ?? this.id,
        type: type ?? this.type,
        targetValue: targetValue ?? this.targetValue,
        currentValue: currentValue ?? this.currentValue,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        exerciseName: exerciseName ?? this.exerciseName,
      );

  @override
  String toString() =>
      'FitnessGoal(id: $id, type: $type, targetValue: $targetValue, '
      'currentValue: $currentValue, startDate: $startDate, '
      'endDate: $endDate, exerciseName: $exerciseName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FitnessGoal &&
          id == other.id &&
          type == other.type &&
          targetValue == other.targetValue &&
          currentValue == other.currentValue &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          exerciseName == other.exerciseName;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        targetValue,
        currentValue,
        startDate,
        endDate,
        exerciseName,
      );
}
