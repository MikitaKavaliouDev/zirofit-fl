import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/location.dart';

void main() {
  group('Location', () {
    final json = {
      'id': 'test-id',
      'profile_id': 'test-profile-id',
      'address': '123 Main St, Warsaw',
      'normalized_address': '123 Main Street, Warsaw, Poland',
      'latitude': 52.2297,
      'longitude': 21.0122,
      'created_at': 1700000000000,
      'updated_at': 1700000001000,
      'deleted_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final model = Location.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.profileId, 'test-profile-id');
      expect(model.address, '123 Main St, Warsaw');
      expect(model.normalizedAddress, '123 Main Street, Warsaw, Poland');
      expect(model.latitude, 52.2297);
      expect(model.longitude, 21.0122);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000001000));
      expect(model.deletedAt, isNull);
    });

    test('toJson produces correct wire format', () {
      final model = Location.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'id': 'test-id',
        'profile_id': 'test-profile-id',
        'address': '123 Main St, Warsaw',
        'normalized_address': '123 Main Street, Warsaw, Poland',
        'created_at': 1700000000000,
        'updated_at': 1700000001000,
      };
      final model = Location.fromJson(minimalJson);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
      expect(model.deletedAt, isNull);
    });

    test('equality works correctly', () {
      final model1 = Location.fromJson(json);
      final model2 = Location.fromJson(json);
      expect(model1, equals(model2));
    });

    test('hashCode is consistent', () {
      final model = Location.fromJson(json);
      expect(model.hashCode, equals(model.hashCode));
    });
  });
}
