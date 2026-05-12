import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/enums/event_status.dart';

/// Trainer info nested inside an event.
class EventTrainer {
  final String? name;
  final String? username;

  const EventTrainer({this.name, this.username});

  factory EventTrainer.fromJson(Map<String, dynamic> json) => EventTrainer(
        name: json['name'] as String?,
        username: json['username'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (username != null) 'username': username,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTrainer &&
          name == other.name &&
          username == other.username;

  @override
  int get hashCode => Object.hashAll([name, username]);

  @override
  String toString() => 'EventTrainer(name: $name, username: $username)';
}

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
  final EventTrainer? trainer;

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
    this.trainer,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: readString(json, 'id', 'id'),
        trainerId: readString(json, 'trainer_id', 'trainerId'),
        title: readString(json, 'title', 'title'),
        description: readStringOrNull(json, 'description', 'description'),
        startTime: readDateTime(json, 'start_time', 'startTime'),
        endTime: readDateTime(json, 'end_time', 'endTime'),
        locationName: readStringOrNull(json, 'location_name', 'locationName'),
        address: readStringOrNull(json, 'address', 'address'),
        city: readStringOrNull(json, 'city', 'city'),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        currency: (json['currency'] as String?) ?? 'PLN',
        capacity: (json['capacity'] as int?) ?? 20,
        enrolledCount:
            (json['enrolledCount'] as int?) ?? (json['enrolled_count'] as int?) ?? 0,
        category: readStringOrNull(json, 'category', 'category'),
        imageUrl: readStringOrNull(json, 'image_url', 'imageUrl'),
        isPromoted: readBool(json, 'is_promoted', 'isPromoted'),
        status: EventStatus.fromJson(
            json['status'] as String? ?? 'PENDING'),
        rejectionReason:
            readStringOrNull(json, 'rejection_reason', 'rejectionReason'),
        createdAt: readDateTime(json, 'created_at', 'createdAt'),
        updatedAt: readDateTime(json, 'updated_at', 'updatedAt'),
        trainer: json['trainer'] != null
            ? EventTrainer.fromJson(json['trainer'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainerId': trainerId,
        'title': title,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'locationName': locationName,
        'address': address,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'price': price,
        'currency': currency,
        'capacity': capacity,
        'enrolledCount': enrolledCount,
        'category': category,
        'imageUrl': imageUrl,
        'isPromoted': isPromoted,
        'status': status.toJson(),
        'rejectionReason': rejectionReason,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (trainer != null) 'trainer': trainer!.toJson(),
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
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'trainer: $trainer)';

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
          updatedAt == other.updatedAt &&
          trainer == other.trainer;

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
        trainer,
      ]);
}
