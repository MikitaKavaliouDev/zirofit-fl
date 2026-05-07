import 'package:zirofit_fl/core/utils/json_helpers.dart';

class TextContent {
  final String? aboutMe;
  final String? philosophy;
  final String? methodology;
  final String? certifications;
  final String? qualifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TextContent({
    this.aboutMe,
    this.philosophy,
    this.methodology,
    this.certifications,
    this.qualifications,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TextContent.fromJson(Map<String, dynamic> json) => TextContent(
        aboutMe: json['about_me'] as String?,
        philosophy: json['philosophy'] as String?,
        methodology: json['methodology'] as String?,
        certifications: json['certifications'] as String?,
        qualifications: json['qualifications'] as String?,
        createdAt: dateTimeFromJson(json['created_at'] as int),
        updatedAt: dateTimeFromJson(json['updated_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'about_me': aboutMe,
        'philosophy': philosophy,
        'methodology': methodology,
        'certifications': certifications,
        'qualifications': qualifications,
        'created_at': dateTimeToJson(createdAt),
        'updated_at': dateTimeToJson(updatedAt),
      };

  TextContent copyWith({
    String? aboutMe,
    String? philosophy,
    String? methodology,
    String? certifications,
    String? qualifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TextContent(
      aboutMe: aboutMe ?? this.aboutMe,
      philosophy: philosophy ?? this.philosophy,
      methodology: methodology ?? this.methodology,
      certifications: certifications ?? this.certifications,
      qualifications: qualifications ?? this.qualifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextContent &&
          aboutMe == other.aboutMe &&
          philosophy == other.philosophy &&
          methodology == other.methodology &&
          certifications == other.certifications &&
          qualifications == other.qualifications &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        aboutMe,
        philosophy,
        methodology,
        certifications,
        qualifications,
        createdAt,
        updatedAt,
      ]);
}
