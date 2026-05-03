import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/client_package.dart';

void main() {
  group('ClientPackage model', () {
    final purchaseDate = DateTime.fromMillisecondsSinceEpoch(1700006400000);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(1700092800000);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700179200000);
    final deletedAt = DateTime.fromMillisecondsSinceEpoch(1700265600000);

    Map<String, dynamic> createJson() => {
          'id': 'cp-1',
          'client_id': 'client-1',
          'package_id': 'pkg-1',
          'sessions_remaining': 10,
          'purchase_date': 1700006400000,
          'created_at': 1700092800000,
          'updated_at': 1700179200000,
          'deleted_at': 1700265600000,
        };

    test('fromJson parses all fields correctly', () {
      final json = createJson();
      final cp = ClientPackage.fromJson(json);
      expect(cp.id, 'cp-1');
      expect(cp.clientId, 'client-1');
      expect(cp.packageId, 'pkg-1');
      expect(cp.sessionsRemaining, 10);
      expect(cp.purchaseDate, purchaseDate);
      expect(cp.createdAt, createdAt);
      expect(cp.updatedAt, updatedAt);
      expect(cp.deletedAt, deletedAt);
    });

    test('toJson produces correct wire format', () {
      final json = createJson();
      final cp = ClientPackage.fromJson(json);
      final output = cp.toJson();
      expect(output['id'], 'cp-1');
      expect(output['client_id'], 'client-1');
      expect(output['package_id'], 'pkg-1');
      expect(output['sessions_remaining'], 10);
      expect(output['purchase_date'], 1700006400000);
      expect(output['created_at'], 1700092800000);
      expect(output['updated_at'], 1700179200000);
      expect(output['deleted_at'], 1700265600000);
      // Verify snake_case keys
      expect(output.containsKey('client_id'), isTrue);
      expect(output.containsKey('package_id'), isTrue);
      expect(output.containsKey('sessions_remaining'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'cp-2',
        'client_id': 'client-2',
        'package_id': 'pkg-2',
        'sessions_remaining': 5,
        'purchase_date': 1700006400000,
        'created_at': 1700092800000,
        'updated_at': 1700179200000,
      };
      final cp = ClientPackage.fromJson(json);
      expect(cp.id, 'cp-2');
      expect(cp.sessionsRemaining, 5);
      expect(cp.deletedAt, isNull);
    });

    test('equality works correctly with same JSON input', () {
      final json = createJson();
      final cp1 = ClientPackage.fromJson(json);
      final cp2 = ClientPackage.fromJson(json);
      expect(cp1, equals(cp2));
    });

    test('client packages with different ids are not equal', () {
      final cp1 = ClientPackage.fromJson(createJson()..['id'] = 'id-1');
      final cp2 = ClientPackage.fromJson(createJson()..['id'] = 'id-2');
      expect(cp1, isNot(equals(cp2)));
    });

    test('toJson roundtrip produces matching data', () {
      final json = createJson();
      final cp = ClientPackage.fromJson(json);
      final output = cp.toJson();
      expect(output['id'], json['id']);
      expect(output['client_id'], json['client_id']);
      expect(output['package_id'], json['package_id']);
      expect(output['sessions_remaining'], json['sessions_remaining']);
    });

    test('hashCode is consistent', () {
      final json = createJson();
      final cp1 = ClientPackage.fromJson(json);
      final cp2 = ClientPackage.fromJson(json);
      expect(cp1.hashCode, equals(cp2.hashCode));
    });
  });
}
