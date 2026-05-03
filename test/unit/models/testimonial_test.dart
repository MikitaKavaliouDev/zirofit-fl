import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';

void main() {
  group('Testimonial', () {
    final json = {
      'id': 'test-1',
      'profile_id': 'profile-1',
      'client_name': 'John Doe',
      'testimonial_text': 'Great trainer!',
      'rating': 5,
      'created_at': 1700000000000,
      'updated_at': 1700000100000,
      'deleted_at': null,
    };

    test('fromJson parses all fields', () {
      final testimonial = Testimonial.fromJson(json);

      expect(testimonial.id, 'test-1');
      expect(testimonial.profileId, 'profile-1');
      expect(testimonial.clientName, 'John Doe');
      expect(testimonial.testimonialText, 'Great trainer!');
      expect(testimonial.rating, 5);
      expect(testimonial.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(testimonial.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000100000));
      expect(testimonial.deletedAt, isNull);
    });

    test('toJson roundtrip', () {
      final testimonial = Testimonial.fromJson(json);
      final output = testimonial.toJson();

      expect(output['id'], 'test-1');
      expect(output['profile_id'], 'profile-1');
      expect(output['client_name'], 'John Doe');
      expect(output['testimonial_text'], 'Great trainer!');
      expect(output['rating'], 5);
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000100000);
      expect(output['deleted_at'], null);
    });

    test('fromJson handles null optionals', () {
      final minimal = {
        'id': 'test-2',
        'profile_id': 'profile-2',
        'client_name': 'Jane Doe',
        'testimonial_text': 'Amazing results',
        'created_at': 1700000000000,
        'updated_at': 1700000100000,
      };

      final testimonial = Testimonial.fromJson(minimal);

      expect(testimonial.id, 'test-2');
      expect(testimonial.rating, isNull);
      expect(testimonial.deletedAt, isNull);
    });

    test('equality', () {
      final a = Testimonial.fromJson(json);
      final b = Testimonial.fromJson(json);

      expect(a, equals(b));
    });

    test('hashCode', () {
      final a = Testimonial.fromJson(json);
      final b = Testimonial.fromJson(json);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
