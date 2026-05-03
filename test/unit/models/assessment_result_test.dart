import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/assessment_result.dart';

void main() {
  group('AssessmentResult model', () {
    final date = DateTime.fromMillisecondsSinceEpoch(1700006400000);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(1700092800000);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700179200000);

    Map<String, dynamic> createJson() => {
          'id': 'ar-1',
          'assessment_id': 'assessment-1',
          'client_id': 'client-1',
          'value': 22.5,
          'date': 1700006400000,
          'notes': 'Good improvement',
          'created_at': 1700092800000,
          'updated_at': 1700179200000,
          'deleted_at': 1700265600000,
        };

    test('fromJson parses all fields correctly', () {
      final json = createJson();
      final result = AssessmentResult.fromJson(json);
      expect(result.id, 'ar-1');
      expect(result.assessmentId, 'assessment-1');
      expect(result.clientId, 'client-1');
      expect(result.value, 22.5);
      expect(result.date, date);
      expect(result.notes, 'Good improvement');
      expect(result.createdAt, createdAt);
      expect(result.updatedAt, updatedAt);
      expect(result.deletedAt, DateTime.fromMillisecondsSinceEpoch(1700265600000));
    });

    test('toJson produces correct wire format', () {
      final json = createJson();
      final result = AssessmentResult.fromJson(json);
      final output = result.toJson();
      expect(output['id'], 'ar-1');
      expect(output['assessment_id'], 'assessment-1');
      expect(output['client_id'], 'client-1');
      expect(output['value'], 22.5);
      expect(output['date'], 1700006400000);
      expect(output['notes'], 'Good improvement');
      expect(output['created_at'], 1700092800000);
      expect(output['updated_at'], 1700179200000);
      expect(output['deleted_at'], 1700265600000);
      // Verify snake_case keys
      expect(output.containsKey('assessment_id'), isTrue);
      expect(output.containsKey('client_id'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'ar-2',
        'assessment_id': 'assessment-2',
        'client_id': 'client-2',
        'value': 30.0,
        'date': 1700006400000,
        'created_at': 1700092800000,
        'updated_at': 1700179200000,
      };
      final result = AssessmentResult.fromJson(json);
      expect(result.notes, isNull);
      expect(result.deletedAt, isNull);
    });

    test('equality works correctly with same JSON input', () {
      final json = createJson();
      final r1 = AssessmentResult.fromJson(json);
      final r2 = AssessmentResult.fromJson(json);
      expect(r1, equals(r2));
    });

    test('assessment results with different ids are not equal', () {
      final r1 = AssessmentResult.fromJson(createJson()..['id'] = 'id-1');
      final r2 = AssessmentResult.fromJson(createJson()..['id'] = 'id-2');
      expect(r1, isNot(equals(r2)));
    });

    test('toJson roundtrip produces matching data', () {
      final json = createJson();
      final result = AssessmentResult.fromJson(json);
      final output = result.toJson();
      expect(output['id'], json['id']);
      expect(output['assessment_id'], json['assessment_id']);
      expect(output['client_id'], json['client_id']);
      expect(output['value'], json['value']);
    });

    test('hashCode is consistent', () {
      final json = createJson();
      final r1 = AssessmentResult.fromJson(json);
      final r2 = AssessmentResult.fromJson(json);
      expect(r1.hashCode, equals(r2.hashCode));
    });
  });
}
