import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/package.dart';

void main() {
  group('Package', () {
    const createdAt = 1700000000000;
    const updatedAt = 1700100000000;
    const deletedAt = 1700200000000;

    final json = {
      'id': 'pkg-1',
      'name': '10 Session Pack',
      'description': 'Best value pack for regular training',
      'price': 299.99,
      'number_of_sessions': 10,
      'is_active': true,
      'stripe_product_id': 'prod_123',
      'stripe_price_id': 'price_123',
      'trainer_id': 'trainer-1',
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };

    test('fromJson parses all fields correctly', () {
      final model = Package.fromJson(json);
      expect(model.id, 'pkg-1');
      expect(model.name, '10 Session Pack');
      expect(model.description, 'Best value pack for regular training');
      expect(model.price, 299.99);
      expect(model.numberOfSessions, 10);
      expect(model.isActive, true);
      expect(model.stripeProductId, 'prod_123');
      expect(model.stripePriceId, 'price_123');
      expect(model.trainerId, 'trainer-1');
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(createdAt));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(updatedAt));
      expect(model.deletedAt, DateTime.fromMillisecondsSinceEpoch(deletedAt));
    });

    test('toJson produces correct wire format', () {
      final model = Package.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimal = {
        'id': 'pkg-2',
        'name': 'Single Session',
        'price': 49.99,
        'number_of_sessions': 1,
        'stripe_product_id': 'prod_456',
        'stripe_price_id': 'price_456',
        'trainer_id': 'trainer-1',
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
      final model = Package.fromJson(minimal);
      expect(model.id, 'pkg-2');
      expect(model.name, 'Single Session');
      expect(model.price, 49.99);
      expect(model.numberOfSessions, 1);
      expect(model.isActive, true);
      expect(model.description, isNull);
      expect(model.deletedAt, isNull);
    });

    test('equality works correctly', () {
      final model1 = Package.fromJson(json);
      final model2 = Package.fromJson(json);
      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality detects different id', () {
      final model1 = Package.fromJson({...json, 'id': 'pkg-1'});
      final model2 = Package.fromJson({...json, 'id': 'pkg-2'});
      expect(model1, isNot(equals(model2)));
    });

    test('hashCode is consistent', () {
      final model = Package.fromJson(json);
      final hashCode1 = model.hashCode;
      final hashCode2 = model.hashCode;
      expect(hashCode1, equals(hashCode2));
    });
  });
}
