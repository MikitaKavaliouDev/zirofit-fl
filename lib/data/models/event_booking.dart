import 'package:zirofit_fl/core/utils/json_helpers.dart';

class EventBooking {
  final String id;
  final String eventId;
  final String userId;
  final String status;
  final String paymentStatus;
  final double amountPaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventBooking({
    required this.id,
    required this.eventId,
    required this.userId,
    this.status = 'CONFIRMED',
    this.paymentStatus = 'FREE',
    this.amountPaid = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventBooking.fromJson(Map<String, dynamic> json) =>
      EventBooking(
        id: json['id'] as String,
        eventId: json['event_id'] as String,
        userId: json['user_id'] as String,
        status: (json['status'] as String?) ?? 'CONFIRMED',
        paymentStatus:
            (json['payment_status'] as String?) ?? 'FREE',
        amountPaid:
            (json['amount_paid'] as num?)?.toDouble() ?? 0,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_id': eventId,
        'user_id': userId,
        'status': status,
        'payment_status': paymentStatus,
        'amount_paid': amountPaid,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'EventBooking(id: $id, eventId: $eventId, '
      'userId: $userId, status: $status, '
      'paymentStatus: $paymentStatus, '
      'amountPaid: $amountPaid, createdAt: $createdAt, '
      'updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventBooking &&
          id == other.id &&
          eventId == other.eventId &&
          userId == other.userId &&
          status == other.status &&
          paymentStatus == other.paymentStatus &&
          amountPaid == other.amountPaid &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        eventId,
        userId,
        status,
        paymentStatus,
        amountPaid,
        createdAt,
        updatedAt,
      );
}
