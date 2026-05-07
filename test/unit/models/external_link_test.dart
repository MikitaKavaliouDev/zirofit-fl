import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/external_link.dart';

void main() {
  group('ExternalLink', () {
    final json = {
      'id': 'test-id',
      'profile_id': 'test-profile-id',
      'link_url': 'https://instagram.com/test',
      'label': 'Instagram',
      'created_at': 1700000000000,
      'updated_at': 1700000001000,
      'deleted_at': null,
    };

    test('fromJson parses all fields correctly', () {
      final model = ExternalLink.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.profileId, 'test-profile-id');
      expect(model.linkUrl, 'https://instagram.com/test');
      expect(model.label, 'Instagram');
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000001000));
      expect(model.deletedAt, isNull);
    });

    test('toJson produces correct wire format', () {
      final model = ExternalLink.fromJson(json);
      // description is null, so omitted from toJson
      final expected = Map<String, dynamic>.from(json)..remove('description');
      expect(model.toJson(), expected);
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'id': 'test-id',
        'profile_id': 'test-profile-id',
        'link_url': 'https://instagram.com/test',
        'label': 'Instagram',
        'created_at': 1700000000000,
        'updated_at': 1700000001000,
      };
      final model = ExternalLink.fromJson(minimalJson);
      expect(model.deletedAt, isNull);
      expect(model.description, isNull);
    });

    test('fromJson parses description when present', () {
      final withDescription = Map<String, dynamic>.from(json);
      withDescription['description'] = 'My social media link';
      final model = ExternalLink.fromJson(withDescription);
      expect(model.description, 'My social media link');
    });

    test('copyWith updates fields correctly', () {
      final model = ExternalLink.fromJson(json);
      final updated = model.copyWith(label: 'New Label', linkUrl: 'https://new.url');
      expect(updated.label, 'New Label');
      expect(updated.linkUrl, 'https://new.url');
      expect(updated.id, model.id);
    });

    test('equality works correctly', () {
      final model1 = ExternalLink.fromJson(json);
      final model2 = ExternalLink.fromJson(json);
      expect(model1, equals(model2));
    });

    test('hashCode is consistent', () {
      final model = ExternalLink.fromJson(json);
      expect(model.hashCode, equals(model.hashCode));
    });
  });
}
