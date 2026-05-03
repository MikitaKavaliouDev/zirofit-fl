import 'package:zirofit_fl/core/utils/json_helpers.dart';

class ClientProgressPhoto {
  final String id;
  final String clientId;
  final DateTime photoDate;
  final String imagePath;
  final String? caption;
  final String? checkInId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ClientProgressPhoto({
    required this.id,
    required this.clientId,
    required this.photoDate,
    required this.imagePath,
    this.caption,
    this.checkInId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ClientProgressPhoto.fromJson(Map<String, dynamic> json) =>
      ClientProgressPhoto(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        photoDate: dateTimeFromJson(json['photo_date'] as int),
        imagePath: json['image_path'] as String,
        caption: json['caption'] as String?,
        checkInId: json['check_in_id'] as String?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt:
            dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'photo_date': DateTime(
                photoDate.year, photoDate.month, photoDate.day)
            .millisecondsSinceEpoch,
        'image_path': imagePath,
        'caption': caption,
        'check_in_id': checkInId,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'ClientProgressPhoto(id: $id, clientId: $clientId, '
      'photoDate: $photoDate, imagePath: $imagePath, '
      'caption: $caption, checkInId: $checkInId, '
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientProgressPhoto &&
          id == other.id &&
          clientId == other.clientId &&
          photoDate == other.photoDate &&
          imagePath == other.imagePath &&
          caption == other.caption &&
          checkInId == other.checkInId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        photoDate,
        imagePath,
        caption,
        checkInId,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
