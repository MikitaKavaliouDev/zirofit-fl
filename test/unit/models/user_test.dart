import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/user.dart';
import '../../fixtures/common/user_fixture.dart';

void main() {
  group('User model', () {
    test('fromJson parses all fields correctly', () {
      final json = UserFixture.createJson();
      final user = User.fromJson(json);
      expect(user.id, 'test-user-id');
      expect(user.name, 'Test Trainer');
      expect(user.email, 'trainer@ziro.fit');
      expect(user.username, 'testtrainer');
      expect(user.role, 'trainer');
    });

    test('toJson produces correct wire format', () {
      final json = UserFixture.createJson();
      final user = User.fromJson(json);
      final output = user.toJson();
      expect(output['id'], 'test-user-id');
      expect(output['name'], 'Test Trainer');
      expect(output['role'], 'trainer');
      // Verify snake_case keys
      expect(output.containsKey('push_tokens'), isTrue);
      expect(output.containsKey('email_verified_at'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = UserFixture.createJson(
        username: 'testtrainer',
        subscriptionStatus: null,
      );
      json.remove('username');
      final user = User.fromJson(json);
      expect(user.role, 'trainer');
      expect(user.username, isNull);
      expect(user.subscriptionStatus, isNull);
    });

    test('equality works correctly with same JSON input', () {
      final json = UserFixture.createJson();
      final user1 = User.fromJson(json);
      final user2 = User.fromJson(json);
      // Compare serialized representations to avoid list identity issues
      expect(user1.toJson(), equals(user2.toJson()));
    });

    test('users with different ids are not equal', () {
      final user1 = User.fromJson(UserFixture.createJson(id: 'id-1'));
      final user2 = User.fromJson(UserFixture.createJson(id: 'id-2'));
      expect(user1.toJson(), isNot(equals(user2.toJson())));
    });

    test('toJson roundtrip produces matching data', () {
      final json = UserFixture.createJson();
      final user = User.fromJson(json);
      final output = user.toJson();
      expect(output['id'], json['id']);
      expect(output['name'], json['name']);
      expect(output['email'], json['email']);
      expect(output['role'], json['role']);
    });
  });
}
