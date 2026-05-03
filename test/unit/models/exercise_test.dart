import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/exercise.dart';

void main() {
  group('Exercise', () {
    final json = {
      'id': 'test-id',
      'name': 'Bench Press',
      'muscle_group': 'Chest',
      'equipment': 'Barbell',
      'category': 'Strength',
      'description': 'Lie on a flat bench and press the barbell up',
      'video_url': 'https://example.com/bench-press.mp4',
      'created_by_id': 'test-trainer-id',
      'recommended_rest_seconds': 90,
      'is_unilateral': false,
      'created_at': 1700000000000,
      'updated_at': 1700000001000,
      'deleted_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final model = Exercise.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.name, 'Bench Press');
      expect(model.muscleGroup, 'Chest');
      expect(model.equipment, 'Barbell');
      expect(model.category, 'Strength');
      expect(model.description, 'Lie on a flat bench and press the barbell up');
      expect(model.videoUrl, 'https://example.com/bench-press.mp4');
      expect(model.createdById, 'test-trainer-id');
      expect(model.recommendedRestSeconds, 90);
      expect(model.isUnilateral, false);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000001000));
      expect(model.deletedAt, isNull);
    });

    test('toJson produces correct wire format', () {
      final model = Exercise.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'id': 'test-id',
        'name': 'Bench Press',
        'created_at': 1700000000000,
        'updated_at': 1700000001000,
      };
      final model = Exercise.fromJson(minimalJson);
      expect(model.muscleGroup, isNull);
      expect(model.equipment, isNull);
      expect(model.category, isNull);
      expect(model.description, isNull);
      expect(model.videoUrl, isNull);
      expect(model.createdById, isNull);
      expect(model.recommendedRestSeconds, isNull);
      expect(model.deletedAt, isNull);
      expect(model.isUnilateral, false);
    });

    test('equality works correctly', () {
      final model1 = Exercise.fromJson(json);
      final model2 = Exercise.fromJson(json);
      expect(model1, equals(model2));
    });

    test('hashCode is consistent', () {
      final model = Exercise.fromJson(json);
      expect(model.hashCode, equals(model.hashCode));
    });
  });
}
