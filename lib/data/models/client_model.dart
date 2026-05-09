import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Client {
  final String id;
  final String? trainerId;
  final String? userId;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarPath;
  final String status;
  final DateTime? dateOfBirth;
  final String? goals;
  final String? healthNotes;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final int? checkInDay;
  final int? checkInHour;
  final DateTime? dataSharingExpiresAt;
  final Map<String, dynamic>? sharingSettings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Client({
    required this.id,
    this.trainerId,
    this.userId,
    required this.name,
    this.email,
    this.phone,
    this.avatarPath,
    this.status = 'active',
    this.dateOfBirth,
    this.goals,
    this.healthNotes,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.checkInDay,
    this.checkInHour,
    this.dataSharingExpiresAt,
    this.sharingSettings,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: readString(json, 'id', 'id'),
        trainerId: readStringOrNull(json, 'trainer_id', 'trainerId'),
        userId: readStringOrNull(json, 'user_id', 'userId'),
        name: readString(json, 'name', 'name'),
        email: readStringOrNull(json, 'email', 'email'),
        phone: readStringOrNull(json, 'phone', 'phone'),
        avatarPath: readStringOrNull(json, 'avatar_path', 'avatarPath'),
        status: readString(json, 'status', 'status'),
        dateOfBirth: readDateTimeOrNull(json, 'date_of_birth', 'dateOfBirth'),
        goals: readStringOrNull(json, 'goals', 'goals'),
        healthNotes: readStringOrNull(json, 'health_notes', 'healthNotes'),
        emergencyContactName:
            readStringOrNull(json, 'emergency_contact_name', 'emergencyContactName'),
        emergencyContactPhone:
            readStringOrNull(json, 'emergency_contact_phone', 'emergencyContactPhone'),
        checkInDay: readIntOrNull(json, 'check_in_day', 'checkInDay'),
        checkInHour: readIntOrNull(json, 'check_in_hour', 'checkInHour'),
        dataSharingExpiresAt:
            readDateTimeOrNull(json, 'data_sharing_expires_at', 'dataSharingExpiresAt'),
        sharingSettings: (json['sharing_settings'] ?? json['sharingSettings'])
            as Map<String, dynamic>?,
        createdAt: readDateTime(json, 'created_at', 'createdAt'),
        updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
        deletedAt: readDateTimeOrNull(json, 'deleted_at', 'deletedAt'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainer_id': trainerId,
        'user_id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar_path': avatarPath,
        'status': status,
        'date_of_birth': dateOfBirth != null
            ? DateTime(dateOfBirth!.year, dateOfBirth!.month,
                    dateOfBirth!.day)
                .millisecondsSinceEpoch
            : null,
        'goals': goals,
        'health_notes': healthNotes,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'check_in_day': checkInDay,
        'check_in_hour': checkInHour,
        'data_sharing_expires_at':
            dateTimeToJson(dataSharingExpiresAt),
        'sharing_settings': sharingSettings,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Client(id: $id, trainerId: $trainerId, userId: $userId, '
      'name: $name, email: $email, phone: $phone, '
      'avatarPath: $avatarPath, status: $status, '
      'dateOfBirth: $dateOfBirth, goals: $goals, '
      'healthNotes: $healthNotes, '
      'emergencyContactName: $emergencyContactName, '
      'emergencyContactPhone: $emergencyContactPhone, '
      'checkInDay: $checkInDay, checkInHour: $checkInHour, '
      'dataSharingExpiresAt: $dataSharingExpiresAt, '
      'sharingSettings: $sharingSettings, '
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client &&
          id == other.id &&
          trainerId == other.trainerId &&
          userId == other.userId &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          avatarPath == other.avatarPath &&
          status == other.status &&
          dateOfBirth == other.dateOfBirth &&
          goals == other.goals &&
          healthNotes == other.healthNotes &&
          emergencyContactName == other.emergencyContactName &&
          emergencyContactPhone == other.emergencyContactPhone &&
          checkInDay == other.checkInDay &&
          checkInHour == other.checkInHour &&
          dataSharingExpiresAt == other.dataSharingExpiresAt &&
          sharingSettings == other.sharingSettings &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        trainerId,
        userId,
        name,
        email,
        phone,
        avatarPath,
        status,
        dateOfBirth,
        goals,
        healthNotes,
        emergencyContactName,
        emergencyContactPhone,
        checkInDay,
        checkInHour,
        dataSharingExpiresAt,
        sharingSettings,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
