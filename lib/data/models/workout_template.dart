import 'package:zirofit_fl/core/utils/json_helpers.dart';

class WorkoutTemplate {
  final String id;
  final String name;
  final String? description;
  final String programId;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.programId,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) =>
      WorkoutTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        programId: readString(json, 'program_id', 'programId'),
        order: (json['order'] as int?) ?? 0,
        createdAt: readDateTime(json, 'created_at', 'createdAt'),
        updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
        deletedAt: readDateTimeOrNull(json, 'deleted_at', 'deletedAt'),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'program_id': programId,
    'order': order,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };

  @override
  String toString() =>
      'WorkoutTemplate(id: $id, name: $name, '
      'description: $description, programId: $programId, '
      'order: $order, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTemplate &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          programId == other.programId &&
          order == other.order &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    programId,
    order,
    createdAt,
    updatedAt,
    deletedAt,
  );
}
