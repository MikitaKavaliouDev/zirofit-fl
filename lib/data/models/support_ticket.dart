import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/support_ticket_category.dart';

class SupportTicket {
  final String id;
  final String userId;
  final SupportTicketCategory category;
  final String message;
  final String? appVersion;
  final String? osVersion;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.category,
    required this.message,
    this.appVersion,
    this.osVersion,
    this.status = 'OPEN',
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      SupportTicket(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        category: SupportTicketCategory.fromJson(
            json['category'] as String),
        message: json['message'] as String,
        appVersion: json['app_version'] as String?,
        osVersion: json['os_version'] as String?,
        status: (json['status'] as String?) ?? 'OPEN',
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category': category.toJson(),
        'message': message,
        'app_version': appVersion,
        'os_version': osVersion,
        'status': status,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'SupportTicket(id: $id, userId: $userId, '
      'category: $category, message: $message, '
      'appVersion: $appVersion, osVersion: $osVersion, '
      'status: $status, createdAt: $createdAt, '
      'updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportTicket &&
          id == other.id &&
          userId == other.userId &&
          category == other.category &&
          message == other.message &&
          appVersion == other.appVersion &&
          osVersion == other.osVersion &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        category,
        message,
        appVersion,
        osVersion,
        status,
        createdAt,
        updatedAt,
      );
}
