import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Testimonial {
  final String id;
  final String profileId;
  final String clientName;
  final String testimonialText;
  final int? rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Testimonial({
    required this.id,
    required this.profileId,
    required this.clientName,
    required this.testimonialText,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) => Testimonial(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        clientName: json['client_name'] as String,
        testimonialText: json['testimonial_text'] as String,
        rating: json['rating'] as int?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'client_name': clientName,
        'testimonial_text': testimonialText,
        'rating': rating,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Testimonial(id: $id, profileId: $profileId, clientName: $clientName, '
      'testimonialText: $testimonialText, rating: $rating, '
      'createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Testimonial &&
          id == other.id &&
          profileId == other.profileId &&
          clientName == other.clientName &&
          testimonialText == other.testimonialText &&
          rating == other.rating &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        profileId,
        clientName,
        testimonialText,
        rating,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
