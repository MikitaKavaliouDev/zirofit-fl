import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/system_error.dart';

void main() {
  group('SystemError', () {
    final json = {
      'id': 'err-1',
      'message': 'Null pointer exception',
      'stack': 'at line 42',
      'path': '/api/users',
      'method': 'GET',
      'status_code': 500,
      'user_id': 'user-1',
      'is_read': false,
      'error_type': 'RuntimeException',
      'severity': 'error',
      'metadata': {'key': 'value'},
      'created_at': 1700000000000,
      'updated_at': 1700000100000,
    };

    test('fromJson parses all fields', () {
      final error = SystemError.fromJson(json);

      expect(error.id, 'err-1');
      expect(error.message, 'Null pointer exception');
      expect(error.stack, 'at line 42');
      expect(error.path, '/api/users');
      expect(error.method, 'GET');
      expect(error.statusCode, 500);
      expect(error.userId, 'user-1');
      expect(error.isRead, false);
      expect(error.errorType, 'RuntimeException');
      expect(error.severity, 'error');
      expect(error.metadata, {'key': 'value'});
      expect(error.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(error.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000100000));
    });

    test('toJson roundtrip', () {
      final error = SystemError.fromJson(json);
      final output = error.toJson();

      expect(output['id'], 'err-1');
      expect(output['message'], 'Null pointer exception');
      expect(output['stack'], 'at line 42');
      expect(output['path'], '/api/users');
      expect(output['method'], 'GET');
      expect(output['status_code'], 500);
      expect(output['user_id'], 'user-1');
      expect(output['is_read'], false);
      expect(output['error_type'], 'RuntimeException');
      expect(output['severity'], 'error');
      expect(output['metadata'], {'key': 'value'});
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000100000);
    });

    test('fromJson handles null optionals', () {
      final minimal = {
        'id': 'err-2',
        'message': 'Not found',
        'created_at': 1700000000000,
        'updated_at': 1700000100000,
      };

      final error = SystemError.fromJson(minimal);

      expect(error.id, 'err-2');
      expect(error.stack, isNull);
      expect(error.path, isNull);
      expect(error.method, isNull);
      expect(error.statusCode, isNull);
      expect(error.userId, isNull);
      expect(error.isRead, false);
      expect(error.errorType, isNull);
      expect(error.severity, 'error');
      expect(error.metadata, isNull);
    });

    test('equality', () {
      final a = SystemError.fromJson(json);
      final b = SystemError.fromJson(json);

      expect(a, equals(b));
    });

    test('hashCode', () {
      final a = SystemError.fromJson(json);
      final b = SystemError.fromJson(json);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
