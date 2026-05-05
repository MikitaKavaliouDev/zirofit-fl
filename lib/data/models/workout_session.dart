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

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    clientId: () {
      // Try flat keys first (snake_case, camelCase)
      final flat = readStringOrNull(json, 'client_id', 'clientId');
      if (flat != null) return flat;
      // Fallback: nested client object (backend returns {"client":{"id":"..."}})
      final clientMap = json['client'] as Map<String, dynamic>?;
      final nestedId = clientMap?['id'] as String?;
      if (nestedId != null) return nestedId;
      throw FormatException('Missing client_id/clientId/client.id');
    }(),
    name:
        json['name'] as String? ??
        (json['client'] as Map<String, dynamic>?)?['name'] as String?,
    startTime: readDateTime(json, 'start_time', 'startTime'),
    endTime: readDateTimeOrNull(json, 'end_time', 'endTime'),
    status: WorkoutSessionStatus.fromJson(
      readStringOrNull(json, 'status', 'status') ?? 'IN_PROGRESS',
    ),
    notes: json['notes'] as String?,
    restStartedAt: readDateTimeOrNull(json, 'rest_started_at', 'restStartedAt'),
    workoutTemplateId: readStringOrNull(
      json,
      'workout_template_id',
      'workoutTemplateId',
    ),
    plannedDate: readDateTimeOrNull(json, 'planned_date', 'plannedDate'),
    clientPackageId: readStringOrNull(
      json,
      'client_package_id',
      'clientPackageId',
    ),
    isTrainerLed: readBool(json, 'is_trainer_led', 'isTrainerLed'),
    reminderTime: readDateTimeOrNull(json, 'reminder_time', 'reminderTime'),
    trainerReminderSent: readBool(
      json,
      'trainer_reminder_sent',
      'trainerReminderSent',
    ),
    createdAt: readDateTime(json, 'created_at', 'createdAt'),
    updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
    deletedAt: readDateTimeOrNull(json, 'deleted_at', 'deletedAt'),
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
