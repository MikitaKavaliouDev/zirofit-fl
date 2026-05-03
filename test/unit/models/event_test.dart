import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/data/models/enums/event_status.dart';

void main() {
  group('Event', () {
    final json = {
      'id': 'test-id',
      'trainer_id': 'test-trainer-id',
      'title': 'Test Event',
      'description': 'An amazing test event',
      'start_time': 1700000000000,
      'end_time': 1700003600000,
      'location_name': 'Test Gym',
      'address': '123 Test St',
      'city': 'Warsaw',
      'latitude': 52.2297,
      'longitude': 21.0122,
      'price': 99.99,
      'currency': 'PLN',
      'capacity': 30,
      'enrolled_count': 15,
      'category': 'fitness',
      'image_url': 'https://example.com/event.jpg',
      'is_promoted': true,
      'status': 'APPROVED',
      'rejection_reason': null,
      'created_at': 1700000000000,
      'updated_at': 1700000001000,
    };

    test('fromJson parses all fields correctly', () {
      final model = Event.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.trainerId, 'test-trainer-id');
      expect(model.title, 'Test Event');
      expect(model.description, 'An amazing test event');
      expect(model.startTime, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.endTime, DateTime.fromMillisecondsSinceEpoch(1700003600000));
      expect(model.locationName, 'Test Gym');
      expect(model.address, '123 Test St');
      expect(model.city, 'Warsaw');
      expect(model.latitude, 52.2297);
      expect(model.longitude, 21.0122);
      expect(model.price, 99.99);
      expect(model.currency, 'PLN');
      expect(model.capacity, 30);
      expect(model.enrolledCount, 15);
      expect(model.category, 'fitness');
      expect(model.imageUrl, 'https://example.com/event.jpg');
      expect(model.isPromoted, true);
      expect(model.status, EventStatus.approved);
      expect(model.rejectionReason, isNull);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000001000));
    });

    test('toJson produces correct wire format', () {
      final model = Event.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'id': 'test-id',
        'trainer_id': 'test-trainer-id',
        'title': 'Test Event',
        'start_time': 1700000000000,
        'end_time': 1700003600000,
        'created_at': 1700000000000,
        'updated_at': 1700000001000,
      };
      final model = Event.fromJson(minimalJson);
      expect(model.description, isNull);
      expect(model.locationName, isNull);
      expect(model.address, isNull);
      expect(model.city, isNull);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
      expect(model.category, isNull);
      expect(model.imageUrl, isNull);
      expect(model.rejectionReason, isNull);
      expect(model.price, 0);
      expect(model.currency, 'PLN');
      expect(model.capacity, 20);
      expect(model.enrolledCount, 0);
      expect(model.isPromoted, false);
      expect(model.status, EventStatus.pending);
    });

    test('equality works correctly', () {
      final model1 = Event.fromJson(json);
      final model2 = Event.fromJson(json);
      expect(model1, equals(model2));
    });

    test('hashCode is consistent', () {
      final model = Event.fromJson(json);
      expect(model.hashCode, equals(model.hashCode));
    });
  });
}
