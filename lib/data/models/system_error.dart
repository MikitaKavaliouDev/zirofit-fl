import 'package:zirofit_fl/core/utils/json_helpers.dart';

class SystemError {
  final String id;
  final String message;
  final String? stack;
  final String? path;
  final String? method;
  final int? statusCode;
  final String? userId;
  final bool isRead;
  final String? errorType;
  final String? severity;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SystemError({
    required this.id,
    required this.message,
    this.stack,
    this.path,
    this.method,
    this.statusCode,
    this.userId,
    this.isRead = false,
    this.errorType,
    this.severity = 'error',
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SystemError.fromJson(Map<String, dynamic> json) =>
      SystemError(
        id: json['id'] as String,
        message: json['message'] as String,
        stack: json['stack'] as String?,
        path: json['path'] as String?,
        method: json['method'] as String?,
        statusCode: json['status_code'] as int?,
        userId: json['user_id'] as String?,
        isRead: (json['is_read'] as bool?) ?? false,
        errorType: json['error_type'] as String?,
        severity:
            (json['severity'] as String?) ?? 'error',
        metadata:
            json['metadata'] as Map<String, dynamic>?,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'stack': stack,
        'path': path,
        'method': method,
        'status_code': statusCode,
        'user_id': userId,
        'is_read': isRead,
        'error_type': errorType,
        'severity': severity,
        'metadata': metadata,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'SystemError(id: $id, message: $message, '
      'stack: $stack, path: $path, method: $method, '
      'statusCode: $statusCode, userId: $userId, '
      'isRead: $isRead, errorType: $errorType, '
      'severity: $severity, metadata: $metadata, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemError &&
          id == other.id &&
          message == other.message &&
          stack == other.stack &&
          path == other.path &&
          method == other.method &&
          statusCode == other.statusCode &&
          userId == other.userId &&
          isRead == other.isRead &&
          errorType == other.errorType &&
          severity == other.severity &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        message,
        stack,
        path,
        method,
        statusCode,
        userId,
        isRead,
        errorType,
        severity,
        metadata,
        createdAt,
        updatedAt,
      );
}
