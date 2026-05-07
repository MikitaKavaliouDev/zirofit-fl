import 'package:zirofit_fl/core/utils/json_helpers.dart';

/// A before/after transformation photo pair for a trainer's portfolio.
class TransformationPhotoPair {
  final String id;
  final String beforeImageUrl;
  final String afterImageUrl;
  final String? caption;
  final DateTime createdAt;

  const TransformationPhotoPair({
    required this.id,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.caption,
    required this.createdAt,
  });

  factory TransformationPhotoPair.fromJson(Map<String, dynamic> json) =>
      TransformationPhotoPair(
        id: json['id'] as String,
        beforeImageUrl: json['before_image_url'] as String,
        afterImageUrl: json['after_image_url'] as String,
        caption: json['caption'] as String?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'before_image_url': beforeImageUrl,
        'after_image_url': afterImageUrl,
        'caption': caption,
        'created_at': dateTimeToJson(createdAt),
      };

  @override
  String toString() =>
      'TransformationPhotoPair(id: $id, beforeImageUrl: $beforeImageUrl, '
      'afterImageUrl: $afterImageUrl, caption: $caption, '
      'createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransformationPhotoPair &&
          id == other.id &&
          beforeImageUrl == other.beforeImageUrl &&
          afterImageUrl == other.afterImageUrl &&
          caption == other.caption &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        beforeImageUrl,
        afterImageUrl,
        caption,
        createdAt,
      );
}
