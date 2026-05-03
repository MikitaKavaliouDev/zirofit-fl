import 'package:zirofit_fl/core/utils/json_helpers.dart';

class ClientPackage {
  final String id;
  final String clientId;
  final String packageId;
  final int sessionsRemaining;
  final DateTime purchaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ClientPackage({
    required this.id,
    required this.clientId,
    required this.packageId,
    required this.sessionsRemaining,
    required this.purchaseDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ClientPackage.fromJson(Map<String, dynamic> json) =>
      ClientPackage(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        packageId: json['package_id'] as String,
        sessionsRemaining:
            (json['sessions_remaining'] as int?) ?? 0,
        purchaseDate:
            dateTimeFromJson(json['purchase_date'] as int),
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(
            json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'package_id': packageId,
        'sessions_remaining': sessionsRemaining,
        'purchase_date': dateTimeToJson(purchaseDate),
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'ClientPackage(id: $id, clientId: $clientId, '
      'packageId: $packageId, '
      'sessionsRemaining: $sessionsRemaining, '
      'purchaseDate: $purchaseDate, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientPackage &&
          id == other.id &&
          clientId == other.clientId &&
          packageId == other.packageId &&
          sessionsRemaining == other.sessionsRemaining &&
          purchaseDate == other.purchaseDate &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        packageId,
        sessionsRemaining,
        purchaseDate,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
