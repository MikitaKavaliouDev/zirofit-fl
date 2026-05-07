import 'package:zirofit_fl/core/utils/json_helpers.dart';

/// Type of personal record/new record
enum NewRecordType {
  weightIncrease,
  repsIncrease,
  volumeMilestone,
  personalBest;

  static NewRecordType fromJson(String? json) {
    if (json == null) return NewRecordType.personalBest;
    switch (json.toUpperCase()) {
      case 'WEIGHT_INCREASE':
      case 'WEIGHT':
        return NewRecordType.weightIncrease;
      case 'REPS_INCREASE':
      case 'REPS':
        return NewRecordType.repsIncrease;
      case 'VOLUME_MILESTONE':
      case 'VOLUME':
        return NewRecordType.volumeMilestone;
      default:
        return NewRecordType.personalBest;
    }
  }

  String toJson() {
    switch (this) {
      case NewRecordType.weightIncrease:
        return 'weight';
      case NewRecordType.repsIncrease:
        return 'reps';
      case NewRecordType.volumeMilestone:
        return 'volume';
      case NewRecordType.personalBest:
        return 'personal_best';
    }
  }

  String get displayName {
    switch (this) {
      case NewRecordType.weightIncrease:
        return 'Weight PR';
      case NewRecordType.repsIncrease:
        return 'Reps PR';
      case NewRecordType.volumeMilestone:
        return 'Volume Milestone';
      case NewRecordType.personalBest:
        return 'Personal Best';
    }
  }
}

/// Represents a new personal record achieved during a workout
class NewRecord {
  final NewRecordType recordType;
  final String exerciseId;
  final String exerciseName;
  final double? oldRecord;
  final double newRecord;
  final DateTime achievedAt;

  const NewRecord({
    required this.recordType,
    required this.exerciseId,
    required this.exerciseName,
    this.oldRecord,
    required this.newRecord,
    required this.achievedAt,
  });

  factory NewRecord.fromJson(Map<String, dynamic> json) => NewRecord(
        recordType: NewRecordType.fromJson(json['record_type'] as String?),
        exerciseId: json['exercise_id'] as String? ?? json['exerciseId'] as String? ?? '',
        exerciseName: json['exercise_name'] as String? ?? json['exerciseName'] as String? ?? 'Exercise',
        oldRecord: (json['old_record'] as num?)?.toDouble(),
        newRecord: (json['new_record'] as num?)?.toDouble() ?? (json['newRecord'] as num?)?.toDouble() ?? 0,
        achievedAt: readDateTimeOrNull(json, 'achieved_at', 'achievedAt') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'record_type': recordType.toJson(),
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        if (oldRecord != null) 'old_record': oldRecord,
        'new_record': newRecord,
        'achieved_at': achievedAt.toIso8601String(),
      };

  /// Compare two records - returns new record if newRecord > oldRecord
  static NewRecord? compare(NewRecord? existing, NewRecord candidate) {
    if (existing == null) return candidate;
    // Weight and reps are compared differently
    if (candidate.recordType == NewRecordType.repsIncrease) {
      if (candidate.newRecord > existing.newRecord) {
        return candidate;
      }
      return existing;
    }
    // Weight: any improvement
    if (candidate.newRecord > (existing.newRecord)) {
      return candidate;
    }
    return existing;
  }

  String get formattedRecord {
    switch (recordType) {
      case NewRecordType.weightIncrease:
        return '${newRecord.toStringAsFixed(1)} kg';
      case NewRecordType.repsIncrease:
        return '${newRecord.toInt()} reps';
      case NewRecordType.volumeMilestone:
        return '${newRecord.toStringAsFixed(0)} kg';
      case NewRecordType.personalBest:
        return newRecord.toStringAsFixed(1);
    }
  }
}