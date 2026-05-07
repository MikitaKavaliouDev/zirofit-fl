import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/new_record.dart';

void main() {
  group('NewRecordType', () {
    test('fromJson returns correct type for weight', () {
      expect(NewRecordType.fromJson('weight'), NewRecordType.weightIncrease);
      expect(NewRecordType.fromJson('weight_increase'), NewRecordType.weightIncrease);
      expect(NewRecordType.fromJson('WEIGHT'), NewRecordType.weightIncrease);
    });

    test('fromJson returns correct type for reps', () {
      expect(NewRecordType.fromJson('reps'), NewRecordType.repsIncrease);
      expect(NewRecordType.fromJson('reps_increase'), NewRecordType.repsIncrease);
      expect(NewRecordType.fromJson('REPS'), NewRecordType.repsIncrease);
    });

    test('fromJson returns correct type for volume', () {
      expect(NewRecordType.fromJson('volume'), NewRecordType.volumeMilestone);
      expect(NewRecordType.fromJson('volume_milestone'), NewRecordType.volumeMilestone);
    });

    test('fromJson defaults to personalBest for unknown', () {
      expect(NewRecordType.fromJson(null), NewRecordType.personalBest);
      expect(NewRecordType.fromJson('unknown'), NewRecordType.personalBest);
    });

    test('displayName returns correct strings', () {
      expect(NewRecordType.weightIncrease.displayName, 'Weight PR');
      expect(NewRecordType.repsIncrease.displayName, 'Reps PR');
      expect(NewRecordType.volumeMilestone.displayName, 'Volume Milestone');
      expect(NewRecordType.personalBest.displayName, 'Personal Best');
    });
  });

  group('NewRecord', () {
    final baseJson = <String, dynamic>{
      'record_type': 'weight',
      'exercise_id': 'ex-1',
      'exercise_name': 'Bench Press',
      'old_record': 100.0,
      'new_record': 105.0,
      'achieved_at': 1700001800000,
    };

    test('fromJson parses all fields correctly', () {
      final record = NewRecord.fromJson(baseJson);

      expect(record.recordType, NewRecordType.weightIncrease);
      expect(record.exerciseId, 'ex-1');
      expect(record.exerciseName, 'Bench Press');
      expect(record.oldRecord, 100.0);
      expect(record.newRecord, 105.0);
    });

    test('toJson produces correct output', () {
      final record = NewRecord.fromJson(baseJson);
      final json = record.toJson();

      expect(json['record_type'], 'weight');
      expect(json['exercise_id'], 'ex-1');
      expect(json['old_record'], 100.0);
    });

    test('formattedRecord returns correct format for weight', () {
      final record = NewRecord(
        recordType: NewRecordType.weightIncrease,
        exerciseId: 'ex-1',
        exerciseName: 'Bench Press',
        newRecord: 105.0,
        achievedAt: DateTime.now(),
      );

      expect(record.formattedRecord, '105.0 kg');
    });

    test('formattedRecord returns correct format for reps', () {
      final record = NewRecord(
        recordType: NewRecordType.repsIncrease,
        exerciseId: 'ex-1',
        exerciseName: 'Bench Press',
        newRecord: 12,
        achievedAt: DateTime.now(),
      );

      expect(record.formattedRecord, '12 reps');
    });
  });

  group('NewRecord comparison', () {
    test('compare returns candidate when existing is null', () {
      final candidate = NewRecord(
        recordType: NewRecordType.weightIncrease,
        exerciseId: 'ex-1',
        exerciseName: 'Bench Press',
        newRecord: 100.0,
        achievedAt: DateTime.now(),
      );

      final result = NewRecord.compare(null, candidate);
      expect(result, candidate);
    });

    test('compare returns new when new weight > old weight', () {
      final existing = NewRecord(
        recordType: NewRecordType.weightIncrease,
        exerciseId: 'ex-1',
        exerciseName: 'Bench Press',
        oldRecord: 100.0,
        newRecord: 100.0,
        achievedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final candidate = NewRecord(
        recordType: NewRecordType.weightIncrease,
        exerciseId: 'ex-1',
        exerciseName: 'Bench Press',
        oldRecord: 100.0,
        newRecord: 105.0,
        achievedAt: DateTime.now(),
      );

      final result = NewRecord.compare(existing, candidate);
      expect(result?.newRecord, 105.0);
    });

    test('compare returns existing when new weight <= old weight', () {
      final existing = NewRecord(
        recordType: NewRecordType.weightIncrease,
        exerciseId: 'ex-1',
        exerciseName: 'Bench Press',
        oldRecord: 100.0,
        newRecord: 100.0,
        achievedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final candidate = NewRecord(
        recordType: NewRecordType.weightIncrease,
        exerciseId: 'ex-1',
        exerciseName: 'Bench Press',
        oldRecord: 100.0,
        newRecord: 100.0,
        achievedAt: DateTime.now(),
      );

      final result = NewRecord.compare(existing, candidate);
      expect(result?.newRecord, existing.newRecord);
    });
  });
}