import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/resource.dart';

void main() {
  group('Resource', () {
    const createdAt = 1700000000000;
    const updatedAt = 1700100000000;
    const deletedAt = 1700200000000;

    final json = {
      'id': 'res-1',
      'trainer_id': 'trainer-1',
      'title': 'Beginner Workout Guide',
      'description': 'A comprehensive guide for beginners',
      'file_url': 'https://example.com/guide.pdf',
      'file_type': 'pdf',
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };

    test('fromJson parses all fields correctly', () {
      final model = Resource.fromJson(json);
      expect(model.id, 'res-1');
      expect(model.trainerId, 'trainer-1');
      expect(model.title, 'Beginner Workout Guide');
      expect(model.description, 'A comprehensive guide for beginners');
      expect(model.fileUrl, 'https://example.com/guide.pdf');
      expect(model.fileType, 'pdf');
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(createdAt));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(updatedAt));
      expect(model.deletedAt, DateTime.fromMillisecondsSinceEpoch(deletedAt));
    });

    test('toJson produces correct wire format', () {
      final model = Resource.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimal = {
        'id': 'res-2',
        'trainer_id': 'trainer-1',
        'title': 'Meal Plan Template',
        'file_url': 'https://example.com/meal-plan.pdf',
        'file_type': 'pdf',
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
      final model = Resource.fromJson(minimal);
      expect(model.id, 'res-2');
      expect(model.trainerId, 'trainer-1');
      expect(model.title, 'Meal Plan Template');
      expect(model.fileUrl, 'https://example.com/meal-plan.pdf');
      expect(model.fileType, 'pdf');
      expect(model.description, isNull);
      expect(model.deletedAt, isNull);
    });

    test('equality works correctly', () {
      final model1 = Resource.fromJson(json);
      final model2 = Resource.fromJson(json);
      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality detects different id', () {
      final model1 = Resource.fromJson({...json, 'id': 'res-1'});
      final model2 = Resource.fromJson({...json, 'id': 'res-2'});
      expect(model1, isNot(equals(model2)));
    });

    test('hashCode is consistent', () {
      final model = Resource.fromJson(json);
      final hashCode1 = model.hashCode;
      final hashCode2 = model.hashCode;
      expect(hashCode1, equals(hashCode2));
    });
  });
}
