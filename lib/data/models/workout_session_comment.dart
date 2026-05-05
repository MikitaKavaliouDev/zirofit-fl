import 'package:zirofit_fl/core/utils/json_helpers.dart';

class WorkoutSessionComment {
  final String id;
  final String text;
  final String workoutSessionId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const WorkoutSessionComment({
    required this.id,
    required this.text,
    required this.workoutSessionId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkoutSessionComment.fromJson(Map<String, dynamic> json) =>
      WorkoutSessionComment(
        id: json['id'] as String,
        text: json['text'] as String,
        workoutSessionId: readString(
          json,
          'workout_session_id',
          'workoutSessionId',
        ),
        userId: readString(json, 'user_id', 'userId'),
        createdAt: readDateTime(json, 'created_at', 'createdAt'),
        updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
        deletedAt: readDateTimeOrNull(json, 'deleted_at', 'deletedAt'),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'workout_session_id': workoutSessionId,
    'user_id': userId,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };

  @override
  String toString() =>
      'WorkoutSessionComment(id: $id, text: $text, '
      'workoutSessionId: $workoutSessionId, userId: $userId, '
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionComment &&
          id == other.id &&
          text == other.text &&
          workoutSessionId == other.workoutSessionId &&
          userId == other.userId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    text,
    workoutSessionId,
    userId,
    createdAt,
    updatedAt,
    deletedAt,
  );
}
