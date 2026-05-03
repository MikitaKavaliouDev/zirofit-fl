import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/message.dart';

void main() {
  group('Message', () {
    const createdAt = 1700000000000;
    const readAt = 1700400000000;

    final json = {
      'id': 'msg-1',
      'conversation_id': 'conv-1',
      'sender_id': 'user-1',
      'content': 'Hello, how are you?',
      'media_url': 'https://example.com/image.jpg',
      'media_type': 'image',
      'is_system_message': true,
      'workout_session_id': 'ws-1',
      'read_at': readAt,
      'created_at': createdAt,
    };

    test('fromJson parses all fields correctly', () {
      final model = Message.fromJson(json);
      expect(model.id, 'msg-1');
      expect(model.conversationId, 'conv-1');
      expect(model.senderId, 'user-1');
      expect(model.content, 'Hello, how are you?');
      expect(model.mediaUrl, 'https://example.com/image.jpg');
      expect(model.mediaType, 'image');
      expect(model.isSystemMessage, true);
      expect(model.workoutSessionId, 'ws-1');
      expect(model.readAt, DateTime.fromMillisecondsSinceEpoch(readAt));
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(createdAt));
    });

    test('toJson produces correct wire format', () {
      final model = Message.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimal = {
        'id': 'msg-2',
        'conversation_id': 'conv-2',
        'content': 'System message',
        'created_at': createdAt,
      };
      final model = Message.fromJson(minimal);
      expect(model.id, 'msg-2');
      expect(model.conversationId, 'conv-2');
      expect(model.content, 'System message');
      expect(model.senderId, isNull);
      expect(model.mediaUrl, isNull);
      expect(model.mediaType, isNull);
      expect(model.isSystemMessage, false);
      expect(model.workoutSessionId, isNull);
      expect(model.readAt, isNull);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(createdAt));
    });

    test('equality works correctly', () {
      final model1 = Message.fromJson(json);
      final model2 = Message.fromJson(json);
      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality detects different id', () {
      final model1 = Message.fromJson({...json, 'id': 'msg-1'});
      final model2 = Message.fromJson({...json, 'id': 'msg-2'});
      expect(model1, isNot(equals(model2)));
    });

    test('hashCode is consistent', () {
      final model = Message.fromJson(json);
      final hashCode1 = model.hashCode;
      final hashCode2 = model.hashCode;
      expect(hashCode1, equals(hashCode2));
    });
  });
}
