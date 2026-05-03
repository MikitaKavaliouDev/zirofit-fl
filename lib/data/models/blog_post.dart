import 'package:zirofit_fl/core/utils/json_helpers.dart';

class BlogPost {
  final String id;
  final String title;
  final String slug;
  final String content;
  final String? excerpt;
  final String? coverImage;
  final bool published;
  final String authorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.excerpt,
    this.coverImage,
    this.published = false,
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) =>
      BlogPost(
        id: json['id'] as String,
        title: json['title'] as String,
        slug: json['slug'] as String,
        content: json['content'] as String,
        excerpt: json['excerpt'] as String?,
        coverImage: json['cover_image'] as String?,
        published: (json['published'] as bool?) ?? false,
        authorId: json['author_id'] as String,
        createdAt:
            dateTimeFromJson(json['created_at'] as int),
        updatedAt:
            dateTimeFromJson(json['updated_at'] as int),
        publishedAt: dateTimeFromJsonOrNull(
            json['published_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'content': content,
        'excerpt': excerpt,
        'cover_image': coverImage,
        'published': published,
        'author_id': authorId,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'published_at': dateTimeToJson(publishedAt),
      };

  @override
  String toString() =>
      'BlogPost(id: $id, title: $title, slug: $slug, '
      'content: $content, excerpt: $excerpt, '
      'coverImage: $coverImage, published: $published, '
      'authorId: $authorId, createdAt: $createdAt, '
      'updatedAt: $updatedAt, publishedAt: $publishedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlogPost &&
          id == other.id &&
          title == other.title &&
          slug == other.slug &&
          content == other.content &&
          excerpt == other.excerpt &&
          coverImage == other.coverImage &&
          published == other.published &&
          authorId == other.authorId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          publishedAt == other.publishedAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        slug,
        content,
        excerpt,
        coverImage,
        published,
        authorId,
        createdAt,
        updatedAt,
        publishedAt,
      );
}
