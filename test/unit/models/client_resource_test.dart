import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/client_resource.dart';

void main() {
  group('ClientResource model', () {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(1700006400000);

    Map<String, dynamic> createJson() => {
          'id': 'cr-1',
          'resource_id': 'res-1',
          'client_id': 'client-1',
          'created_at': 1700006400000,
        };

    test('fromJson parses all fields correctly', () {
      final json = createJson();
      final cr = ClientResource.fromJson(json);
      expect(cr.id, 'cr-1');
      expect(cr.resourceId, 'res-1');
      expect(cr.clientId, 'client-1');
      expect(cr.createdAt, createdAt);
    });

    test('toJson produces correct wire format', () {
      final json = createJson();
      final cr = ClientResource.fromJson(json);
      final output = cr.toJson();
      expect(output['id'], 'cr-1');
      expect(output['resource_id'], 'res-1');
      expect(output['client_id'], 'client-1');
      expect(output['created_at'], 1700006400000);
      // Verify snake_case keys
      expect(output.containsKey('resource_id'), isTrue);
      expect(output.containsKey('client_id'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      // ClientResource has no optional fields; verify required-only JSON works
      final json = createJson();
      final cr = ClientResource.fromJson(json);
      expect(cr.id, 'cr-1');
      expect(cr.resourceId, 'res-1');
      expect(cr.clientId, 'client-1');
    });

    test('equality works correctly with same JSON input', () {
      final json = createJson();
      final cr1 = ClientResource.fromJson(json);
      final cr2 = ClientResource.fromJson(json);
      expect(cr1, equals(cr2));
    });

    test('client resources with different ids are not equal', () {
      final cr1 = ClientResource.fromJson(createJson()..['id'] = 'id-1');
      final cr2 = ClientResource.fromJson(createJson()..['id'] = 'id-2');
      expect(cr1, isNot(equals(cr2)));
    });

    test('toJson roundtrip produces matching data', () {
      final json = createJson();
      final cr = ClientResource.fromJson(json);
      final output = cr.toJson();
      expect(output['id'], json['id']);
      expect(output['resource_id'], json['resource_id']);
      expect(output['client_id'], json['client_id']);
      expect(output['created_at'], json['created_at']);
    });

    test('hashCode is consistent', () {
      final json = createJson();
      final cr1 = ClientResource.fromJson(json);
      final cr2 = ClientResource.fromJson(json);
      expect(cr1.hashCode, equals(cr2.hashCode));
    });
  });
}
