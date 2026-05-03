import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/client_progress_photo.dart';

void main() {
  group('ClientProgressPhoto model', () {
    // Use midnight timestamp to match photoDate's date-only toJson encoding
    final photoDate = DateTime.fromMillisecondsSinceEpoch(1700006400000);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(1700092800000);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700179200000);

    Map<String, dynamic> createJson() => {
          'id': 'photo-1',
          'client_id': 'client-1',
          'photo_date': 1700006400000,
          'image_path': 'progress_photos/photo_001.jpg',
          'caption': 'Week 4 progress',
          'check_in_id': 'ci-1',
          'created_at': 1700092800000,
          'updated_at': 1700179200000,
          'deleted_at': null,
        };

    test('fromJson parses all fields correctly', () {
      final json = createJson();
      final photo = ClientProgressPhoto.fromJson(json);
      expect(photo.id, 'photo-1');
      expect(photo.clientId, 'client-1');
      expect(photo.photoDate, photoDate);
      expect(photo.imagePath, 'progress_photos/photo_001.jpg');
      expect(photo.caption, 'Week 4 progress');
      expect(photo.checkInId, 'ci-1');
      expect(photo.createdAt, createdAt);
      expect(photo.updatedAt, updatedAt);
      expect(photo.deletedAt, isNull);
    });

    test('toJson produces correct wire format', () {
      final json = createJson();
      final photo = ClientProgressPhoto.fromJson(json);
      final output = photo.toJson();
      expect(output['id'], 'photo-1');
      expect(output['client_id'], 'client-1');
      expect(output['image_path'], 'progress_photos/photo_001.jpg');
      expect(output['caption'], 'Week 4 progress');
      expect(output['check_in_id'], 'ci-1');
      expect(output['created_at'], 1700092800000);
      expect(output['updated_at'], 1700179200000);
      // Verify snake_case keys
      expect(output.containsKey('client_id'), isTrue);
      expect(output.containsKey('photo_date'), isTrue);
      expect(output.containsKey('image_path'), isTrue);
      expect(output.containsKey('check_in_id'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'photo-2',
        'client_id': 'client-2',
        'photo_date': 1700006400000,
        'image_path': 'progress_photos/photo_002.jpg',
        'created_at': 1700092800000,
        'updated_at': 1700179200000,
      };
      final photo = ClientProgressPhoto.fromJson(json);
      expect(photo.caption, isNull);
      expect(photo.checkInId, isNull);
      expect(photo.deletedAt, isNull);
    });

    test('equality works correctly with same JSON input', () {
      final json = createJson();
      final p1 = ClientProgressPhoto.fromJson(json);
      final p2 = ClientProgressPhoto.fromJson(json);
      expect(p1, equals(p2));
    });

    test('progress photos with different ids are not equal', () {
      final p1 = ClientProgressPhoto.fromJson(createJson()..['id'] = 'id-1');
      final p2 = ClientProgressPhoto.fromJson(createJson()..['id'] = 'id-2');
      expect(p1, isNot(equals(p2)));
    });

    test('toJson roundtrip produces matching data', () {
      final json = createJson();
      final photo = ClientProgressPhoto.fromJson(json);
      final output = photo.toJson();
      expect(output['id'], json['id']);
      expect(output['client_id'], json['client_id']);
      expect(output['image_path'], json['image_path']);
      expect(output['caption'], json['caption']);
      expect(output['check_in_id'], json['check_in_id']);
      expect(output['created_at'], json['created_at']);
      expect(output['updated_at'], json['updated_at']);
    });

    test('hashCode is consistent', () {
      final json = createJson();
      final p1 = ClientProgressPhoto.fromJson(json);
      final p2 = ClientProgressPhoto.fromJson(json);
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
