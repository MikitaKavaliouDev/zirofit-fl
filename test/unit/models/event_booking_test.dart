import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/event_booking.dart';

void main() {
  group('EventBooking', () {
    final json = {
      'id': 'test-id',
      'event_id': 'test-event-id',
      'user_id': 'test-user-id',
      'status': 'CONFIRMED',
      'payment_status': 'PAID',
      'amount_paid': 49.99,
      'created_at': 1700000000000,
      'updated_at': 1700000001000,
    };

    test('fromJson parses all fields correctly', () {
      final model = EventBooking.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.eventId, 'test-event-id');
      expect(model.userId, 'test-user-id');
      expect(model.status, 'CONFIRMED');
      expect(model.paymentStatus, 'PAID');
      expect(model.amountPaid, 49.99);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000001000));
    });

    test('toJson produces correct wire format', () {
      final model = EventBooking.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'id': 'test-id',
        'event_id': 'test-event-id',
        'user_id': 'test-user-id',
        'created_at': 1700000000000,
        'updated_at': 1700000001000,
      };
      final model = EventBooking.fromJson(minimalJson);
      expect(model.status, 'CONFIRMED');
      expect(model.paymentStatus, 'FREE');
      expect(model.amountPaid, 0);
    });

    test('equality works correctly', () {
      final model1 = EventBooking.fromJson(json);
      final model2 = EventBooking.fromJson(json);
      expect(model1, equals(model2));
    });

    test('hashCode is consistent', () {
      final model = EventBooking.fromJson(json);
      expect(model.hashCode, equals(model.hashCode));
    });
  });
}
