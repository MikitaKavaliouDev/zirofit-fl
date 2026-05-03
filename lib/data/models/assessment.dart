import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Assessment {
  final String id;
  final String name;
  final String? description;
  final String unit;
  final String? trainerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Assessment({
    required this.id,
    required this.name,
    this.description,
    required this.unit,
    this.trainerId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) =>
      Assessment(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        unit: json['unit'] as String,
        trainerId: json['trainer_id'] as String?,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(
            json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'unit': unit,
        'trainer_id': trainerId,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Assessment(id: $id, name: $name, '
      'description: $description, unit: $unit, '
      'trainerId: $trainerId, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Assessment &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          unit == other.unit &&
          trainerId == other.trainerId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        unit,
        trainerId,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
