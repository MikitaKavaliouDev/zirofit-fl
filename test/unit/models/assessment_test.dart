import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/assessment.dart';

void main() {
  group('Assessment model', () {
    const description = 'Body fat percentage measurement';
    const trainerId = 'trainer-1';
    final createdAt = DateTime.fromMillisecondsSinceEpoch(1700006400000);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700092800000);
    final deletedAt = DateTime.fromMillisecondsSinceEpoch(1700179200000);

    Map<String, dynamic> createJson() => {
          'id': 'assessment-1',
          'name': 'Body Fat %',
          'description': description,
          'unit': '%',
          'trainer_id': trainerId,
          'created_at': 1700006400000,
          'updated_at': 1700092800000,
          'deleted_at': 1700179200000,
        };

    test('fromJson parses all fields correctly', () {
      final json = createJson();
      final assessment = Assessment.fromJson(json);
      expect(assessment.id, 'assessment-1');
      expect(assessment.name, 'Body Fat %');
      expect(assessment.description, description);
      expect(assessment.unit, '%');
      expect(assessment.trainerId, trainerId);
      expect(assessment.createdAt, createdAt);
      expect(assessment.updatedAt, updatedAt);
      expect(assessment.deletedAt, deletedAt);
    });

    test('toJson produces correct wire format', () {
      final json = createJson();
      final assessment = Assessment.fromJson(json);
      final output = assessment.toJson();
      expect(output['id'], 'assessment-1');
      expect(output['name'], 'Body Fat %');
      expect(output['description'], description);
      expect(output['unit'], '%');
      expect(output['trainer_id'], trainerId);
      expect(output['created_at'], 1700006400000);
      expect(output['updated_at'], 1700092800000);
      expect(output['deleted_at'], 1700179200000);
      // Verify snake_case keys
      expect(output.containsKey('trainer_id'), isTrue);
      expect(output.containsKey('created_at'), isTrue);
      expect(output.containsKey('updated_at'), isTrue);
      expect(output.containsKey('deleted_at'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'assessment-2',
        'name': 'Strength Test',
        'unit': 'kg',
        'created_at': 1700006400000,
        'updated_at': 1700092800000,
      };
      final assessment = Assessment.fromJson(json);
      expect(assessment.id, 'assessment-2');
      expect(assessment.description, isNull);
      expect(assessment.trainerId, isNull);
      expect(assessment.deletedAt, isNull);
    });

    test('equality works correctly with same JSON input', () {
      final json = createJson();
      final a1 = Assessment.fromJson(json);
      final a2 = Assessment.fromJson(json);
      expect(a1, equals(a2));
    });

    test('assessments with different ids are not equal', () {
      final a1 = Assessment.fromJson(createJson()..['id'] = 'id-1');
      final a2 = Assessment.fromJson(createJson()..['id'] = 'id-2');
      expect(a1, isNot(equals(a2)));
    });

    test('toJson roundtrip produces matching data', () {
      final json = createJson();
      final assessment = Assessment.fromJson(json);
      final output = assessment.toJson();
      expect(output['id'], json['id']);
      expect(output['name'], json['name']);
      expect(output['unit'], json['unit']);
      expect(output['description'], json['description']);
    });

    test('hashCode is consistent', () {
      final json = createJson();
      final a1 = Assessment.fromJson(json);
      final a2 = Assessment.fromJson(json);
      expect(a1.hashCode, equals(a2.hashCode));
    });
  });
}
