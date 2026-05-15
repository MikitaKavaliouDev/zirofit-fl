import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/active_program_progress.dart';
import 'package:zirofit_fl/data/models/active_program_template.dart';

/// Top-level wrapper for GET /api/client/program/active response.
///
/// The API wraps the payload in a `data` envelope:
/// ```json
/// { "data": { "program": {...}, "progress": {...}, "templates": [...] } }
/// ```
class ActiveProgramResponse {
  final WorkoutProgram program;
  final ActiveProgramProgress progress;
  final List<ActiveProgramTemplate> templates;

  const ActiveProgramResponse({
    required this.program,
    required this.progress,
    this.templates = const <ActiveProgramTemplate>[],
  });

  factory ActiveProgramResponse.fromJson(Map<String, dynamic> json) {
    // Unwrap the `data` envelope, falling back to the root object.
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ActiveProgramResponse(
      program:
          WorkoutProgram.fromJson(data['program'] as Map<String, dynamic>),
      progress: ActiveProgramProgress.fromJson(
          data['progress'] as Map<String, dynamic>),
      templates: (data['templates'] as List<dynamic>?)
              ?.map((e) =>
                  ActiveProgramTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ActiveProgramTemplate>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          'program': program.toJson(),
          'progress': progress.toJson(),
          'templates': templates.map((e) => e.toJson()).toList(),
        },
      };

  @override
  String toString() =>
      'ActiveProgramResponse(program: $program, '
      'progress: $progress, templates: $templates)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveProgramResponse &&
          program == other.program &&
          progress == other.progress &&
          _listEquals(templates, other.templates);

  @override
  int get hashCode => Object.hash(
        program,
        progress,
        Object.hashAll(templates),
      );
}

/// Compares two lists of [ActiveProgramTemplate] for element-wise equality.
bool _listEquals(
    List<ActiveProgramTemplate> a, List<ActiveProgramTemplate> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
