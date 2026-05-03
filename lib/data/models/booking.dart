import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';

class Booking {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final bool? dataSharingApproved;
  final DateTime? dataSharingApprovedAt;
  final String trainerId;
  final String? clientId;
  final String? clientName;
  final String? clientEmail;
  final String? clientNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Booking({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.status = BookingStatus.pending,
    this.dataSharingApproved,
    this.dataSharingApprovedAt,
    required this.trainerId,
    this.clientId,
    this.clientName,
    this.clientEmail,
    this.clientNotes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) =>
      Booking(
        id: json['id'] as String,
        startTime:
            dateTimeFromJson(json['start_time'] as int),
        endTime:
            dateTimeFromJson(json['end_time'] as int),
        status: BookingStatus.fromJson(
            json['status'] as String? ?? 'PENDING'),
        dataSharingApproved:
            json['data_sharing_approved'] as bool?,
        dataSharingApprovedAt: dateTimeFromJsonOrNull(
            json['data_sharing_approved_at'] as int?),
        trainerId: json['trainer_id'] as String,
        clientId: json['client_id'] as String?,
        clientName: json['client_name'] as String?,
        clientEmail: json['client_email'] as String?,
        clientNotes: json['client_notes'] as String?,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(
            json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'start_time': dateTimeToJson(startTime),
        'end_time': dateTimeToJson(endTime),
        'status': status.toJson(),
        'data_sharing_approved': dataSharingApproved,
        'data_sharing_approved_at':
            dateTimeToJson(dataSharingApprovedAt),
        'trainer_id': trainerId,
        'client_id': clientId,
        'client_name': clientName,
        'client_email': clientEmail,
        'client_notes': clientNotes,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Booking(id: $id, startTime: $startTime, '
      'endTime: $endTime, status: $status, '
      'dataSharingApproved: $dataSharingApproved, '
      'dataSharingApprovedAt: $dataSharingApprovedAt, '
      'trainerId: $trainerId, clientId: $clientId, '
      'clientName: $clientName, clientEmail: $clientEmail, '
      'clientNotes: $clientNotes, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Booking &&
          id == other.id &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          status == other.status &&
          dataSharingApproved == other.dataSharingApproved &&
          dataSharingApprovedAt ==
              other.dataSharingApprovedAt &&
          trainerId == other.trainerId &&
          clientId == other.clientId &&
          clientName == other.clientName &&
          clientEmail == other.clientEmail &&
          clientNotes == other.clientNotes &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        startTime,
        endTime,
        status,
        dataSharingApproved,
        dataSharingApprovedAt,
        trainerId,
        clientId,
        clientName,
        clientEmail,
        clientNotes,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
