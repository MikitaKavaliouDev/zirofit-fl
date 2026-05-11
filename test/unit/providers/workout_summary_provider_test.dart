import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/features/workout/providers/workout_summary_provider.dart';
import '../../helpers/mock_api_client.dart';

void main() {
  late WorkoutSummaryNotifier notifier;

  setUp(() {
    notifier = WorkoutSummaryNotifier();
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  WorkoutSession createSession({
    String id = 'session-1',
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return WorkoutSession(
      id: id,
      clientId: 'client-1',
      startTime: startTime ?? DateTime(2025, 5, 6, 10, 0, 0),
      endTime: endTime,
      createdAt: DateTime(2025, 5, 6, 10, 0, 0),
      updatedAt: DateTime(2025, 5, 6, 10, 0, 0),
    );
  }

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('initial state', () {
    test('all values are at their defaults', () {
      final state = notifier.state;
      expect(state.totalVolume, 0);
      expect(state.totalSets, 0);
      expect(state.totalReps, 0);
      expect(state.duration, Duration.zero);
      expect(state.personalRecords, isEmpty);
      expect(state.bestSet, isNull);
      expect(state.exerciseSummaries, isEmpty);
      expect(state.isEmpty, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // calculateSummary
  // ---------------------------------------------------------------------------

  group('calculateSummary', () {
    test('Test 1: calculates total volume (reps × weight for each set)', () {
      final session = createSession();
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's2',
          logId: 'log-bench',
          reps: 8,
          weight: 60,
          isCompleted: true,
        ),
      ];

      notifier.calculateSummary(session, completedSets: sets);

      // 10 × 50 + 8 × 60 = 500 + 480 = 980
      expect(notifier.state.totalVolume, 980);
    });

    test('Test 2: calculates total sets count', () {
      final session = createSession();
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's2',
          logId: 'log-bench',
          reps: 8,
          weight: 60,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's3',
          logId: 'log-squat',
          reps: 5,
          weight: 100,
          isCompleted: true,
        ),
      ];

      notifier.calculateSummary(session, completedSets: sets);

      expect(notifier.state.totalSets, 3);
    });

    test('Test 3: calculates total reps count', () {
      final session = createSession();
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's2',
          logId: 'log-bench',
          reps: 8,
          weight: 60,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's3',
          logId: 'log-squat',
          reps: 5,
          weight: 100,
          isCompleted: true,
        ),
      ];

      notifier.calculateSummary(session, completedSets: sets);

      // 10 + 8 + 5 = 23
      expect(notifier.state.totalReps, 23);
    });

    test('ignores incomplete sets in calculations', () {
      final session = createSession();
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's2',
          logId: 'log-bench',
          reps: 8,
          weight: 60,
          isCompleted: false, // not completed
        ),
        const WorkoutSet(
          id: 's3',
          logId: 'log-squat',
          reps: null,
          weight: null,
          isCompleted: true,
        ),
      ];

      notifier.calculateSummary(session, completedSets: sets);

      expect(notifier.state.totalSets, 1); // only s1 is completed with data
      expect(notifier.state.totalReps, 10); // only s1 reps
      expect(notifier.state.totalVolume, 500); // only s1 volume
    });

    test('calculates duration from session start/end times', () {
      final startTime = DateTime(2025, 5, 6, 10, 0, 0);
      final endTime = DateTime(2025, 5, 6, 11, 30, 0);
      final session = createSession(startTime: startTime, endTime: endTime);
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: true,
        ),
      ];

      notifier.calculateSummary(session, completedSets: sets);

      expect(notifier.state.duration, const Duration(hours: 1, minutes: 30));
    });

    test('duration is zero when session has no end time', () {
      final session = createSession(endTime: null);
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: true,
        ),
      ];

      notifier.calculateSummary(session, completedSets: sets);

      expect(notifier.state.duration, Duration.zero);
    });
  });

  // ---------------------------------------------------------------------------
  // findBestSet
  // ---------------------------------------------------------------------------

  group('findBestSet', () {
    test('Test 4: returns set with highest weight × reps', () {
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: true,
        ), // 500
        const WorkoutSet(
          id: 's2',
          logId: 'log-bench',
          reps: 5,
          weight: 100,
          isCompleted: true,
        ), // 500
        const WorkoutSet(
          id: 's3',
          logId: 'log-squat',
          reps: 8,
          weight: 70,
          isCompleted: true,
        ), // 560 ← best
        const WorkoutSet(
          id: 's4',
          logId: 'log-squat',
          reps: 3,
          weight: 120,
          isCompleted: true,
        ), // 360
      ];

      final best = notifier.findBestSet(sets);

      expect(best, isNotNull);
      expect(best!.id, 's3');
      expect(best.reps, 8);
      expect(best.weight, 70);
    });

    test('skips incomplete sets', () {
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: false,
        ),
        const WorkoutSet(
          id: 's2',
          logId: 'log-squat',
          reps: 5,
          weight: 100,
          isCompleted: true,
        ), // 500 ← best
      ];

      final best = notifier.findBestSet(sets);

      expect(best, isNotNull);
      expect(best!.id, 's2');
    });

    test('skips sets without weight or reps', () {
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: null,
          weight: 50,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's2',
          logId: 'log-bench',
          reps: 10,
          weight: null,
          isCompleted: true,
        ),
      ];

      final best = notifier.findBestSet(sets);

      expect(best, isNull);
    });

    test('returns null for empty list', () {
      final best = notifier.findBestSet([]);

      expect(best, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // detectPRs
  // ---------------------------------------------------------------------------

  group('detectPRs', () {
    test('Test 5: detects PR for heavier weight than history', () {
      final currentSets = [
        const WorkoutSet(
          id: 'c1',
          logId: 'log-bench',
          reps: 5,
          weight: 100,
          isCompleted: true,
        ),
      ];
      final historicalSets = [
        const WorkoutSet(
          id: 'h1',
          logId: 'log-bench',
          reps: 5,
          weight: 90,
          isCompleted: true,
        ),
      ];
      final exerciseNames = {'log-bench': 'Bench Press'};

      final prs = notifier.detectPRs(
        currentSets: currentSets,
        historicalSets: historicalSets,
        exerciseNamesByLogId: exerciseNames,
      );

      expect(prs.length, greaterThanOrEqualTo(1));
      final weightPr = prs.firstWhere((p) => p.type == 'weight');
      expect(weightPr.exerciseName, 'Bench Press');
      expect(weightPr.value, 100);
      expect(weightPr.previousValue, 90);
    });

    test('Test 6: detects PR for more volume than history', () {
      final currentSets = [
        const WorkoutSet(
          id: 'c1',
          logId: 'log-squat',
          reps: 10,
          weight: 80,
          isCompleted: true,
        ), // volume: 800
      ];
      final historicalSets = [
        const WorkoutSet(
          id: 'h1',
          logId: 'log-squat',
          reps: 8,
          weight: 80,
          isCompleted: true,
        ), // volume: 640
      ];
      final exerciseNames = {'log-squat': 'Squat'};

      final prs = notifier.detectPRs(
        currentSets: currentSets,
        historicalSets: historicalSets,
        exerciseNamesByLogId: exerciseNames,
      );

      expect(prs.length, greaterThanOrEqualTo(1));
      final volumePr = prs.firstWhere((p) => p.type == 'volume');
      expect(volumePr.exerciseName, 'Squat');
      expect(volumePr.value, 800);
      expect(volumePr.previousValue, 640);
    });

    test('Test 7: no PR when history has higher values', () {
      final currentSets = [
        const WorkoutSet(
          id: 'c1',
          logId: 'log-bench',
          reps: 5,
          weight: 80,
          isCompleted: true,
        ), // weight: 80, volume: 400
      ];
      final historicalSets = [
        const WorkoutSet(
          id: 'h1',
          logId: 'log-bench',
          reps: 5,
          weight: 100,
          isCompleted: true,
        ), // weight: 100, volume: 500 (better)
      ];
      final exerciseNames = {'log-bench': 'Bench Press'};

      final prs = notifier.detectPRs(
        currentSets: currentSets,
        historicalSets: historicalSets,
        exerciseNamesByLogId: exerciseNames,
      );

      expect(prs, isEmpty);
    });

    test('returns empty when current set has no values', () {
      final currentSets = [
        const WorkoutSet(
          id: 'c1',
          logId: 'log-bench',
          reps: null,
          weight: null,
          isCompleted: true,
        ),
      ];
      final historicalSets = [
        const WorkoutSet(
          id: 'h1',
          logId: 'log-bench',
          reps: 5,
          weight: 100,
          isCompleted: true,
        ),
      ];
      final exerciseNames = {'log-bench': 'Bench Press'};

      final prs = notifier.detectPRs(
        currentSets: currentSets,
        historicalSets: historicalSets,
        exerciseNamesByLogId: exerciseNames,
      );

      expect(prs, isEmpty);
    });

    test('handles multiple exercises independently', () {
      final currentSets = [
        const WorkoutSet(
          id: 'c1',
          logId: 'log-bench',
          reps: 5,
          weight: 100,
          isCompleted: true,
        ), // bench weight: 100 (↑), volume: 500 (↓ vs 900)
        const WorkoutSet(
          id: 'c2',
          logId: 'log-squat',
          reps: 5,
          weight: 120,
          isCompleted: true,
        ), // squat same as history (no PR)
      ];
      final historicalSets = [
        const WorkoutSet(
          id: 'h1',
          logId: 'log-bench',
          reps: 10,
          weight: 90,
          isCompleted: true,
        ), // bench weight: 90, volume: 900 (higher)
        const WorkoutSet(
          id: 'h2',
          logId: 'log-squat',
          reps: 5,
          weight: 140,
          isCompleted: true,
        ), // squat weight: 140 (higher), volume: 700 (higher)
      ];
      final exerciseNames = {
        'log-bench': 'Bench Press',
        'log-squat': 'Squat',
      };

      final prs = notifier.detectPRs(
        currentSets: currentSets,
        historicalSets: historicalSets,
        exerciseNamesByLogId: exerciseNames,
      );

      // Bench should have weight PR (100 > 90) but NOT volume (500 < 900)
      // Squat should have nothing (120 < 140, 600 < 700)
      expect(prs.length, 1);
      expect(prs[0].exerciseName, 'Bench Press');
      expect(prs[0].type, 'weight');
    });
  });

  // ---------------------------------------------------------------------------
  // exerciseSummaries
  // ---------------------------------------------------------------------------

  group('exerciseSummaries', () {
    test('Test 8: groups by exercise name with correct totals', () {
      final session = createSession();
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's2',
          logId: 'log-bench',
          reps: 8,
          weight: 60,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's3',
          logId: 'log-squat',
          reps: 5,
          weight: 100,
          isCompleted: true,
        ),
      ];
      final exerciseNames = {
        'log-bench': 'Bench Press',
        'log-squat': 'Squat',
      };

      notifier.calculateSummary(
        session,
        completedSets: sets,
        exerciseNamesByLogId: exerciseNames,
      );

      final summaries = notifier.state.exerciseSummaries;

      expect(summaries.length, 2);

      // --- Bench Press ---
      final bench = summaries.firstWhere((s) => s.exerciseName == 'Bench Press');
      expect(bench.setsCompleted, 2);
      expect(bench.totalReps, 18); // 10 + 8
      expect(bench.totalVolume, 980); // 500 + 480
      expect(bench.bestWeight, 60);

      // --- Squat ---
      final squat = summaries.firstWhere((s) => s.exerciseName == 'Squat');
      expect(squat.setsCompleted, 1);
      expect(squat.totalReps, 5);
      expect(squat.totalVolume, 500); // 5 × 100
      expect(squat.bestWeight, 100);
    });

    test('uses logId as fallback when no exercise name map provided', () {
      final session = createSession();
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's2',
          logId: 'log-squat',
          reps: 5,
          weight: 100,
          isCompleted: true,
        ),
      ];

      notifier.calculateSummary(session, completedSets: sets);

      final summaries = notifier.state.exerciseSummaries;

      expect(summaries.length, 2);
      expect(summaries.any((s) => s.exerciseName == 'log-bench'), isTrue);
      expect(summaries.any((s) => s.exerciseName == 'log-squat'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // updatePersonalRecords & reset
  // ---------------------------------------------------------------------------

  group('updatePersonalRecords', () {
    test('replaces personalRecords in state', () {
      expect(notifier.state.personalRecords, isEmpty);

      final records = [
        const PersonalRecord(
          exerciseName: 'Bench Press',
          type: 'weight',
          value: 100,
          previousValue: 90,
        ),
      ];

      notifier.updatePersonalRecords(records);

      expect(notifier.state.personalRecords.length, 1);
      expect(notifier.state.personalRecords[0].exerciseName, 'Bench Press');
    });
  });

  group('reset', () {
    test('returns state to defaults', () {
      // Populate some data
      final session = createSession(
        endTime: DateTime(2025, 5, 6, 11, 0, 0),
      );
      final sets = [
        const WorkoutSet(
          id: 's1',
          logId: 'log-bench',
          reps: 10,
          weight: 50,
          isCompleted: true,
        ),
      ];
      notifier.calculateSummary(session, completedSets: sets);
      expect(notifier.state.isEmpty, isFalse);

      notifier.reset();

      expect(notifier.state.totalVolume, 0);
      expect(notifier.state.totalSets, 0);
      expect(notifier.state.totalReps, 0);
      expect(notifier.state.duration, Duration.zero);
      expect(notifier.state.personalRecords, isEmpty);
      expect(notifier.state.bestSet, isNull);
      expect(notifier.state.exerciseSummaries, isEmpty);
      expect(notifier.state.isEmpty, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  group('WorkoutSummaryState.copyWith', () {
    test('returns same state when no arguments provided', () {
      const state = WorkoutSummaryState(
        totalVolume: 1000,
        totalSets: 10,
        totalReps: 50,
      );

      final copied = state.copyWith();

      expect(copied.totalVolume, 1000);
      expect(copied.totalSets, 10);
      expect(copied.totalReps, 50);
    });

    test('overrides specified fields', () {
      const state = WorkoutSummaryState(totalVolume: 1000);

      final copied = state.copyWith(totalVolume: 2000);

      expect(copied.totalVolume, 2000);
    });
  });

  // ---------------------------------------------------------------------------
  // PersonalRecord equality
  // ---------------------------------------------------------------------------

  group('PersonalRecord', () {
    test('equality works correctly', () {
      const a = PersonalRecord(
        exerciseName: 'Bench Press',
        type: 'weight',
        value: 100,
        previousValue: 90,
      );
      const b = PersonalRecord(
        exerciseName: 'Bench Press',
        type: 'weight',
        value: 100,
        previousValue: 90,
      );
      const c = PersonalRecord(
        exerciseName: 'Squat',
        type: 'volume',
        value: 500,
        previousValue: 400,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ---------------------------------------------------------------------------
  // saveAsTemplate
  // ---------------------------------------------------------------------------

  group('saveAsTemplate', () {
    test('Test 9: saveAsTemplate calls API with correct endpoint', () async {
      final mockApi = MockApiClient();
      when(
        () => mockApi.post(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      final notifier = WorkoutSummaryNotifier(apiClient: mockApi);

      await notifier.saveAsTemplate('s1', name: 'Morning Pump');

      verify(
        () => mockApi.post(
          ApiConstants.workoutSaveAsTemplate('s1'),
          body: {'name': 'Morning Pump'},
        ),
      ).called(1);
    });

    test('Test 10: saveAsTemplate throws on API error', () async {
      final mockApi = MockApiClient();
      when(
        () => mockApi.post(any(), body: any(named: 'body')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          message: 'Server error',
        ),
      );

      final notifier = WorkoutSummaryNotifier(apiClient: mockApi);

      await expectLater(
        () => notifier.saveAsTemplate('s1'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
