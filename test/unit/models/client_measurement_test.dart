import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';

void main() {
  group('ClientMeasurement', () {
    final json = {
      'id': 'test-id',
      'client_id': 'test-client-id',
      'measurement_date': 1699916400000,
      'weight_kg': 75.5,
      'body_fat_percentage': 15.2,
      'notes': 'Test measurement',
      'custom_metrics': [
        {'name': 'chest', 'value': 100.0}
      ],
      'created_at': 1700000000000,
      'updated_at': 1700000001000,
      'deleted_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final model = ClientMeasurement.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.clientId, 'test-client-id');
      expect(model.measurementDate, DateTime.fromMillisecondsSinceEpoch(1699916400000));
      expect(model.weightKg, 75.5);
      expect(model.bodyFatPercentage, 15.2);
      expect(model.notes, 'Test measurement');
      expect(model.customMetrics, hasLength(1));
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000001000));
      expect(model.deletedAt, isNull);
    });

    test('toJson produces correct wire format', () {
      final model = ClientMeasurement.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'id': 'test-id',
        'client_id': 'test-client-id',
      'measurement_date': 1699916400000,
        'created_at': 1700000000000,
        'updated_at': 1700000001000,
      };
      final model = ClientMeasurement.fromJson(minimalJson);
      expect(model.weightKg, isNull);
      expect(model.bodyFatPercentage, isNull);
      expect(model.notes, isNull);
      expect(model.customMetrics, isNull);
      expect(model.deletedAt, isNull);
    });

    test('equality works correctly', () {
      final model1 = ClientMeasurement.fromJson(json);
      final model2 = ClientMeasurement.fromJson(json);
      expect(model1, equals(model2));
    });

    test('hashCode is consistent', () {
      final model = ClientMeasurement.fromJson(json);
      expect(model.hashCode, equals(model.hashCode));
    });
  });
}
