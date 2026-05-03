import 'package:zirofit_fl/core/utils/json_helpers.dart';

class ClientResource {
  final String id;
  final String resourceId;
  final String clientId;
  final DateTime createdAt;

  const ClientResource({
    required this.id,
    required this.resourceId,
    required this.clientId,
    required this.createdAt,
  });

  factory ClientResource.fromJson(Map<String, dynamic> json) =>
      ClientResource(
        id: json['id'] as String,
        resourceId: json['resource_id'] as String,
        clientId: json['client_id'] as String,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'resource_id': resourceId,
        'client_id': clientId,
        'created_at': dateTimeToJson(createdAt),
      };

  @override
  String toString() =>
      'ClientResource(id: $id, resourceId: $resourceId, '
      'clientId: $clientId, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientResource &&
          id == other.id &&
          resourceId == other.resourceId &&
          clientId == other.clientId &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, resourceId, clientId, createdAt);
}
