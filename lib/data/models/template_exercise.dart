import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/step_type.dart';

class TemplateExercise {
  final String id;
  final String templateId;
  final StepType? type;
  final String? exerciseId;
  final String? targetReps;
  final int? targetRIR;
  final String? tempo;
  final bool enableRpe;
  final int? durationSeconds;
  final String? notes;
  final int order;
  final String? supersetGroupId;
  final int? supersetOrder;
  final int? targetSets;
  final int? targetRest;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const TemplateExercise({
    required this.id,
    required this.templateId,
    this.type,
    this.exerciseId,
    this.targetReps,
    this.targetRIR,
    this.tempo,
    this.enableRpe = false,
    this.durationSeconds,
    this.notes,
    this.order = 0,
    this.supersetGroupId,
    this.supersetOrder,
    this.targetSets,
    this.targetRest,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory TemplateExercise.fromJson(Map<String, dynamic> json) =>
      TemplateExercise(
        id: json['id'] as String,
        templateId: readString(json, 'template_id', 'templateId'),
        type: json['type'] != null
            ? StepType.fromJson(json['type'] as String)
            : null,
        exerciseId: readStringOrNull(json, 'exercise_id', 'exerciseId'),
        targetReps: json['target_reps'] as String?,
        targetRIR: json['target_rir'] as int?,
        tempo: json['tempo'] as String?,
        enableRpe: readBool(json, 'enable_rpe', 'enableRpe'),
        durationSeconds: json['duration_seconds'] as int?,
        notes: json['notes'] as String?,
        order: (json['order'] as int?) ?? 0,
        supersetGroupId: readStringOrNull(
          json,
          'superset_group_id',
          'supersetGroupId',
        ),
        supersetOrder: readIntOrNull(json, 'superset_order', 'supersetOrder'),
        targetSets: json['target_sets'] as int?,
        targetRest: json['target_rest'] as int?,
        createdAt: readDateTime(json, 'created_at', 'createdAt'),
        updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
        deletedAt: readDateTimeOrNull(json, 'deleted_at', 'deletedAt'),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'template_id': templateId,
    'type': type?.toJson(),
    'exercise_id': exerciseId,
    'target_reps': targetReps,
    'target_rir': targetRIR,
    'tempo': tempo,
    'enable_rpe': enableRpe,
    'duration_seconds': durationSeconds,
    'notes': notes,
    'order': order,
    'superset_group_id': supersetGroupId,
    'superset_order': supersetOrder,
    'target_sets': targetSets,
    'target_rest': targetRest,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };

  @override
  String toString() =>
      'TemplateExercise(id: $id, templateId: $templateId, '
      'type: $type, exerciseId: $exerciseId, '
      'targetReps: $targetReps, targetRIR: $targetRIR, '
      'tempo: $tempo, enableRpe: $enableRpe, '
      'durationSeconds: $durationSeconds, notes: $notes, '
      'order: $order, supersetGroupId: $supersetGroupId, '
      'supersetOrder: $supersetOrder, '
      'targetSets: $targetSets, targetRest: $targetRest, '
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateExercise &&
          id == other.id &&
          templateId == other.templateId &&
          type == other.type &&
          exerciseId == other.exerciseId &&
          targetReps == other.targetReps &&
          targetRIR == other.targetRIR &&
          tempo == other.tempo &&
          enableRpe == other.enableRpe &&
          durationSeconds == other.durationSeconds &&
          notes == other.notes &&
          order == other.order &&
          supersetGroupId == other.supersetGroupId &&
          supersetOrder == other.supersetOrder &&
          targetSets == other.targetSets &&
          targetRest == other.targetRest &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    type,
    exerciseId,
    targetReps,
    targetRIR,
    tempo,
    enableRpe,
    durationSeconds,
    notes,
    order,
    supersetGroupId,
    supersetOrder,
    targetSets,
    targetRest,
    createdAt,
    updatedAt,
    deletedAt,
  );
}
