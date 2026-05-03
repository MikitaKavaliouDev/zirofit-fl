import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/event_status.dart';

class Event {
  final String id;
  final String trainerId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? locationName;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final double price;
  final String currency;
  final int capacity;
  final int enrolledCount;
  final String? category;
  final String? imageUrl;
  final bool isPromoted;
  final EventStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.trainerId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.locationName,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.price = 0,
    this.currency = 'PLN',
    this.capacity = 20,
    this.enrolledCount = 0,
    this.category,
    this.imageUrl,
    this.isPromoted = false,
    this.status = EventStatus.pending,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        trainerId: json['trainer_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        startTime:
            dateTimeFromJson(json['start_time'] as int),
        endTime:
            dateTimeFromJson(json['end_time'] as int),
        locationName: json['location_name'] as String?,
        address: json['address'] as String?,
        city: json['city'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        currency:
            (json['currency'] as String?) ?? 'PLN',
        capacity: (json['capacity'] as int?) ?? 20,
        enrolledCount:
            (json['enrolled_count'] as int?) ?? 0,
        category: json['category'] as String?,
        imageUrl: json['image_url'] as String?,
        isPromoted:
            (json['is_promoted'] as bool?) ?? false,
        status: EventStatus.fromJson(
            json['status'] as String? ?? 'PENDING'),
        rejectionReason:
            json['rejection_reason'] as String?,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainer_id': trainerId,
        'title': title,
        'description': description,
        'start_time': dateTimeToJson(startTime),
        'end_time': dateTimeToJson(endTime),
        'location_name': locationName,
        'address': address,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'price': price,
        'currency': currency,
        'capacity': capacity,
        'enrolled_count': enrolledCount,
        'category': category,
        'image_url': imageUrl,
        'is_promoted': isPromoted,
        'status': status.toJson(),
        'rejection_reason': rejectionReason,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  @override
  String toString() =>
      'Event(id: $id, trainerId: $trainerId, title: $title, '
      'description: $description, startTime: $startTime, '
      'endTime: $endTime, locationName: $locationName, '
      'address: $address, city: $city, latitude: $latitude, '
      'longitude: $longitude, price: $price, '
      'currency: $currency, capacity: $capacity, '
      'enrolledCount: $enrolledCount, category: $category, '
      'imageUrl: $imageUrl, isPromoted: $isPromoted, '
      'status: $status, rejectionReason: $rejectionReason, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          id == other.id &&
          trainerId == other.trainerId &&
          title == other.title &&
          description == other.description &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          locationName == other.locationName &&
          address == other.address &&
          city == other.city &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          price == other.price &&
          currency == other.currency &&
          capacity == other.capacity &&
          enrolledCount == other.enrolledCount &&
          category == other.category &&
          imageUrl == other.imageUrl &&
          isPromoted == other.isPromoted &&
          status == other.status &&
          rejectionReason == other.rejectionReason &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id,
        trainerId,
        title,
        description,
        startTime,
        endTime,
        locationName,
        address,
        city,
        latitude,
        longitude,
        price,
        currency,
        capacity,
        enrolledCount,
        category,
        imageUrl,
        isPromoted,
        status,
        rejectionReason,
        createdAt,
        updatedAt,
      ]);
}
