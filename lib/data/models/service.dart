import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Service {
  final String id;
  final String profileId;
  final String title;
  final String description;
  final double? price;
  final String? currency;
  final int? duration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Service({
    required this.id,
    required this.profileId,
    required this.title,
    required this.description,
    this.price,
    this.currency,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        price: (json['price'] as num?)?.toDouble(),
        currency: json['currency'] as String?,
        duration: json['duration'] as int?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'title': title,
        'description': description,
        'price': price,
        'currency': currency,
        'duration': duration,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Service(id: $id, profileId: $profileId, title: $title, '
      'description: $description, price: $price, currency: $currency, '
      'duration: $duration, createdAt: $createdAt, updatedAt: $updatedAt, '
      'deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service &&
          id == other.id &&
          profileId == other.profileId &&
          title == other.title &&
          description == other.description &&
          price == other.price &&
          currency == other.currency &&
          duration == other.duration &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        profileId,
        title,
        description,
        price,
        currency,
        duration,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
