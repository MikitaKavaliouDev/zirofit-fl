import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/client_model.dart';

void main() {
  group('Client model', () {
    final baseJson = <String, dynamic>{
      'id': 'client-1',
      'trainer_id': 'trainer-1',
      'user_id': 'user-1',
      'name': 'John Doe',
      'email': 'john@example.com',
      'phone': '+1234567890',
      'avatar_path': '/avatars/john.jpg',
      'status': 'active',
      'date_of_birth': 946684800000,
      'goals': 'Lose weight, build muscle',
      'health_notes': 'No known allergies',
      'emergency_contact_name': 'Jane Doe',
      'emergency_contact_phone': '+0987654321',
      'check_in_day': 1,
      'check_in_hour': 9,
      'data_sharing_expires_at': 1735689600000,
      'sharing_settings': <String, dynamic>{
        'progress_photos': true,
        'workout_data': true,
        'nutrition_data': false,
      },
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
      'deleted_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final client = Client.fromJson(baseJson);

      expect(client.id, 'client-1');
      expect(client.trainerId, 'trainer-1');
      expect(client.userId, 'user-1');
      expect(client.name, 'John Doe');
      expect(client.email, 'john@example.com');
      expect(client.phone, '+1234567890');
      expect(client.avatarPath, '/avatars/john.jpg');
      expect(client.status, 'active');
      expect(client.dateOfBirth, DateTime.fromMillisecondsSinceEpoch(946684800000));
      expect(client.goals, 'Lose weight, build muscle');
      expect(client.healthNotes, 'No known allergies');
      expect(client.emergencyContactName, 'Jane Doe');
      expect(client.emergencyContactPhone, '+0987654321');
      expect(client.checkInDay, 1);
      expect(client.checkInHour, 9);
      expect(client.dataSharingExpiresAt, DateTime.fromMillisecondsSinceEpoch(1735689600000));
      expect(client.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(client.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(client.deletedAt, isNull);
    });

    test('fromJson parses sharingSettings map correctly', () {
      final client = Client.fromJson(baseJson);

      expect(client.sharingSettings, isNotNull);
      expect(client.sharingSettings!['progress_photos'], isTrue);
      expect(client.sharingSettings!['workout_data'], isTrue);
      expect(client.sharingSettings!['nutrition_data'], isFalse);
    });

    test('fromJson handles null sharingSettings', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['sharing_settings'] = null;

      final client = Client.fromJson(json);

      expect(client.sharingSettings, isNull);
    });

    test('fromJson handles missing sharingSettings key', () {
      final json = Map<String, dynamic>.from(baseJson);
      json.remove('sharing_settings');

      final client = Client.fromJson(json);

      expect(client.sharingSettings, isNull);
    });

    test('toJson produces correct wire format', () {
      final client = Client.fromJson(baseJson);
      final output = client.toJson();

      expect(output['id'], 'client-1');
      expect(output['trainer_id'], 'trainer-1');
      expect(output['user_id'], 'user-1');
      expect(output['name'], 'John Doe');
      expect(output['email'], 'john@example.com');
      expect(output['phone'], '+1234567890');
      expect(output['avatar_path'], '/avatars/john.jpg');
      expect(output['status'], 'active');
      expect(output['date_of_birth'], isA<int>());
      expect(output['goals'], 'Lose weight, build muscle');
      expect(output['health_notes'], 'No known allergies');
      expect(output['emergency_contact_name'], 'Jane Doe');
      expect(output['emergency_contact_phone'], '+0987654321');
      expect(output['check_in_day'], 1);
      expect(output['check_in_hour'], 9);
      expect(output['data_sharing_expires_at'], 1735689600000);
      expect(output['sharing_settings'], isA<Map<String, dynamic>>());
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000000000);
      expect(output.containsKey('deleted_at'), isTrue);
      expect(output['deleted_at'], isNull);
    });

    test('toJson preserves sharingSettings map', () {
      final client = Client.fromJson(baseJson);
      final output = client.toJson();

      expect(output['sharing_settings'], <String, dynamic>{
        'progress_photos': true,
        'workout_data': true,
        'nutrition_data': false,
      });
    });

    test('toJson correctly serializes date_of_birth as date-only timestamp', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['date_of_birth'] = 946684800000; // 2000-01-01T00:00:00.000Z
      final client = Client.fromJson(json);
      final output = client.toJson();

      // date_of_birth should be serialized as start of day in UTC
      final dob = DateTime.fromMillisecondsSinceEpoch(946684800000);
      final expectedEpoch = DateTime(dob.year, dob.month, dob.day).millisecondsSinceEpoch;
      expect(output['date_of_birth'], expectedEpoch);
    });

    test('toJson sets date_of_birth to null when null', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['date_of_birth'] = null;
      final client = Client.fromJson(json);
      final output = client.toJson();

      expect(output['date_of_birth'], isNull);
    });

    test('fromJson uses default status "active" when status is null', () {
      final json = Map<String, dynamic>.from(baseJson);
      json.remove('status');

      final client = Client.fromJson(json);

      expect(client.status, 'active');
    });

    test('fromJson handles null optional fields', () {
      final json = Map<String, dynamic>.from(baseJson);
      json.remove('trainer_id');
      json.remove('user_id');
      json.remove('email');
      json.remove('phone');
      json.remove('avatar_path');
      json.remove('date_of_birth');
      json.remove('goals');
      json.remove('health_notes');
      json.remove('emergency_contact_name');
      json.remove('emergency_contact_phone');
      json.remove('check_in_day');
      json.remove('check_in_hour');
      json.remove('data_sharing_expires_at');
      json.remove('sharing_settings');
      json['deleted_at'] = null;

      final client = Client.fromJson(json);

      expect(client.trainerId, isNull);
      expect(client.userId, isNull);
      expect(client.email, isNull);
      expect(client.phone, isNull);
      expect(client.avatarPath, isNull);
      expect(client.dateOfBirth, isNull);
      expect(client.goals, isNull);
      expect(client.healthNotes, isNull);
      expect(client.emergencyContactName, isNull);
      expect(client.emergencyContactPhone, isNull);
      expect(client.checkInDay, isNull);
      expect(client.checkInHour, isNull);
      expect(client.dataSharingExpiresAt, isNull);
      expect(client.sharingSettings, isNull);
      expect(client.deletedAt, isNull);
    });

    test('equality works with same data', () {
      final c1 = Client.fromJson(baseJson);
      final c2 = Client.fromJson(baseJson);

      expect(c1, equals(c2));
    });

    test('clients with different ids are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      json1['id'] = 'client-1';
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['id'] = 'client-2';

      final c1 = Client.fromJson(json1);
      final c2 = Client.fromJson(json2);

      expect(c1, isNot(equals(c2)));
    });

    test('clients with different sharingSettings are not equal', () {
      final json1 = Map<String, dynamic>.from(baseJson);
      final json2 = Map<String, dynamic>.from(baseJson);
      json2['sharing_settings'] = <String, dynamic>{'progress_photos': false};

      final c1 = Client.fromJson(json1);
      final c2 = Client.fromJson(json2);

      expect(c1, isNot(equals(c2)));
    });

    test('toJson roundtrip produces matching data', () {
      final client = Client.fromJson(baseJson);
      final output = client.toJson();

      expect(output['id'], baseJson['id']);
      expect(output['name'], baseJson['name']);
      expect(output['email'], baseJson['email']);
      expect(output['status'], baseJson['status']);
      expect(output['created_at'], baseJson['created_at']);
      expect(output['updated_at'], baseJson['updated_at']);
    });

    test('full roundtrip fromJson -> toJson -> fromJson produces equivalent serialization', () {
      final original = Client.fromJson(baseJson);
      final output = original.toJson();
      final restored = Client.fromJson(output);

      expect(restored.toJson(), equals(original.toJson()));
    });

    test('hashCode is consistent for same serialized output', () {
      final c1 = Client.fromJson(baseJson);
      final c2 = Client.fromJson(baseJson);

      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('toString returns expected format', () {
      final client = Client.fromJson(baseJson);
      final str = client.toString();

      expect(str, contains('client-1'));
      expect(str, contains('Client('));
      expect(str, contains('sharingSettings'));
    });
  });
}
