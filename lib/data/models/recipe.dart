import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Recipe {
  final String id;
  final String trainerId;
  final String name;
  final String? description;
  final String? instructions;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final int? calories;
  final String? difficulty;
  final int? prepTime;
  final int? cookTime;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Recipe({
    required this.id,
    required this.trainerId,
    required this.name,
    this.description,
    this.instructions,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.calories,
    this.difficulty,
    this.prepTime,
    this.cookTime,
    this.isPublished = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) =>
      Recipe(
        id: json['id'] as String,
        trainerId: json['trainer_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        instructions: json['instructions'] as String?,
        proteinG:
            (json['protein_g'] as num?)?.toDouble(),
        carbsG: (json['carbs_g'] as num?)?.toDouble(),
        fatG: (json['fat_g'] as num?)?.toDouble(),
        calories: json['calories'] as int?,
        difficulty: json['difficulty'] as String?,
        prepTime: json['prep_time'] as int?,
        cookTime: json['cook_time'] as int?,
        isPublished:
            (json['is_published'] as bool?) ?? false,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(
            json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainer_id': trainerId,
        'name': name,
        'description': description,
        'instructions': instructions,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'calories': calories,
        'difficulty': difficulty,
        'prep_time': prepTime,
        'cook_time': cookTime,
        'is_published': isPublished,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Recipe(id: $id, trainerId: $trainerId, name: $name, '
      'description: $description, instructions: $instructions, '
      'proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, '
      'calories: $calories, difficulty: $difficulty, '
      'prepTime: $prepTime, cookTime: $cookTime, '
      'isPublished: $isPublished, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          id == other.id &&
          trainerId == other.trainerId &&
          name == other.name &&
          description == other.description &&
          instructions == other.instructions &&
          proteinG == other.proteinG &&
          carbsG == other.carbsG &&
          fatG == other.fatG &&
          calories == other.calories &&
          difficulty == other.difficulty &&
          prepTime == other.prepTime &&
          cookTime == other.cookTime &&
          isPublished == other.isPublished &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        trainerId,
        name,
        description,
        instructions,
        proteinG,
        carbsG,
        fatG,
        calories,
        difficulty,
        prepTime,
        cookTime,
        isPublished,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
