import 'package:zirofit_fl/core/utils/json_helpers.dart';

class HabitLog {
  final String id;
  final String habitId;
  final String clientId;
  final DateTime date;
  final bool isCompleted;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.clientId,
    required this.date,
    this.isCompleted = false,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) =>
      HabitLog(
        id: json['id'] as String,
        habitId: json['habit_id'] as String,
        clientId: json['client_id'] as String,
        date: dateTimeFromJson(json['date'] as int),
        isCompleted:
            (json['is_completed'] as bool?) ?? false,
        note: json['note'] as String?,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'habit_id': habitId,
        'client_id': clientId,
        'date': dateTimeToJson(date),
        'is_completed': isCompleted,
        'note': note,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'HabitLog(id: $id, habitId: $habitId, '
      'clientId: $clientId, date: $date, '
      'isCompleted: $isCompleted, note: $note, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLog &&
          id == other.id &&
          habitId == other.habitId &&
          clientId == other.clientId &&
          date == other.date &&
          isCompleted == other.isCompleted &&
          note == other.note &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        habitId,
        clientId,
        date,
        isCompleted,
        note,
        createdAt,
        updatedAt,
      );
}
