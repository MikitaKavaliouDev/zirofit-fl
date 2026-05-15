import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/template_step_status.dart';

/// A template with completion status, returned inside the active program response.
class ActiveProgramTemplate {
  final String id;
  final String name;
  final String? description;
  final String programId;
  final int order;
  final TemplateStepStatus status;
  final int exerciseCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ActiveProgramTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.programId,
    this.order = 0,
    required this.status,
    this.exerciseCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActiveProgramTemplate.fromJson(Map<String, dynamic> json) =>
      ActiveProgramTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        programId: readString(json, 'program_id', 'programId'),
        order: (json['order'] as int?) ?? 0,
        status: TemplateStepStatus.fromJson(json['status'] as String),
        exerciseCount: (json['exerciseCount'] as int?) ?? 0,
        createdAt: readDateTime(json, 'created_at', 'createdAt'),
        updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'program_id': programId,
        'order': order,
        'status': status.toJson(),
        'exercise_count': exerciseCount,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'ActiveProgramTemplate(id: $id, name: $name, '
      'description: $description, programId: $programId, '
      'order: $order, status: $status, exerciseCount: $exerciseCount, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveProgramTemplate &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          programId == other.programId &&
          order == other.order &&
          status == other.status &&
          exerciseCount == other.exerciseCount &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        programId,
        order,
        status,
        exerciseCount,
        createdAt,
        updatedAt,
      );
}
