import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/client_program_assignment.dart';

void main() {
  group('ClientProgramAssignment model', () {
    final startDate = DateTime.fromMillisecondsSinceEpoch(1700006400000);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(1700092800000);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700179200000);
    final deletedAt = DateTime.fromMillisecondsSinceEpoch(1700265600000);

    Map<String, dynamic> createJson() => {
          'id': 'cpa-1',
          'client_id': 'client-1',
          'program_id': 'prog-1',
          'start_date': 1700006400000,
          'is_active': true,
          'created_at': 1700092800000,
          'updated_at': 1700179200000,
          'deleted_at': 1700265600000,
        };

    test('fromJson parses all fields correctly', () {
      final json = createJson();
      final cpa = ClientProgramAssignment.fromJson(json);
      expect(cpa.id, 'cpa-1');
      expect(cpa.clientId, 'client-1');
      expect(cpa.programId, 'prog-1');
      expect(cpa.startDate, startDate);
      expect(cpa.isActive, isTrue);
      expect(cpa.createdAt, createdAt);
      expect(cpa.updatedAt, updatedAt);
      expect(cpa.deletedAt, deletedAt);
    });

    test('toJson produces correct wire format', () {
      final json = createJson();
      final cpa = ClientProgramAssignment.fromJson(json);
      final output = cpa.toJson();
      expect(output['id'], 'cpa-1');
      expect(output['client_id'], 'client-1');
      expect(output['program_id'], 'prog-1');
      expect(output['start_date'], 1700006400000);
      expect(output['is_active'], isTrue);
      expect(output['created_at'], 1700092800000);
      expect(output['updated_at'], 1700179200000);
      expect(output['deleted_at'], 1700265600000);
      // Verify snake_case keys
      expect(output.containsKey('client_id'), isTrue);
      expect(output.containsKey('program_id'), isTrue);
      expect(output.containsKey('start_date'), isTrue);
      expect(output.containsKey('is_active'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'cpa-2',
        'client_id': 'client-2',
        'program_id': 'prog-2',
        'start_date': 1700006400000,
        'created_at': 1700092800000,
        'updated_at': 1700179200000,
      };
      final cpa = ClientProgramAssignment.fromJson(json);
      expect(cpa.isActive, isTrue);
      expect(cpa.deletedAt, isNull);
    });

    test('equality works correctly with same JSON input', () {
      final json = createJson();
      final cpa1 = ClientProgramAssignment.fromJson(json);
      final cpa2 = ClientProgramAssignment.fromJson(json);
      expect(cpa1, equals(cpa2));
    });

    test('assignments with different ids are not equal', () {
      final cpa1 = ClientProgramAssignment.fromJson(createJson()..['id'] = 'id-1');
      final cpa2 = ClientProgramAssignment.fromJson(createJson()..['id'] = 'id-2');
      expect(cpa1, isNot(equals(cpa2)));
    });

    test('toJson roundtrip produces matching data', () {
      final json = createJson();
      final cpa = ClientProgramAssignment.fromJson(json);
      final output = cpa.toJson();
      expect(output['id'], json['id']);
      expect(output['client_id'], json['client_id']);
      expect(output['program_id'], json['program_id']);
      expect(output['is_active'], json['is_active']);
    });

    test('hashCode is consistent', () {
      final json = createJson();
      final cpa1 = ClientProgramAssignment.fromJson(json);
      final cpa2 = ClientProgramAssignment.fromJson(json);
      expect(cpa1.hashCode, equals(cpa2.hashCode));
    });
  });
}
