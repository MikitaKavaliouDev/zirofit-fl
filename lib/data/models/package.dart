import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Package {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int numberOfSessions;
  final bool isActive;
  final String stripeProductId;
  final String stripePriceId;
  final String trainerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Package({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.numberOfSessions,
    this.isActive = true,
    required this.stripeProductId,
    required this.stripePriceId,
    required this.trainerId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Package.fromJson(Map<String, dynamic> json) =>
      Package(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price:
            (json['price'] as num?)?.toDouble() ?? 0,
        numberOfSessions:
            (json['number_of_sessions'] as int?) ?? 0,
        isActive: (json['is_active'] as bool?) ?? true,
        stripeProductId:
            json['stripe_product_id'] as String,
        stripePriceId:
            json['stripe_price_id'] as String,
        trainerId: json['trainer_id'] as String,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(
            json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'number_of_sessions': numberOfSessions,
        'is_active': isActive,
        'stripe_product_id': stripeProductId,
        'stripe_price_id': stripePriceId,
        'trainer_id': trainerId,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Package(id: $id, name: $name, '
      'description: $description, price: $price, '
      'numberOfSessions: $numberOfSessions, '
      'isActive: $isActive, '
      'stripeProductId: $stripeProductId, '
      'stripePriceId: $stripePriceId, '
      'trainerId: $trainerId, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Package &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          price == other.price &&
          numberOfSessions == other.numberOfSessions &&
          isActive == other.isActive &&
          stripeProductId == other.stripeProductId &&
          stripePriceId == other.stripePriceId &&
          trainerId == other.trainerId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        price,
        numberOfSessions,
        isActive,
        stripeProductId,
        stripePriceId,
        trainerId,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
