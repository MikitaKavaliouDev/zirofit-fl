import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/habit_frequency.dart';

class DailyHabit {
  final String id;
  final String clientId;
  final String trainerId;
  final String title;
  final String? description;
  final HabitFrequency frequency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const DailyHabit({
    required this.id,
    required this.clientId,
    required this.trainerId,
    required this.title,
    this.description,
    this.frequency = HabitFrequency.daily,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory DailyHabit.fromJson(Map<String, dynamic> json) =>
      DailyHabit(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        trainerId: json['trainer_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        frequency: HabitFrequency.fromJson(
            json['frequency'] as String? ?? 'DAILY'),
        isActive: (json['is_active'] as bool?) ?? true,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(
            json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'trainer_id': trainerId,
        'title': title,
        'description': description,
        'frequency': frequency.toJson(),
        'is_active': isActive,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'DailyHabit(id: $id, clientId: $clientId, '
      'trainerId: $trainerId, title: $title, '
      'description: $description, frequency: $frequency, '
      'isActive: $isActive, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyHabit &&
          id == other.id &&
          clientId == other.clientId &&
          trainerId == other.trainerId &&
          title == other.title &&
          description == other.description &&
          frequency == other.frequency &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        trainerId,
        title,
        description,
        frequency,
        isActive,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
