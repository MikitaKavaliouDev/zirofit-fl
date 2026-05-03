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
        id: json['id'] as String,
        trainerId: json['trainer_id'] as String?,
        userId: json['user_id'] as String?,
        name: json['name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        avatarPath: json['avatar_path'] as String?,
        status: (json['status'] as String?) ?? 'active',
        dateOfBirth:
            dateTimeFromJsonOrNull(json['date_of_birth'] as int?),
        goals: json['goals'] as String?,
        healthNotes: json['health_notes'] as String?,
        emergencyContactName:
            json['emergency_contact_name'] as String?,
        emergencyContactPhone:
            json['emergency_contact_phone'] as String?,
        checkInDay: json['check_in_day'] as int?,
        checkInHour: json['check_in_hour'] as int?,
        dataSharingExpiresAt: dateTimeFromJsonOrNull(
            json['data_sharing_expires_at'] as int?),
        sharingSettings:
            json['sharing_settings'] as Map<String, dynamic>?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt:
            dateTimeFromJsonOrNull(json['deleted_at'] as int?),
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
