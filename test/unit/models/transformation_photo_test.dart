import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/transformation_photo.dart';

void main() {
  group('TransformationPhoto', () {
    final json = {
      'id': 'photo-1',
      'profile_id': 'profile-1',
      'image_path': '/images/before.jpg',
      'caption': 'Before photo',
      'client_name': 'John Doe',
      'created_at': 1700000000000,
      'updated_at': 1700000100000,
      'deleted_at': null,
    };

    test('fromJson parses all fields', () {
      final photo = TransformationPhoto.fromJson(json);

      expect(photo.id, 'photo-1');
      expect(photo.profileId, 'profile-1');
      expect(photo.imagePath, '/images/before.jpg');
      expect(photo.caption, 'Before photo');
      expect(photo.clientName, 'John Doe');
      expect(photo.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(photo.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000100000));
      expect(photo.deletedAt, isNull);
    });

    test('toJson roundtrip', () {
      final photo = TransformationPhoto.fromJson(json);
      final output = photo.toJson();

      expect(output['id'], 'photo-1');
      expect(output['profile_id'], 'profile-1');
      expect(output['image_path'], '/images/before.jpg');
      expect(output['caption'], 'Before photo');
      expect(output['client_name'], 'John Doe');
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000100000);
      expect(output['deleted_at'], null);
    });

    test('fromJson handles null optionals', () {
      final minimal = {
        'id': 'photo-2',
        'profile_id': 'profile-2',
        'image_path': '/images/after.jpg',
        'created_at': 1700000000000,
        'updated_at': 1700000100000,
      };

      final photo = TransformationPhoto.fromJson(minimal);

      expect(photo.id, 'photo-2');
      expect(photo.caption, isNull);
      expect(photo.clientName, isNull);
      expect(photo.deletedAt, isNull);
    });

    test('equality', () {
      final a = TransformationPhoto.fromJson(json);
      final b = TransformationPhoto.fromJson(json);

      expect(a, equals(b));
    });

    test('hashCode', () {
      final a = TransformationPhoto.fromJson(json);
      final b = TransformationPhoto.fromJson(json);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
