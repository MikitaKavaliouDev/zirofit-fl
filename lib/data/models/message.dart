import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Message {
  final String id;
  final String conversationId;
  final String? senderId;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final bool isSystemMessage;
  final String? workoutSessionId;
  final DateTime? readAt;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    this.senderId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    this.isSystemMessage = false,
    this.workoutSessionId,
    this.readAt,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      Message(
        id: json['id'] as String,
        conversationId:
            json['conversation_id'] as String,
        senderId: json['sender_id'] as String?,
        content: json['content'] as String,
        mediaUrl: json['media_url'] as String?,
        mediaType: json['media_type'] as String?,
        isSystemMessage:
            (json['is_system_message'] as bool?) ?? false,
        workoutSessionId:
            json['workout_session_id'] as String?,
        readAt: dateTimeFromJsonOrNull(
            json['read_at'] as int?),
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'is_system_message': isSystemMessage,
        'workout_session_id': workoutSessionId,
        'read_at': dateTimeToJson(readAt),
        'created_at': dateTimeToJson(createdAt),
      };

  @override
  String toString() =>
      'Message(id: $id, conversationId: $conversationId, '
      'senderId: $senderId, content: $content, '
      'mediaUrl: $mediaUrl, mediaType: $mediaType, '
      'isSystemMessage: $isSystemMessage, '
      'workoutSessionId: $workoutSessionId, readAt: $readAt, '
      'createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          id == other.id &&
          conversationId == other.conversationId &&
          senderId == other.senderId &&
          content == other.content &&
          mediaUrl == other.mediaUrl &&
          mediaType == other.mediaType &&
          isSystemMessage == other.isSystemMessage &&
          workoutSessionId == other.workoutSessionId &&
          readAt == other.readAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        conversationId,
        senderId,
        content,
        mediaUrl,
        mediaType,
        isSystemMessage,
        workoutSessionId,
        readAt,
        createdAt,
      );
}
