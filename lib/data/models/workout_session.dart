import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';

class WorkoutSession {
  final String id;
  final String clientId;
  final String? name;
  final DateTime startTime;
  final DateTime? endTime;
  final WorkoutSessionStatus status;
  final String? notes;
  final DateTime? restStartedAt;
  final String? workoutTemplateId;
  final DateTime? plannedDate;
  final String? clientPackageId;
  final bool isTrainerLed;
  final DateTime? reminderTime;
  final bool trainerReminderSent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const WorkoutSession({
    required this.id,
    required this.clientId,
    this.name,
    required this.startTime,
    this.endTime,
    this.status = WorkoutSessionStatus.inProgress,
    this.notes,
    this.restStartedAt,
    this.workoutTemplateId,
    this.plannedDate,
    this.clientPackageId,
    this.isTrainerLed = false,
    this.reminderTime,
    this.trainerReminderSent = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      WorkoutSession(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        name: json['name'] as String?,
        startTime:
            dateTimeFromJson(json['start_time'] as int),
        endTime:
            dateTimeFromJsonOrNull(json['end_time'] as int?),
        status: WorkoutSessionStatus.fromJson(
            json['status'] as String? ?? 'IN_PROGRESS'),
        notes: json['notes'] as String?,
        restStartedAt: dateTimeFromJsonOrNull(
            json['rest_started_at'] as int?),
        workoutTemplateId:
            json['workout_template_id'] as String?,
        plannedDate: dateTimeFromJsonOrNull(
            json['planned_date'] as int?),
        clientPackageId:
            json['client_package_id'] as String?,
        isTrainerLed:
            (json['is_trainer_led'] as bool?) ?? false,
        reminderTime: dateTimeFromJsonOrNull(
            json['reminder_time'] as int?),
        trainerReminderSent:
            (json['trainer_reminder_sent'] as bool?) ?? false,
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
        'name': name,
        'start_time': dateTimeToJson(startTime),
        'end_time': dateTimeToJson(endTime),
        'status': status.toJson(),
        'notes': notes,
        'rest_started_at': dateTimeToJson(restStartedAt),
        'workout_template_id': workoutTemplateId,
        'planned_date': dateTimeToJson(plannedDate),
        'client_package_id': clientPackageId,
        'is_trainer_led': isTrainerLed,
        'reminder_time': dateTimeToJson(reminderTime),
        'trainer_reminder_sent': trainerReminderSent,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'WorkoutSession(id: $id, clientId: $clientId, name: $name, '
      'startTime: $startTime, endTime: $endTime, status: $status, '
      'notes: $notes, restStartedAt: $restStartedAt, '
      'workoutTemplateId: $workoutTemplateId, '
      'plannedDate: $plannedDate, clientPackageId: $clientPackageId, '
      'isTrainerLed: $isTrainerLed, reminderTime: $reminderTime, '
      'trainerReminderSent: $trainerReminderSent, '
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSession &&
          id == other.id &&
          clientId == other.clientId &&
          name == other.name &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          status == other.status &&
          notes == other.notes &&
          restStartedAt == other.restStartedAt &&
          workoutTemplateId == other.workoutTemplateId &&
          plannedDate == other.plannedDate &&
          clientPackageId == other.clientPackageId &&
          isTrainerLed == other.isTrainerLed &&
          reminderTime == other.reminderTime &&
          trainerReminderSent == other.trainerReminderSent &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        name,
        startTime,
        endTime,
        status,
        notes,
        restStartedAt,
        workoutTemplateId,
        plannedDate,
        clientPackageId,
        isTrainerLed,
        reminderTime,
        trainerReminderSent,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
