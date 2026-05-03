import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/benefit.dart';

void main() {
  group('Benefit model', () {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(1700006400000);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700092800000);
    final deletedAt = DateTime.fromMillisecondsSinceEpoch(1700179200000);

    Map<String, dynamic> createJson() => {
          'id': 'benefit-1',
          'profile_id': 'profile-1',
          'icon_name': 'check-circle',
          'icon_style': 'regular',
          'title': 'Personalized Coaching',
          'description': 'One-on-one coaching sessions',
          'order_column': 1,
          'created_at': 1700006400000,
          'updated_at': 1700092800000,
          'deleted_at': 1700179200000,
        };

    test('fromJson parses all fields correctly', () {
      final json = createJson();
      final benefit = Benefit.fromJson(json);
      expect(benefit.id, 'benefit-1');
      expect(benefit.profileId, 'profile-1');
      expect(benefit.iconName, 'check-circle');
      expect(benefit.iconStyle, 'regular');
      expect(benefit.title, 'Personalized Coaching');
      expect(benefit.description, 'One-on-one coaching sessions');
      expect(benefit.orderColumn, 1);
      expect(benefit.createdAt, createdAt);
      expect(benefit.updatedAt, updatedAt);
      expect(benefit.deletedAt, deletedAt);
    });

    test('toJson produces correct wire format', () {
      final json = createJson();
      final benefit = Benefit.fromJson(json);
      final output = benefit.toJson();
      expect(output['id'], 'benefit-1');
      expect(output['profile_id'], 'profile-1');
      expect(output['icon_name'], 'check-circle');
      expect(output['icon_style'], 'regular');
      expect(output['title'], 'Personalized Coaching');
      expect(output['description'], 'One-on-one coaching sessions');
      expect(output['order_column'], 1);
      expect(output['created_at'], 1700006400000);
      expect(output['updated_at'], 1700092800000);
      expect(output['deleted_at'], 1700179200000);
      // Verify snake_case keys
      expect(output.containsKey('profile_id'), isTrue);
      expect(output.containsKey('icon_name'), isTrue);
      expect(output.containsKey('order_column'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'benefit-2',
        'profile_id': 'profile-2',
        'title': 'Nutrition Planning',
        'order_column': 0,
        'created_at': 1700006400000,
        'updated_at': 1700092800000,
      };
      final benefit = Benefit.fromJson(json);
      expect(benefit.iconName, isNull);
      expect(benefit.iconStyle, isNull);
      expect(benefit.description, isNull);
      expect(benefit.deletedAt, isNull);
    });

    test('equality works correctly with same JSON input', () {
      final json = createJson();
      final b1 = Benefit.fromJson(json);
      final b2 = Benefit.fromJson(json);
      expect(b1, equals(b2));
    });

    test('benefits with different ids are not equal', () {
      final b1 = Benefit.fromJson(createJson()..['id'] = 'id-1');
      final b2 = Benefit.fromJson(createJson()..['id'] = 'id-2');
      expect(b1, isNot(equals(b2)));
    });

    test('toJson roundtrip produces matching data', () {
      final json = createJson();
      final benefit = Benefit.fromJson(json);
      final output = benefit.toJson();
      expect(output['id'], json['id']);
      expect(output['profile_id'], json['profile_id']);
      expect(output['title'], json['title']);
      expect(output['order_column'], json['order_column']);
    });

    test('hashCode is consistent', () {
      final json = createJson();
      final b1 = Benefit.fromJson(json);
      final b2 = Benefit.fromJson(json);
      expect(b1.hashCode, equals(b2.hashCode));
    });
  });
}
