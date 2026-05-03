import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/recipe_tag.dart';

void main() {
  group('RecipeTag', () {
    final json = {
      'id': 'tag-1',
      'recipe_id': 'recipe-1',
      'name': 'high-protein',
    };

    test('fromJson parses all fields correctly', () {
      final model = RecipeTag.fromJson(json);
      expect(model.id, 'tag-1');
      expect(model.recipeId, 'recipe-1');
      expect(model.name, 'high-protein');
    });

    test('toJson produces correct wire format', () {
      final model = RecipeTag.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles minimal data', () {
      final minimal = {
        'id': 'tag-2',
        'recipe_id': 'recipe-2',
        'name': 'vegan',
      };
      final model = RecipeTag.fromJson(minimal);
      expect(model.id, 'tag-2');
      expect(model.recipeId, 'recipe-2');
      expect(model.name, 'vegan');
    });

    test('equality works correctly', () {
      final model1 = RecipeTag.fromJson(json);
      final model2 = RecipeTag.fromJson(json);
      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality detects different id', () {
      final model1 = RecipeTag.fromJson({...json, 'id': 'tag-1'});
      final model2 = RecipeTag.fromJson({...json, 'id': 'tag-2'});
      expect(model1, isNot(equals(model2)));
    });

    test('hashCode is consistent', () {
      final model = RecipeTag.fromJson(json);
      final hashCode1 = model.hashCode;
      final hashCode2 = model.hashCode;
      expect(hashCode1, equals(hashCode2));
    });
  });
}
