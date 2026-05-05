import 'package:zirofit_fl/core/utils/json_helpers.dart';

class WorkoutProgram {
  final String id;
  final String name;
  final String? description;
  final String? trainerId;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const WorkoutProgram({
    required this.id,
    required this.name,
    this.description,
    this.trainerId,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) => WorkoutProgram(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    trainerId: readStringOrNull(json, 'trainer_id', 'trainerId'),
    category: json['category'] as String?,
    createdAt: readDateTime(json, 'created_at', 'createdAt'),
    updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
    deletedAt: readDateTimeOrNull(json, 'deleted_at', 'deletedAt'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'trainer_id': trainerId,
    'category': category,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
    'deleted_at': dateTimeToJson(deletedAt),
  };

  @override
  String toString() =>
      'WorkoutProgram(id: $id, name: $name, '
      'description: $description, trainerId: $trainerId, '
      'category: $category, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutProgram &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          trainerId == other.trainerId &&
          category == other.category &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    trainerId,
    category,
    createdAt,
    updatedAt,
    deletedAt,
  );
}
