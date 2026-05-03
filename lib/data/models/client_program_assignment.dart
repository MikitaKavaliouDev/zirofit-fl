import 'package:zirofit_fl/core/utils/json_helpers.dart';

class ClientProgramAssignment {
  final String id;
  final String clientId;
  final String programId;
  final DateTime startDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ClientProgramAssignment({
    required this.id,
    required this.clientId,
    required this.programId,
    required this.startDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ClientProgramAssignment.fromJson(
          Map<String, dynamic> json) =>
      ClientProgramAssignment(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        programId: json['program_id'] as String,
        startDate:
            dateTimeFromJson(json['start_date'] as int),
        isActive: (json['is_active'] as bool?) ?? true,
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
        'program_id': programId,
        'start_date': dateTimeToJson(startDate),
        'is_active': isActive,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'ClientProgramAssignment(id: $id, clientId: $clientId, '
      'programId: $programId, startDate: $startDate, '
      'isActive: $isActive, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientProgramAssignment &&
          id == other.id &&
          clientId == other.clientId &&
          programId == other.programId &&
          startDate == other.startDate &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        programId,
        startDate,
        isActive,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
