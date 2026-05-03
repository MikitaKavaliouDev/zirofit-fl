import 'package:zirofit_fl/core/utils/json_helpers.dart';

class Benefit {
  final String id;
  final String profileId;
  final String? iconName;
  final String? iconStyle;
  final String title;
  final String? description;
  final int orderColumn;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Benefit({
    required this.id,
    required this.profileId,
    this.iconName,
    this.iconStyle,
    required this.title,
    this.description,
    this.orderColumn = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Benefit.fromJson(Map<String, dynamic> json) => Benefit(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        iconName: json['icon_name'] as String?,
        iconStyle: json['icon_style'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        orderColumn: (json['order_column'] as int?) ?? 0,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
        deletedAt: dateTimeFromJsonOrNull(json['deleted_at'] as int?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'icon_name': iconName,
        'icon_style': iconStyle,
        'title': title,
        'description': description,
        'order_column': orderColumn,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
        'deleted_at': dateTimeToJson(deletedAt),
      };

  @override
  String toString() =>
      'Benefit(id: $id, profileId: $profileId, iconName: $iconName, '
      'iconStyle: $iconStyle, title: $title, description: $description, '
      'orderColumn: $orderColumn, createdAt: $createdAt, '
      'updatedAt: $updatedAt, deletedAt: $deletedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Benefit &&
          id == other.id &&
          profileId == other.profileId &&
          iconName == other.iconName &&
          iconStyle == other.iconStyle &&
          title == other.title &&
          description == other.description &&
          orderColumn == other.orderColumn &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        profileId,
        iconName,
        iconStyle,
        title,
        description,
        orderColumn,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
