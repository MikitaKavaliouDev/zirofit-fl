import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/system_setting.dart';

void main() {
  group('SystemSetting', () {
    final json = {
      'key': 'app_version',
      'value': '1.2.3',
      'description': 'Current app version',
      'updated_at': 1700000000000,
    };

    test('fromJson parses all fields', () {
      final setting = SystemSetting.fromJson(json);

      expect(setting.key, 'app_version');
      expect(setting.value, '1.2.3');
      expect(setting.description, 'Current app version');
      expect(setting.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('toJson roundtrip', () {
      final setting = SystemSetting.fromJson(json);
      final output = setting.toJson();

      expect(output['key'], 'app_version');
      expect(output['value'], '1.2.3');
      expect(output['description'], 'Current app version');
      expect(output['updated_at'], 1700000000000);
    });

    test('fromJson handles null optionals', () {
      final minimal = {
        'key': 'maintenance_mode',
        'value': 'false',
        'updated_at': 1700000000000,
      };

      final setting = SystemSetting.fromJson(minimal);

      expect(setting.key, 'maintenance_mode');
      expect(setting.value, 'false');
      expect(setting.description, isNull);
    });

    test('equality', () {
      final a = SystemSetting.fromJson(json);
      final b = SystemSetting.fromJson(json);

      expect(a, equals(b));
    });

    test('hashCode', () {
      final a = SystemSetting.fromJson(json);
      final b = SystemSetting.fromJson(json);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
