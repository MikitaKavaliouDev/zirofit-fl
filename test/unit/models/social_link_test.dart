import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/social_link.dart';

void main() {
  group('SocialLink', () {
    const createdAt = 1700000000000;
    const updatedAt = 1700100000000;
    const deletedAt = 1700200000000;

    final json = {
      'id': 'sl-1',
      'profile_id': 'profile-1',
      'platform': 'instagram',
      'username': '@fitnesspro',
      'profile_url': 'https://instagram.com/fitnesspro',
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };

    test('fromJson parses all fields correctly', () {
      final model = SocialLink.fromJson(json);
      expect(model.id, 'sl-1');
      expect(model.profileId, 'profile-1');
      expect(model.platform, 'instagram');
      expect(model.username, '@fitnesspro');
      expect(model.profileUrl, 'https://instagram.com/fitnesspro');
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(createdAt));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(updatedAt));
      expect(model.deletedAt, DateTime.fromMillisecondsSinceEpoch(deletedAt));
    });

    test('toJson produces correct wire format', () {
      final model = SocialLink.fromJson(json);
      expect(model.toJson(), json);
    });

    test('fromJson handles null optional fields', () {
      final minimal = {
        'id': 'sl-2',
        'profile_id': 'profile-2',
        'platform': 'youtube',
        'username': '@fitnesscoach',
        'profile_url': 'https://youtube.com/@fitnesscoach',
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
      final model = SocialLink.fromJson(minimal);
      expect(model.id, 'sl-2');
      expect(model.profileId, 'profile-2');
      expect(model.platform, 'youtube');
      expect(model.username, '@fitnesscoach');
      expect(model.profileUrl, 'https://youtube.com/@fitnesscoach');
      expect(model.deletedAt, isNull);
    });

    test('equality works correctly', () {
      final model1 = SocialLink.fromJson(json);
      final model2 = SocialLink.fromJson(json);
      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality detects different id', () {
      final model1 = SocialLink.fromJson({...json, 'id': 'sl-1'});
      final model2 = SocialLink.fromJson({...json, 'id': 'sl-2'});
      expect(model1, isNot(equals(model2)));
    });

    test('hashCode is consistent', () {
      final model = SocialLink.fromJson(json);
      final hashCode1 = model.hashCode;
      final hashCode2 = model.hashCode;
      expect(hashCode1, equals(hashCode2));
    });
  });
}
