import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';

void main() {
  group('Booking model', () {
    final baseJson = <String, dynamic>{
      'id': 'booking-1',
      'start_time': 1700000000000,
      'end_time': 1700003600000,
      'status': 'CONFIRMED',
      'data_sharing_approved': true,
      'data_sharing_approved_at': 1700000000000,
      'trainer_id': 'trainer-1',
      'client_id': 'client-1',
      'client_name': 'John Doe',
      'client_email': 'john@example.com',
      'client_notes': 'Prefers morning sessions',
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
      'deleted_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final booking = Booking.fromJson(baseJson);

      expect(booking.id, 'booking-1');
      expect(booking.startTime, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(booking.endTime, DateTime.fromMillisecondsSinceEpoch(1700003600000));
      expect(booking.status, BookingStatus.confirmed);
      expect(booking.dataSharingApproved, isTrue);
      expect(booking.dataSharingApprovedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(booking.trainerId, 'trainer-1');
      expect(booking.clientId, 'client-1');
      expect(booking.clientName, 'John Doe');
      expect(booking.clientEmail, 'john@example.com');
      expect(booking.clientNotes, 'Prefers morning sessions');
      expect(booking.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(booking.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(booking.deletedAt, isNull);
    });

    test('toJson produces correct wire format', () {
      final booking = Booking.fromJson(baseJson);
      final output = booking.toJson();

      expect(output['id'], 'booking-1');
      expect(output['start_time'], 1700000000000);
      expect(output['end_time'], 1700003600000);
      expect(output['status'], 'CONFIRMED');
      expect(output['data_sharing_approved'], isTrue);
      expect(output['data_sharing_approved_at'], 1700000000000);
      expect(output['trainer_id'], 'trainer-1');
      expect(output['client_id'], 'client-1');
      expect(output['client_name'], 'John Doe');
      expect(output['client_email'], 'john@example.com');
      expect(output['client_notes'], 'Prefers morning sessions');
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000000000);
      expect(output.containsKey('deleted_at'), isTrue);
      expect(output['deleted_at'], isNull);
    });

    test('fromJson uses default status when status is null', () {
      final json = Map<String, dynamic>.from(baseJson);
      json.remove('status');
      final booking = Booking.fromJson(json);

      expect(booking.status, BookingStatus.pending);
    });

    test('fromJson uses default status when status is PENDING string', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['status'] = 'PENDING';
      final booking = Booking.fromJson(json);

      expect(booking.status, BookingStatus.pending);
    });

    test('fromJson handles null optional fields', () {
      final json = Map<String, dynamic>.from(baseJson);
      json.remove('client_name');
      json.remove('client_email');
      json.remove('client_notes');
      json['data_sharing_approved'] = null;
      json['data_sharing_approved_at'] = null;
      json['deleted_at'] = null;

      final booking = Booking.fromJson(json);

      expect(booking.clientName, isNull);
      expect(booking.clientEmail, isNull);
      expect(booking.clientNotes, isNull);
      expect(booking.dataSharingApproved, isNull);
      expect(booking.dataSharingApprovedAt, isNull);
      expect(booking.deletedAt, isNull);
    });

    test('equality works with same data', () {
      final booking1 = Booking.fromJson(baseJson);
      final booking2 = Booking.fromJson(baseJson);

      expect(booking1, equals(booking2));
    });

    test('bookings with different ids are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      json1['id'] = 'booking-1';
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['id'] = 'booking-2';

      final booking1 = Booking.fromJson(json1);
      final booking2 = Booking.fromJson(json2);

      expect(booking1, isNot(equals(booking2)));
    });

    test('toJson roundtrip produces matching data', () {
      final booking = Booking.fromJson(baseJson);
      final output = booking.toJson();

      expect(output['id'], baseJson['id']);
      expect(output['start_time'], baseJson['start_time']);
      expect(output['end_time'], baseJson['end_time']);
      expect(output['status'], baseJson['status']);
      expect(output['trainer_id'], baseJson['trainer_id']);
      expect(output['client_id'], baseJson['client_id']);
      expect(output['created_at'], baseJson['created_at']);
      expect(output['updated_at'], baseJson['updated_at']);
    });

    test('full roundtrip fromJson -> toJson -> fromJson produces equal object', () {
      final original = Booking.fromJson(baseJson);
      final output = original.toJson();
      final restored = Booking.fromJson(output);

      expect(restored, equals(original));
    });

    test('hashCode is consistent for equal objects', () {
      final booking1 = Booking.fromJson(baseJson);
      final booking2 = Booking.fromJson(baseJson);

      expect(booking1.hashCode, equals(booking2.hashCode));
    });

    test('toString returns expected format', () {
      final booking = Booking.fromJson(baseJson);
      final str = booking.toString();

      expect(str, contains('booking-1'));
      expect(str, contains('Booking('));
      expect(str, contains('trainer-1'));
    });
  });
}
