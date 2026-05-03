import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/recipe.dart';

void main() {
  group('Recipe', () {
    const createdAt = 1700000000000;
    const updatedAt = 1700100000000;
    const deletedAt = 1700200000000;

    final json = {
      'id': 'recipe-1',
      'trainer_id': 'trainer-1',
      'name': 'Protein Pancakes',
      'description': 'Fluffy high-protein pancakes',
      'instructions': 'Mix ingredients. Cook on medium heat.',
      'protein_g': 30.5,
      'carbs_g': 25.0,
      'fat_g': 8.2,
      'calories': 320,
      'difficulty': 'easy',
      'prep_time': 10,
      'cook_time': 15,
      'is_published': true,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };

    test('fromJson parses all fields correctly', () {
      final model = Recipe.fromJson(json);
      expect(model.id, 'recipe-1');
      expect(model.trainerId, 'trainer-1');
      expect(model.name, 'Protein Pancakes');
      expect(model.description, 'Fluffy high-protein pancakes');
      expect(model.instructions, 'Mix ingredients. Cook on medium heat.');
      expect(model.proteinG, 30.5);
      expect(model.carbsG, 25.0);
      expect(model.fatG, 8.2);
      expect(model.calories, 320);
      expect(model.difficulty, 'easy');
      expect(model.prepTime, 10);
      expect(model.cookTime, 15);
      expect(model.isPublished, true);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(createdAt));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(updatedAt));
      expect(model.deletedAt, DateTime.fromMillisecondsSinceEpoch(deletedAt));
    });

    test('toJson produces correct wire format', () {
      final model = Recipe.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimal = {
        'id': 'recipe-2',
        'trainer_id': 'trainer-1',
        'name': 'Simple Oats',
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
      final model = Recipe.fromJson(minimal);
      expect(model.id, 'recipe-2');
      expect(model.trainerId, 'trainer-1');
      expect(model.name, 'Simple Oats');
      expect(model.description, isNull);
      expect(model.instructions, isNull);
      expect(model.proteinG, isNull);
      expect(model.carbsG, isNull);
      expect(model.fatG, isNull);
      expect(model.calories, isNull);
      expect(model.difficulty, isNull);
      expect(model.prepTime, isNull);
      expect(model.cookTime, isNull);
      expect(model.isPublished, false);
      expect(model.deletedAt, isNull);
    });

    test('equality works correctly', () {
      final model1 = Recipe.fromJson(json);
      final model2 = Recipe.fromJson(json);
      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality detects different id', () {
      final model1 = Recipe.fromJson({...json, 'id': 'recipe-1'});
      final model2 = Recipe.fromJson({...json, 'id': 'recipe-2'});
      expect(model1, isNot(equals(model2)));
    });

    test('hashCode is consistent', () {
      final model = Recipe.fromJson(json);
      final hashCode1 = model.hashCode;
      final hashCode2 = model.hashCode;
      expect(hashCode1, equals(hashCode2));
    });
  });
}
