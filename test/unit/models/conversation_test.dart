import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/conversation.dart';

void main() {
  group('Conversation model', () {
    final lastMessageAt = DateTime.fromMillisecondsSinceEpoch(1700006400000);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(1700092800000);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700179200000);

    Map<String, dynamic> createJson() => {
          'id': 'conv-1',
          'trainer_id': 'trainer-1',
          'client_id': 'client-1',
          'last_message_at': 1700006400000,
          'created_at': 1700092800000,
          'updated_at': 1700179200000,
        };

    test('fromJson parses all fields correctly', () {
      final json = createJson();
      final conv = Conversation.fromJson(json);
      expect(conv.id, 'conv-1');
      expect(conv.trainerId, 'trainer-1');
      expect(conv.clientId, 'client-1');
      expect(conv.lastMessageAt, lastMessageAt);
      expect(conv.createdAt, createdAt);
      expect(conv.updatedAt, updatedAt);
    });

    test('toJson produces correct wire format', () {
      final json = createJson();
      final conv = Conversation.fromJson(json);
      final output = conv.toJson();
      expect(output['id'], 'conv-1');
      expect(output['trainer_id'], 'trainer-1');
      expect(output['client_id'], 'client-1');
      expect(output['last_message_at'], 1700006400000);
      expect(output['created_at'], 1700092800000);
      expect(output['updated_at'], 1700179200000);
      // Verify snake_case keys
      expect(output.containsKey('trainer_id'), isTrue);
      expect(output.containsKey('client_id'), isTrue);
      expect(output.containsKey('last_message_at'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      // Conversation has no optional fields; verify required-only JSON works
      final json = createJson();
      final conv = Conversation.fromJson(json);
      expect(conv.id, 'conv-1');
      expect(conv.trainerId, 'trainer-1');
      expect(conv.clientId, 'client-1');
    });

    test('equality works correctly with same JSON input', () {
      final json = createJson();
      final c1 = Conversation.fromJson(json);
      final c2 = Conversation.fromJson(json);
      expect(c1, equals(c2));
    });

    test('conversations with different ids are not equal', () {
      final c1 = Conversation.fromJson(createJson()..['id'] = 'id-1');
      final c2 = Conversation.fromJson(createJson()..['id'] = 'id-2');
      expect(c1, isNot(equals(c2)));
    });

    test('toJson roundtrip produces matching data', () {
      final json = createJson();
      final conv = Conversation.fromJson(json);
      final output = conv.toJson();
      expect(output['id'], json['id']);
      expect(output['trainer_id'], json['trainer_id']);
      expect(output['client_id'], json['client_id']);
      expect(output['last_message_at'], json['last_message_at']);
    });

    test('hashCode is consistent', () {
      final json = createJson();
      final c1 = Conversation.fromJson(json);
      final c2 = Conversation.fromJson(json);
      expect(c1.hashCode, equals(c2.hashCode));
    });
  });
}
