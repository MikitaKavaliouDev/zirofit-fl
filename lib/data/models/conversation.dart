import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Conversation {
  final String id;
  final String trainerId;
  final String clientId;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      Conversation(
        id: json['id'] as String,
        trainerId: json['trainer_id'] as String,
        clientId: json['client_id'] as String,
        lastMessageAt:
            dateTimeFromJson(json['last_message_at'] as int),
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainer_id': trainerId,
        'client_id': clientId,
        'last_message_at': dateTimeToJson(lastMessageAt),
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'Conversation(id: $id, trainerId: $trainerId, '
      'clientId: $clientId, lastMessageAt: $lastMessageAt, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          id == other.id &&
          trainerId == other.trainerId &&
          clientId == other.clientId &&
          lastMessageAt == other.lastMessageAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        trainerId,
        clientId,
        lastMessageAt,
        createdAt,
        updatedAt,
      );
}
