import 'package:zirofit_fl/core/utils/json_helpers.dart';

class PersonalRecord {
  final String id;
  final String clientId;
  final String exerciseId;
  final String workoutSessionId;
  final String recordType;
  final double value;
  final DateTime achievedAt;
  final DateTime? deletedAt;

  const PersonalRecord({
    required this.id,
    required this.clientId,
    required this.exerciseId,
    required this.workoutSessionId,
    required this.recordType,
    required this.value,
    required this.achievedAt,
    this.deletedAt,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) =>
      PersonalRecord(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        exerciseId: json['exercise_id'] as String,
        workoutSessionId:
            json['workout_session_id'] as String,
        recordType: json['record_type'] as String,
        value: (json['value'] as num).toDouble(),
        achievedAt:
            dateTimeFromJson(json['achieved_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(
            json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'exercise_id': exerciseId,
        'workout_session_id': workoutSessionId,
        'record_type': recordType,
        'value': value,
        'achieved_at': dateTimeToJson(achievedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'PersonalRecord(id: $id, clientId: $clientId, '
      'exerciseId: $exerciseId, '
      'workoutSessionId: $workoutSessionId, '
      'recordType: $recordType, value: $value, '
      'achievedAt: $achievedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalRecord &&
          id == other.id &&
          clientId == other.clientId &&
          exerciseId == other.exerciseId &&
          workoutSessionId == other.workoutSessionId &&
          recordType == other.recordType &&
          value == other.value &&
          achievedAt == other.achievedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        exerciseId,
        workoutSessionId,
        recordType,
        value,
        achievedAt,
        deletedAt,
      );
}
