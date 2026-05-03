import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/notification_model.dart';

void main() {
  group('Notification', () {
    const createdAt = 1700000000000;
    const updatedAt = 1700100000000;
    const deletedAt = 1700200000000;

    final json = {
      'id': 'notif-1',
      'user_id': 'user-1',
      'message': 'You have a new workout plan!',
      'type': 'workout_assigned',
      'read_status': true,
      'metadata': {'plan_id': 'plan-1'},
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };

    test('fromJson parses all fields correctly', () {
      final model = Notification.fromJson(json);
      expect(model.id, 'notif-1');
      expect(model.userId, 'user-1');
      expect(model.message, 'You have a new workout plan!');
      expect(model.type, 'workout_assigned');
      expect(model.readStatus, true);
      expect(model.metadata, {'plan_id': 'plan-1'});
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(createdAt));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(updatedAt));
      expect(model.deletedAt, DateTime.fromMillisecondsSinceEpoch(deletedAt));
    });

    test('toJson produces correct wire format', () {
      final model = Notification.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimal = {
        'id': 'notif-2',
        'user_id': 'user-2',
        'message': 'Welcome!',
        'type': 'system',
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
      final model = Notification.fromJson(minimal);
      expect(model.id, 'notif-2');
      expect(model.userId, 'user-2');
      expect(model.message, 'Welcome!');
      expect(model.type, 'system');
      expect(model.readStatus, false);
      expect(model.metadata, isNull);
      expect(model.deletedAt, isNull);
    });

    test('equality works correctly', () {
      final model1 = Notification.fromJson(json);
      final model2 = Notification.fromJson(json);
      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality detects different id', () {
      final model1 = Notification.fromJson({...json, 'id': 'notif-1'});
      final model2 = Notification.fromJson({...json, 'id': 'notif-2'});
      expect(model1, isNot(equals(model2)));
    });

    test('hashCode is consistent', () {
      final model = Notification.fromJson(json);
      final hashCode1 = model.hashCode;
      final hashCode2 = model.hashCode;
      expect(hashCode1, equals(hashCode2));
    });
  });
}
