import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';

class AssignedProgram {
  final String assignmentId;
  final DateTime startDate;
  final bool isActive;
  final String source;
  final WorkoutProgram program;

  const AssignedProgram({
    required this.assignmentId,
    required this.startDate,
    this.isActive = true,
    required this.source,
    required this.program,
  });

  factory AssignedProgram.fromJson(Map<String, dynamic> json) => AssignedProgram(
    assignmentId: json['assignmentId'] as String,
    startDate: readDateTime(json, 'start_date', 'startDate'),
    isActive: json['isActive'] as bool? ?? true,
    source: json['source'] as String,
    program: WorkoutProgram.fromJson(json['program'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'assignmentId': assignmentId,
    'startDate': dateTimeToJson(startDate),
    'isActive': isActive,
    'source': source,
    'program': program.toJson(),
  };

  @override
  String toString() =>
      'AssignedProgram(assignmentId: $assignmentId, startDate: $startDate, '
      'isActive: $isActive, source: $source, program: $program)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignedProgram &&
          assignmentId == other.assignmentId &&
          startDate == other.startDate &&
          isActive == other.isActive &&
          source == other.source &&
          program == other.program;

  @override
  int get hashCode => Object.hash(
    assignmentId,
    startDate,
    isActive,
    source,
    program,
  );
}
