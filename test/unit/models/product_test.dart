import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/product.dart';

void main() {
  group('Product', () {
    final json = {
      'id': 'prod-1',
      'recipe_id': 'recipe-1',
      'name': 'Whey Protein Isolate',
      'brand': 'Optimum Nutrition',
      'amount': '500g',
      'is_recommended': true,
    };

    test('fromJson parses all fields correctly', () {
      final model = Product.fromJson(json);
      expect(model.id, 'prod-1');
      expect(model.recipeId, 'recipe-1');
      expect(model.name, 'Whey Protein Isolate');
      expect(model.brand, 'Optimum Nutrition');
      expect(model.amount, '500g');
      expect(model.isRecommended, true);
    });

    test('toJson produces correct wire format', () {
      final model = Product.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimal = {
        'id': 'prod-2',
        'recipe_id': 'recipe-2',
        'name': 'Creatine Monohydrate',
      };
      final model = Product.fromJson(minimal);
      expect(model.id, 'prod-2');
      expect(model.recipeId, 'recipe-2');
      expect(model.name, 'Creatine Monohydrate');
      expect(model.brand, isNull);
      expect(model.amount, isNull);
      expect(model.isRecommended, false);
    });

    test('equality works correctly', () {
      final model1 = Product.fromJson(json);
      final model2 = Product.fromJson(json);
      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality detects different id', () {
      final model1 = Product.fromJson({...json, 'id': 'prod-1'});
      final model2 = Product.fromJson({...json, 'id': 'prod-2'});
      expect(model1, isNot(equals(model2)));
    });

    test('hashCode is consistent', () {
      final model = Product.fromJson(json);
      final hashCode1 = model.hashCode;
      final hashCode2 = model.hashCode;
      expect(hashCode1, equals(hashCode2));
    });
  });
}
