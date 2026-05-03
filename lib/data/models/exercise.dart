import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Exercise {
  final String id;
  final String name;
  final String? muscleGroup;
  final String? equipment;
  final String? category;
  final String? description;
  final String? videoUrl;
  final String? createdById;
  final int? recommendedRestSeconds;
  final bool isUnilateral;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Exercise({
    required this.id,
    required this.name,
    this.muscleGroup,
    this.equipment,
    this.category,
    this.description,
    this.videoUrl,
    this.createdById,
    this.recommendedRestSeconds,
    this.isUnilateral = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        muscleGroup: json['muscle_group'] as String?,
        equipment: json['equipment'] as String?,
        category: json['category'] as String?,
        description: json['description'] as String?,
        videoUrl: json['video_url'] as String?,
        createdById: json['created_by_id'] as String?,
        recommendedRestSeconds:
            json['recommended_rest_seconds'] as int?,
        isUnilateral: (json['is_unilateral'] as bool?) ?? false,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt:
            dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'muscle_group': muscleGroup,
        'equipment': equipment,
        'category': category,
        'description': description,
        'video_url': videoUrl,
        'created_by_id': createdById,
        'recommended_rest_seconds': recommendedRestSeconds,
        'is_unilateral': isUnilateral,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Exercise(id: $id, name: $name, muscleGroup: $muscleGroup, '
      'equipment: $equipment, category: $category, '
      'description: $description, videoUrl: $videoUrl, '
      'createdById: $createdById, '
      'recommendedRestSeconds: $recommendedRestSeconds, '
      'isUnilateral: $isUnilateral, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          id == other.id &&
          name == other.name &&
          muscleGroup == other.muscleGroup &&
          equipment == other.equipment &&
          category == other.category &&
          description == other.description &&
          videoUrl == other.videoUrl &&
          createdById == other.createdById &&
          recommendedRestSeconds == other.recommendedRestSeconds &&
          isUnilateral == other.isUnilateral &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        muscleGroup,
        equipment,
        category,
        description,
        videoUrl,
        createdById,
        recommendedRestSeconds,
        isUnilateral,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
