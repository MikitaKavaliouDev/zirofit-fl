import 'package:zirofit_fl/data/models/assigned_program.dart';
import 'package:zirofit_fl/data/models/personal_program.dart';
import 'package:zirofit_fl/data/models/personal_template.dart';

/// Top-level wrapper for the GET /api/client/programs response.
///
/// The API returns these lists wrapped inside a `data` object:
/// ```json
/// {
///   "data": {
///     "assignedPrograms": [...],
///     "personalPrograms": [...],
///     "personalTemplates": [...],
///     "systemTemplates": [...],
///     "categories": ["cardio", "hybrid", "strength"]
///   }
/// }
/// ```
class ClientProgramLibraryResponse {
  final List<AssignedProgram> assignedPrograms;
  final List<PersonalProgram> personalPrograms;
  final List<PersonalTemplate> personalTemplates;
  final List<PersonalTemplate> systemTemplates;
  final List<String> categories;

  const ClientProgramLibraryResponse({
    this.assignedPrograms = const [],
    this.personalPrograms = const [],
    this.personalTemplates = const [],
    this.systemTemplates = const [],
    this.categories = const [],
  });

  factory ClientProgramLibraryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ClientProgramLibraryResponse(
      assignedPrograms: (data['assignedPrograms'] as List<dynamic>?)
              ?.map((e) => AssignedProgram.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      personalPrograms: (data['personalPrograms'] as List<dynamic>?)
              ?.map((e) => PersonalProgram.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      personalTemplates: (data['personalTemplates'] as List<dynamic>?)
              ?.map((e) => PersonalTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      systemTemplates: (data['systemTemplates'] as List<dynamic>?)
              ?.map((e) => PersonalTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categories: (data['categories'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          'assignedPrograms':
              assignedPrograms.map((e) => e.toJson()).toList(),
          'personalPrograms':
              personalPrograms.map((e) => e.toJson()).toList(),
          'personalTemplates':
              personalTemplates.map((e) => e.toJson()).toList(),
          'systemTemplates':
              systemTemplates.map((e) => e.toJson()).toList(),
          'categories': categories,
        },
      };

  @override
  String toString() =>
      'ClientProgramLibraryResponse('
      'assignedPrograms: $assignedPrograms, '
      'personalPrograms: $personalPrograms, '
      'personalTemplates: $personalTemplates, '
      'systemTemplates: $systemTemplates, '
      'categories: $categories)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientProgramLibraryResponse &&
          assignedPrograms == other.assignedPrograms &&
          personalPrograms == other.personalPrograms &&
          personalTemplates == other.personalTemplates &&
          systemTemplates == other.systemTemplates &&
          categories == other.categories;

  @override
  int get hashCode => Object.hash(
        assignedPrograms,
        personalPrograms,
        personalTemplates,
        systemTemplates,
        categories,
      );
}
