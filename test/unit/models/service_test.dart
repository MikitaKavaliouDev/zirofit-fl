import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/service.dart';

void main() {
  group('Service', () {
    const createdAt = 1700000000000;
    const updatedAt = 1700100000000;
    const deletedAt = 1700200000000;

    final json = {
      'id': 'svc-1',
      'profile_id': 'profile-1',
      'title': 'Personal Training Session',
      'description': 'One-on-one personal training session',
      'price': 79.99,
      'currency': 'USD',
      'duration': 60,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };

    test('fromJson parses all fields correctly', () {
      final model = Service.fromJson(json);
      expect(model.id, 'svc-1');
      expect(model.profileId, 'profile-1');
      expect(model.title, 'Personal Training Session');
      expect(model.description, 'One-on-one personal training session');
      expect(model.price, 79.99);
      expect(model.currency, 'USD');
      expect(model.duration, 60);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(createdAt));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(updatedAt));
      expect(model.deletedAt, DateTime.fromMillisecondsSinceEpoch(deletedAt));
    });

    test('toJson produces correct wire format', () {
      final model = Service.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimal = {
        'id': 'svc-2',
        'profile_id': 'profile-2',
        'title': 'Nutrition Consultation',
        'description': 'Diet planning session',
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
      final model = Service.fromJson(minimal);
      expect(model.id, 'svc-2');
      expect(model.profileId, 'profile-2');
      expect(model.title, 'Nutrition Consultation');
      expect(model.description, 'Diet planning session');
      expect(model.price, isNull);
      expect(model.currency, isNull);
      expect(model.duration, isNull);
      expect(model.deletedAt, isNull);
    });

    test('equality works correctly', () {
      final model1 = Service.fromJson(json);
      final model2 = Service.fromJson(json);
      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality detects different id', () {
      final model1 = Service.fromJson({...json, 'id': 'svc-1'});
      final model2 = Service.fromJson({...json, 'id': 'svc-2'});
      expect(model1, isNot(equals(model2)));
    });

    test('hashCode is consistent', () {
      final model = Service.fromJson(json);
      final hashCode1 = model.hashCode;
      final hashCode2 = model.hashCode;
      expect(hashCode1, equals(hashCode2));
    });
  });
}
