import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Notification {
  final String id;
  final String userId;
  final String message;
  final String type;
  final bool readStatus;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    this.readStatus = false,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) =>
      Notification(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        message: json['message'] as String,
        type: json['type'] as String,
        readStatus: (json['read_status'] as bool?) ?? false,
        metadata:
            json['metadata'] as Map<String, dynamic>?,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(
            json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'message': message,
        'type': type,
        'read_status': readStatus,
        'metadata': metadata,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Notification(id: $id, userId: $userId, '
      'message: $message, type: $type, '
      'readStatus: $readStatus, metadata: $metadata, '
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&
          id == other.id &&
          userId == other.userId &&
          message == other.message &&
          type == other.type &&
          readStatus == other.readStatus &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        message,
        type,
        readStatus,
        metadata,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
