/// Explore event model for marketplace API responses.
///
/// Used for featured events and event listings from the explore/discovery API.
/// This model handles the API's camelCase fields and nested objects that differ
/// from the internal Event model (which uses snake_case and epoch timestamps).
class ExploreEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? locationName;
  final String? address;
  final String? imageUrl;
  final String? categoryId;
  final String? cityId;
  final String? priceDisplay;
  final String? hostName;
  final String? hostId;
  final double price;
  final String currency;
  final int capacity;
  final int enrolledCount;
  final bool isNearCapacity;
  final double? distance;
  final ExploreEventTrainer? trainer;

  /// Alias for categoryId for widget compatibility.
  String? get category => categoryId;

  /// Alias for hostId for widget compatibility.
  String? get trainerId => hostId;

  const ExploreEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.locationName,
    this.address,
    this.imageUrl,
    this.categoryId,
    this.cityId,
    this.priceDisplay,
    this.hostName,
    this.hostId,
    this.price = 0,
    this.currency = 'USD',
    this.capacity = 20,
    this.enrolledCount = 0,
    this.isNearCapacity = false,
    this.distance,
    this.trainer,
  });

  factory ExploreEvent.fromJson(Map<String, dynamic> json) {
    return ExploreEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      locationName: json['locationName'] as String?,
      address: json['address'] as String?,
      imageUrl: json['imageUrl'] as String?,
      categoryId: json['categoryId'] as String?,
      cityId: json['cityId'] as String?,
      priceDisplay: json['priceDisplay'] as String?,
      hostName: json['hostName'] as String?,
      hostId: json['hostId'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      capacity: json['capacity'] as int? ?? 20,
      enrolledCount: json['enrolledCount'] as int? ?? 0,
      isNearCapacity: json['isNearCapacity'] as bool? ?? false,
      distance: (json['distance'] as num?)?.toDouble(),
      trainer: json['trainer'] != null
          ? ExploreEventTrainer.fromJson(
              json['trainer'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'locationName': locationName,
        'address': address,
        'imageUrl': imageUrl,
        'categoryId': categoryId,
        'cityId': cityId,
        'priceDisplay': priceDisplay,
        'hostName': hostName,
        'hostId': hostId,
        'price': price,
        'currency': currency,
        'capacity': capacity,
        'enrolledCount': enrolledCount,
        'isNearCapacity': isNearCapacity,
        'distance': distance,
        'trainer': trainer?.toJson(),
      };

  @override
  String toString() =>
      'ExploreEvent(id: $id, title: $title, startTime: $startTime, '
      'endTime: $endTime, locationName: $locationName, address: $address, '
      'imageUrl: $imageUrl, categoryId: $categoryId, cityId: $cityId, '
      'priceDisplay: $priceDisplay, hostName: $hostName, hostId: $hostId, '
      'price: $price, currency: $currency, capacity: $capacity, '
      'enrolledCount: $enrolledCount, isNearCapacity: $isNearCapacity, '
      'distance: $distance, trainer: $trainer)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExploreEvent &&
          id == other.id &&
          title == other.title &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          locationName == other.locationName &&
          address == other.address &&
          imageUrl == other.imageUrl &&
          categoryId == other.categoryId &&
          cityId == other.cityId &&
          priceDisplay == other.priceDisplay &&
          hostName == other.hostName &&
          hostId == other.hostId &&
          price == other.price &&
          currency == other.currency &&
          capacity == other.capacity &&
          enrolledCount == other.enrolledCount &&
          isNearCapacity == other.isNearCapacity &&
          distance == other.distance &&
          trainer == other.trainer;

  @override
  int get hashCode => Object.hashAll([
        id,
        title,
        startTime,
        endTime,
        locationName,
        address,
        imageUrl,
        categoryId,
        cityId,
        priceDisplay,
        hostName,
        hostId,
        price,
        currency,
        capacity,
        enrolledCount,
        isNearCapacity,
        distance,
        trainer,
      ]);
}

/// Nested trainer object within ExploreEvent.
class ExploreEventTrainer {
  final String? name;

  const ExploreEventTrainer({this.name});

  factory ExploreEventTrainer.fromJson(Map<String, dynamic> json) {
    return ExploreEventTrainer(
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'name': name};

  @override
  String toString() => 'ExploreEventTrainer(name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExploreEventTrainer && name == other.name;

  @override
  int get hashCode => Object.hashAll([name]);
}