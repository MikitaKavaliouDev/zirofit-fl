import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/check_in.dart';

void main() {
  group('CheckIn model', () {
    final date = DateTime.fromMillisecondsSinceEpoch(1700006400000);
    final reviewedAt = DateTime.fromMillisecondsSinceEpoch(1700092800000);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(1700179200000);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700265600000);

    Map<String, dynamic> createJson() => {
          'id': 'ci-1',
          'client_id': 'client-1',
          'date': 1700006400000,
          'status': 'REVIEWED',
          'weight': 75.5,
          'waist_cm': 85.0,
          'sleep_hours': 7.5,
          'energy_level': 4,
          'stress_level': 3,
          'hunger_level': 2,
          'digestion_level': 4,
          'nutrition_compliance': 'Good',
          'client_notes': 'Feeling great today',
          'trainer_response': 'Keep it up!',
          'reviewed_at': 1700092800000,
          'reviewed_by_user_id': 'trainer-1',
          'created_at': 1700179200000,
          'updated_at': 1700265600000,
        };

    test('fromJson parses all fields correctly', () {
      final json = createJson();
      final checkIn = CheckIn.fromJson(json);
      expect(checkIn.id, 'ci-1');
      expect(checkIn.clientId, 'client-1');
      expect(checkIn.date, date);
      expect(checkIn.status, 'REVIEWED');
      expect(checkIn.weight, 75.5);
      expect(checkIn.waistCm, 85.0);
      expect(checkIn.sleepHours, 7.5);
      expect(checkIn.energyLevel, 4);
      expect(checkIn.stressLevel, 3);
      expect(checkIn.hungerLevel, 2);
      expect(checkIn.digestionLevel, 4);
      expect(checkIn.nutritionCompliance, 'Good');
      expect(checkIn.clientNotes, 'Feeling great today');
      expect(checkIn.trainerResponse, 'Keep it up!');
      expect(checkIn.reviewedAt, reviewedAt);
      expect(checkIn.reviewedByUserId, 'trainer-1');
      expect(checkIn.createdAt, createdAt);
      expect(checkIn.updatedAt, updatedAt);
    });

    test('toJson produces correct wire format', () {
      final json = createJson();
      final checkIn = CheckIn.fromJson(json);
      final output = checkIn.toJson();
      expect(output['id'], 'ci-1');
      expect(output['client_id'], 'client-1');
      expect(output['date'], 1700006400000);
      expect(output['status'], 'REVIEWED');
      expect(output['weight'], 75.5);
      expect(output['waist_cm'], 85.0);
      expect(output['sleep_hours'], 7.5);
      expect(output['energy_level'], 4);
      expect(output['stress_level'], 3);
      expect(output['hunger_level'], 2);
      expect(output['digestion_level'], 4);
      expect(output['nutrition_compliance'], 'Good');
      expect(output['client_notes'], 'Feeling great today');
      expect(output['trainer_response'], 'Keep it up!');
      expect(output['reviewed_at'], 1700092800000);
      expect(output['reviewed_by_user_id'], 'trainer-1');
      expect(output['created_at'], 1700179200000);
      expect(output['updated_at'], 1700265600000);
      // Verify snake_case keys
      expect(output.containsKey('client_id'), isTrue);
      expect(output.containsKey('waist_cm'), isTrue);
      expect(output.containsKey('nutrition_compliance'), isTrue);
      expect(output.containsKey('reviewed_by_user_id'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'ci-2',
        'client_id': 'client-2',
        'date': 1700006400000,
        'created_at': 1700179200000,
        'updated_at': 1700265600000,
      };
      final checkIn = CheckIn.fromJson(json);
      expect(checkIn.status, 'SUBMITTED');
      expect(checkIn.weight, isNull);
      expect(checkIn.waistCm, isNull);
      expect(checkIn.sleepHours, isNull);
      expect(checkIn.energyLevel, isNull);
      expect(checkIn.stressLevel, isNull);
      expect(checkIn.hungerLevel, isNull);
      expect(checkIn.digestionLevel, isNull);
      expect(checkIn.nutritionCompliance, isNull);
      expect(checkIn.clientNotes, isNull);
      expect(checkIn.trainerResponse, isNull);
      expect(checkIn.reviewedAt, isNull);
      expect(checkIn.reviewedByUserId, isNull);
    });

    test('equality works correctly with same JSON input', () {
      final json = createJson();
      final c1 = CheckIn.fromJson(json);
      final c2 = CheckIn.fromJson(json);
      expect(c1, equals(c2));
    });

    test('check-ins with different ids are not equal', () {
      final c1 = CheckIn.fromJson(createJson()..['id'] = 'id-1');
      final c2 = CheckIn.fromJson(createJson()..['id'] = 'id-2');
      expect(c1, isNot(equals(c2)));
    });

    test('toJson roundtrip produces matching data', () {
      final json = createJson();
      final checkIn = CheckIn.fromJson(json);
      final output = checkIn.toJson();
      expect(output['id'], json['id']);
      expect(output['client_id'], json['client_id']);
      expect(output['status'], json['status']);
      expect(output['date'], json['date']);
    });

    test('hashCode is consistent', () {
      final json = createJson();
      final c1 = CheckIn.fromJson(json);
      final c2 = CheckIn.fromJson(json);
      expect(c1.hashCode, equals(c2.hashCode));
    });
  });
}
