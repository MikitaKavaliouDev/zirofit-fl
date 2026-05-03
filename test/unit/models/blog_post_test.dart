import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/blog_post.dart';

void main() {
  group('BlogPost model', () {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(1700006400000);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700092800000);
    final publishedAt = DateTime.fromMillisecondsSinceEpoch(1700179200000);

    Map<String, dynamic> createJson() => {
          'id': 'post-1',
          'title': '5 Tips for Better Sleep',
          'slug': '5-tips-for-better-sleep',
          'content': 'Sleep is essential for recovery...',
          'excerpt': 'Improve your sleep quality',
          'cover_image': 'https://ziro.fit/images/sleep.jpg',
          'published': true,
          'author_id': 'trainer-1',
          'created_at': 1700006400000,
          'updated_at': 1700092800000,
          'published_at': 1700179200000,
        };

    test('fromJson parses all fields correctly', () {
      final json = createJson();
      final post = BlogPost.fromJson(json);
      expect(post.id, 'post-1');
      expect(post.title, '5 Tips for Better Sleep');
      expect(post.slug, '5-tips-for-better-sleep');
      expect(post.content, 'Sleep is essential for recovery...');
      expect(post.excerpt, 'Improve your sleep quality');
      expect(post.coverImage, 'https://ziro.fit/images/sleep.jpg');
      expect(post.published, isTrue);
      expect(post.authorId, 'trainer-1');
      expect(post.createdAt, createdAt);
      expect(post.updatedAt, updatedAt);
      expect(post.publishedAt, publishedAt);
    });

    test('toJson produces correct wire format', () {
      final json = createJson();
      final post = BlogPost.fromJson(json);
      final output = post.toJson();
      expect(output['id'], 'post-1');
      expect(output['title'], '5 Tips for Better Sleep');
      expect(output['slug'], '5-tips-for-better-sleep');
      expect(output['content'], 'Sleep is essential for recovery...');
      expect(output['excerpt'], 'Improve your sleep quality');
      expect(output['cover_image'], 'https://ziro.fit/images/sleep.jpg');
      expect(output['published'], isTrue);
      expect(output['author_id'], 'trainer-1');
      expect(output['created_at'], 1700006400000);
      expect(output['updated_at'], 1700092800000);
      expect(output['published_at'], 1700179200000);
      // Verify snake_case keys
      expect(output.containsKey('cover_image'), isTrue);
      expect(output.containsKey('author_id'), isTrue);
      expect(output.containsKey('published_at'), isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'post-2',
        'title': 'Meal Prep Guide',
        'slug': 'meal-prep-guide',
        'content': 'Meal prep saves time...',
        'published': false,
        'author_id': 'trainer-2',
        'created_at': 1700006400000,
        'updated_at': 1700092800000,
      };
      final post = BlogPost.fromJson(json);
      expect(post.excerpt, isNull);
      expect(post.coverImage, isNull);
      expect(post.publishedAt, isNull);
    });

    test('equality works correctly with same JSON input', () {
      final json = createJson();
      final p1 = BlogPost.fromJson(json);
      final p2 = BlogPost.fromJson(json);
      expect(p1, equals(p2));
    });

    test('blog posts with different ids are not equal', () {
      final p1 = BlogPost.fromJson(createJson()..['id'] = 'id-1');
      final p2 = BlogPost.fromJson(createJson()..['id'] = 'id-2');
      expect(p1, isNot(equals(p2)));
    });

    test('toJson roundtrip produces matching data', () {
      final json = createJson();
      final post = BlogPost.fromJson(json);
      final output = post.toJson();
      expect(output['id'], json['id']);
      expect(output['title'], json['title']);
      expect(output['slug'], json['slug']);
      expect(output['author_id'], json['author_id']);
      expect(output['published'], json['published']);
    });

    test('hashCode is consistent', () {
      final json = createJson();
      final p1 = BlogPost.fromJson(json);
      final p2 = BlogPost.fromJson(json);
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
