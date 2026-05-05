import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/utils/json_helpers.dart';

void main() {
  // ===========================================================================
  // dateTimeToJson
  // ===========================================================================
  group('dateTimeToJson', () {
    test('converts DateTime to Unix ms int', () {
      final dt = DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000);
      expect(dateTimeToJson(dt), 1_700_000_000_000);
    });

    test('returns null for null input', () {
      expect(dateTimeToJson(null), isNull);
    });

    test('preserves millisecond precision', () {
      final dt = DateTime.fromMillisecondsSinceEpoch(1_700_000_000_123);
      expect(dateTimeToJson(dt), 1_700_000_000_123);
    });

    test('handles epoch zero', () {
      final dt = DateTime.fromMillisecondsSinceEpoch(0);
      expect(dateTimeToJson(dt), 0);
    });
  });

  // ===========================================================================
  // dateTimeFromJson
  // ===========================================================================
  group('dateTimeFromJson', () {
    test('converts Unix ms int to DateTime', () {
      final result = dateTimeFromJson(1_700_000_000_000);
      expect(result, DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000));
    });

    test('handles epoch zero', () {
      final result = dateTimeFromJson(0);
      expect(result, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('handles large future timestamps', () {
      final result = dateTimeFromJson(4_100_000_000_000);
      expect(result, DateTime.fromMillisecondsSinceEpoch(4_100_000_000_000));
    });
  });

  // ===========================================================================
  // dateTimeFromJsonOrNull
  // ===========================================================================
  group('dateTimeFromJsonOrNull', () {
    test('converts non-null int to DateTime', () {
      final result = dateTimeFromJsonOrNull(1_700_000_000_000);
      expect(result, DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000));
    });

    test('returns null for null input', () {
      expect(dateTimeFromJsonOrNull(null), isNull);
    });

    test('handles zero', () {
      final result = dateTimeFromJsonOrNull(0);
      expect(result, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  // ===========================================================================
  // readString
  // ===========================================================================
  group('readString', () {
    test('reads from snake_case key', () {
      final json = {'user_name': 'alice', 'userName': 'bob'};
      expect(readString(json, 'user_name', 'userName'), 'alice');
    });

    test('reads from camelCase key when snake_case is absent', () {
      final json = {'userName': 'bob'};
      expect(readString(json, 'user_name', 'userName'), 'bob');
    });

    test('snake_case key takes priority when both present', () {
      final json = {'user_name': 'snake', 'userName': 'camel'};
      expect(readString(json, 'user_name', 'userName'), 'snake');
    });

    test('throws ArgumentError when value is null', () {
      final json = <String, dynamic>{};
      expect(
        () => readString(json, 'user_name', 'userName'),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when value is wrong type (int)', () {
      final json = {'user_name': 42};
      expect(
        () => readString(json, 'user_name', 'userName'),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when value is wrong type (bool)', () {
      final json = {'user_name': true};
      expect(
        () => readString(json, 'user_name', 'userName'),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when value is a List', () {
      final json = {'user_name': <String>['a']};
      expect(
        () => readString(json, 'user_name', 'userName'),
        throwsArgumentError,
      );
    });

    test('ArgumentError message includes key names and type', () {
      final json = {'user_name': 42};
      expect(
        () => readString(json, 'user_name', 'userName'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('user_name'),
          ),
        ),
      );
    });
  });

  // ===========================================================================
  // readStringOrNull
  // ===========================================================================
  group('readStringOrNull', () {
    test('reads from snake_case key', () {
      final json = {'user_name': 'alice', 'userName': 'bob'};
      expect(readStringOrNull(json, 'user_name', 'userName'), 'alice');
    });

    test('reads from camelCase key when snake_case is absent', () {
      final json = {'userName': 'bob'};
      expect(readStringOrNull(json, 'user_name', 'userName'), 'bob');
    });

    test('snake_case key takes priority when both present', () {
      final json = {'user_name': 'snake', 'userName': 'camel'};
      expect(readStringOrNull(json, 'user_name', 'userName'), 'snake');
    });

    test('returns null when key is absent', () {
      final json = <String, dynamic>{};
      expect(readStringOrNull(json, 'user_name', 'userName'), isNull);
    });

    test('returns null when value is wrong type (int)', () {
      final json = {'user_name': 42};
      expect(readStringOrNull(json, 'user_name', 'userName'), isNull);
    });

    test('returns null when value is wrong type (bool)', () {
      final json = {'user_name': true};
      expect(readStringOrNull(json, 'user_name', 'userName'), isNull);
    });

    test('returns null when value is null explicitly', () {
      final json = {'user_name': null, 'userName': null};
      expect(readStringOrNull(json, 'user_name', 'userName'), isNull);
    });
  });

  // ===========================================================================
  // readIntOrNull
  // ===========================================================================
  group('readIntOrNull', () {
    test('reads from snake_case key', () {
      final json = {'age': 30, 'age_': 25};
      // Note: the keys are 'age' for snake and 'age_' for camel in this test
      // to be explicit about resolution order
      expect(readIntOrNull(json, 'age', 'not_present'), 30);
    });

    test('reads from camelCase key when snake_case is absent', () {
      final json = {'userAge': 25};
      expect(readIntOrNull(json, 'user_age', 'userAge'), 25);
    });

    test('snake_case key takes priority when both present', () {
      final json = {'item_count': 5, 'itemCount': 3};
      expect(readIntOrNull(json, 'item_count', 'itemCount'), 5);
    });

    test('returns null when key is absent', () {
      final json = <String, dynamic>{};
      expect(readIntOrNull(json, 'count', 'count'), isNull);
    });

    test('returns null when value is wrong type (String)', () {
      final json = {'count': 'hello'};
      expect(readIntOrNull(json, 'count', 'count'), isNull);
    });

    test('returns null when value is wrong type (bool)', () {
      final json = {'count': true};
      expect(readIntOrNull(json, 'count', 'count'), isNull);
    });

    test('returns null when value is null explicitly', () {
      final json = {'count': null};
      expect(readIntOrNull(json, 'count', 'count'), isNull);
    });

    test('reads zero as valid int', () {
      final json = {'count': 0};
      expect(readIntOrNull(json, 'count', 'count'), 0);
    });

    test('reads negative int', () {
      final json = {'offset': -5};
      expect(readIntOrNull(json, 'offset', 'offset'), -5);
    });
  });

  // ===========================================================================
  // readBool
  // ===========================================================================
  group('readBool', () {
    test('reads from snake_case key', () {
      final json = {'is_active': true, 'isActive': false};
      expect(readBool(json, 'is_active', 'isActive'), true);
    });

    test('reads from camelCase key when snake_case is absent', () {
      final json = {'isActive': true};
      expect(readBool(json, 'is_active', 'isActive'), true);
    });

    test('snake_case key takes priority when both present', () {
      final json = {'is_active': false, 'isActive': true};
      expect(readBool(json, 'is_active', 'isActive'), false);
    });

    test('returns fallback (default false) when key is absent', () {
      final json = <String, dynamic>{};
      expect(readBool(json, 'is_active', 'isActive'), false);
    });

    test('returns custom fallback when key is absent', () {
      final json = <String, dynamic>{};
      expect(readBool(json, 'is_active', 'isActive', fallback: true), true);
    });

    test('returns fallback when value is wrong type (String)', () {
      final json = {'is_active': 'yes'};
      expect(readBool(json, 'is_active', 'isActive'), false);
    });

    test('returns fallback when value is wrong type (int)', () {
      final json = {'is_active': 1};
      expect(readBool(json, 'is_active', 'isActive'), false);
    });

    test('returns fallback when value is null explicitly', () {
      final json = {'is_active': null};
      expect(readBool(json, 'is_active', 'isActive'), false);
    });

    test('reads false correctly', () {
      final json = {'is_active': false};
      expect(readBool(json, 'is_active', 'isActive'), false);
    });
  });

  // ===========================================================================
  // readDateTime
  // ===========================================================================
  group('readDateTime', () {
    test('parses int (Unix ms) from snake_case key', () {
      final json = {'created_at': 1_700_000_000_000, 'createdAt': 42};
      expect(
        readDateTime(json, 'created_at', 'createdAt'),
        DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
      );
    });

    test('parses String (ISO 8601) from camelCase key', () {
      final json = {'createdAt': '2024-11-15T10:30:00.000'};
      expect(
        readDateTime(json, 'created_at', 'createdAt'),
        DateTime(2024, 11, 15, 10, 30),
      );
    });

    test('parses String (ISO 8601) from snake_case key', () {
      final json = {'created_at': '2024-06-01T00:00:00.000'};
      expect(
        readDateTime(json, 'created_at', 'createdAt'),
        DateTime(2024, 6, 1),
      );
    });

    test('snake_case key takes priority when both present', () {
      final json = {
        'created_at': 1_600_000_000_000,
        'createdAt': '2024-01-01T00:00:00.000',
      };
      expect(
        readDateTime(json, 'created_at', 'createdAt'),
        DateTime.fromMillisecondsSinceEpoch(1_600_000_000_000),
      );
    });

    test('parses ISO string without milliseconds', () {
      final json = {'createdAt': '2024-12-25T08:15:30'};
      expect(
        readDateTime(json, 'created_at', 'createdAt'),
        DateTime(2024, 12, 25, 8, 15, 30),
      );
    });

    test('parses ISO string with timezone offset', () {
      final json = {'createdAt': '2024-01-01T00:00:00.000Z'};
      expect(
        readDateTime(json, 'created_at', 'createdAt'),
        DateTime.utc(2024, 1, 1),
      );
    });

    test('throws ArgumentError when value is bool', () {
      final json = {'created_at': true};
      expect(
        () => readDateTime(json, 'created_at', 'createdAt'),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when value is null', () {
      final json = <String, dynamic>{};
      expect(
        () => readDateTime(json, 'created_at', 'createdAt'),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when value is a List', () {
      final json = {'created_at': <int>[1, 2, 3]};
      expect(
        () => readDateTime(json, 'created_at', 'createdAt'),
        throwsArgumentError,
      );
    });

    test('throws FormatException when String is not valid ISO 8601', () {
      final json = {'createdAt': 'not-a-date'};
      expect(
        () => readDateTime(json, 'created_at', 'createdAt'),
        throwsFormatException,
      );
    });

    test('ArgumentError message includes key names and type', () {
      final json = {'created_at': true};
      expect(
        () => readDateTime(json, 'created_at', 'createdAt'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('created_at'),
          ),
        ),
      );
    });
  });

  // ===========================================================================
  // readDateTimeOrNull
  // ===========================================================================
  group('readDateTimeOrNull', () {
    test('parses int (Unix ms) from snake_case key', () {
      final json = {'created_at': 1_700_000_000_000, 'createdAt': 42};
      expect(
        readDateTimeOrNull(json, 'created_at', 'createdAt'),
        DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
      );
    });

    test('parses String (ISO 8601) from camelCase key', () {
      final json = {'createdAt': '2024-11-15T10:30:00.000'};
      expect(
        readDateTimeOrNull(json, 'created_at', 'createdAt'),
        DateTime(2024, 11, 15, 10, 30),
      );
    });

    test('snake_case key takes priority when both present', () {
      final json = {
        'created_at': 1_600_000_000_000,
        'createdAt': '2024-01-01T00:00:00.000',
      };
      expect(
        readDateTimeOrNull(json, 'created_at', 'createdAt'),
        DateTime.fromMillisecondsSinceEpoch(1_600_000_000_000),
      );
    });

    test('returns null when key is absent', () {
      final json = <String, dynamic>{};
      expect(readDateTimeOrNull(json, 'created_at', 'createdAt'), isNull);
    });

    test('returns null when value is bool', () {
      final json = {'created_at': true};
      expect(readDateTimeOrNull(json, 'created_at', 'createdAt'), isNull);
    });

    test('returns null when value is a List', () {
      final json = {'created_at': <int>[1, 2, 3]};
      expect(readDateTimeOrNull(json, 'created_at', 'createdAt'), isNull);
    });

    test('returns null when value is null explicitly', () {
      final json = {'created_at': null};
      expect(readDateTimeOrNull(json, 'created_at', 'createdAt'), isNull);
    });

    test('throws FormatException for invalid ISO 8601 string', () {
      final json = {'createdAt': 'not-a-date'};
      expect(
        () => readDateTimeOrNull(json, 'created_at', 'createdAt'),
        throwsFormatException,
      );
    });
  });

  // ===========================================================================
  // listFromJson
  // ===========================================================================
  group('listFromJson', () {
    test('converts List<dynamic> to List<T> using fromJson callback', () {
      final json = <Map<String, dynamic>>[
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
      ];
      final result = listFromJson(
        json,
        (m) => '${m['name']} (${m['id']})',
      );
      expect(result, ['Alice (1)', 'Bob (2)']);
    });

    test('returns empty list when input is null', () {
      final result = listFromJson<int?>(null, (e) => e as int);
      expect(result, isEmpty);
    });

    test('returns empty list when input is empty list', () {
      final result = listFromJson<String>(<String>[], (e) => e as String);
      expect(result, isEmpty);
    });

    test('preserves order of elements', () {
      final json = [3, 1, 2];
      final result = listFromJson(json, (e) => (e as int) * 10);
      expect(result, [30, 10, 20]);
    });

    test('works with nullable element types', () {
      final json = ['a', null, 'b'];
      final result = listFromJson<String?>(json, (e) => e as String?);
      expect(result, ['a', null, 'b']);
    });
  });

  // ===========================================================================
  // mapFromJson
  // ===========================================================================
  group('mapFromJson', () {
    test('extracts nested map by key', () {
      final json = <String, dynamic>{
        'profile': {'name': 'Alice', 'age': 30},
      };
      final result = mapFromJson(json, 'profile');
      expect(result, {'name': 'Alice', 'age': 30});
    });

    test('returns null when key is absent', () {
      final json = <String, dynamic>{'other': 'data'};
      expect(mapFromJson(json, 'profile'), isNull);
    });

    test('returns null when input json is null', () {
      expect(mapFromJson(null, 'profile'), isNull);
    });

    test('throws TypeError when value is not a Map (String)', () {
      final json = <String, dynamic>{'profile': 'not-a-map'};
      expect(
        () => mapFromJson(json, 'profile'),
        throwsA(isA<TypeError>()),
      );
    });

    test('throws TypeError when value is an int', () {
      final json = <String, dynamic>{'profile': 42};
      expect(
        () => mapFromJson(json, 'profile'),
        throwsA(isA<TypeError>()),
      );
    });

    test('extracts nested map with dynamic values', () {
      final json = <String, dynamic>{
        'settings': {'theme': 'dark', 'notifications': true, 'count': 5},
      };
      final result = mapFromJson(json, 'settings');
      expect(result, {'theme': 'dark', 'notifications': true, 'count': 5});
    });

    test('returns null when value is an empty map (empty map is still a Map)', () {
      final json = <String, dynamic>{'data': <String, dynamic>{}};
      final result = mapFromJson(json, 'data');
      expect(result, <String, dynamic>{});
    });
  });
}
