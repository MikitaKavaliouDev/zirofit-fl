import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/data/models/fitness_goal.dart';
import 'package:zirofit_fl/data/models/personal_record.dart';
import 'package:zirofit_fl/features/progress/providers/goal_provider.dart';

import '../../helpers/provider_utils.dart';

/// Creates a [ProviderContainer] backed by a fresh SharedPreferences mock.
///
/// Each test gets its own container to avoid cross-test interference from
/// the SharedPreferences singleton.
Future<ProviderContainer> createIsolatedContainer({
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = createTestContainer();
  // Trigger lazy provider creation so _loadGoals starts.
  container.read(goalsProvider);
  // Let the async _loadGoals complete.
  await Future(() {});
  return container;
}

void main() {
  group('GoalsState', () {
    test('initial state is correct', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());

      final state = container.read(goalsProvider);
      expect(state.goals, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });
  });

  group('setGoal', () {
    test('adds a new goal', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());

      await container.read(goalsProvider.notifier).setGoal(FitnessGoal(
            id: 'goal-1',
            type: GoalType.sessions,
            targetValue: 4,
            startDate: DateTime(2026, 5, 1),
          ));

      final state = container.read(goalsProvider);
      expect(state.goals, hasLength(1));
      expect(state.goals[0].id, 'goal-1');
      expect(state.goals[0].type, GoalType.sessions);
      expect(state.goals[0].targetValue, 4);
      expect(state.goals[0].currentValue, 0);
    });

    test('updates an existing goal matched by id', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());
      final notifier = container.read(goalsProvider.notifier);

      await notifier.setGoal(FitnessGoal(
        id: 'goal-1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      ));
      await notifier.setGoal(FitnessGoal(
        id: 'goal-1',
        type: GoalType.volume,
        targetValue: 10000,
        startDate: DateTime(2026, 5, 1),
      ));

      final state = container.read(goalsProvider);
      expect(state.goals, hasLength(1));
      expect(state.goals[0].type, GoalType.volume);
      expect(state.goals[0].targetValue, 10000);
    });

    test('adds multiple goals', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());
      final notifier = container.read(goalsProvider.notifier);

      await notifier.setGoal(FitnessGoal(
        id: 'g1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      ));
      await notifier.setGoal(FitnessGoal(
        id: 'g2',
        type: GoalType.volume,
        targetValue: 10000,
        startDate: DateTime(2026, 5, 1),
      ));

      final state = container.read(goalsProvider);
      expect(state.goals, hasLength(2));
    });
  });

  group('removeGoal', () {
    test('removes a goal by id', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());
      final notifier = container.read(goalsProvider.notifier);

      await notifier.setGoal(FitnessGoal(
        id: 'goal-1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      ));
      await notifier.setGoal(FitnessGoal(
        id: 'goal-2',
        type: GoalType.volume,
        targetValue: 10000,
        startDate: DateTime(2026, 5, 1),
      ));

      await notifier.removeGoal('goal-1');

      final state = container.read(goalsProvider);
      expect(state.goals, hasLength(1));
      expect(state.goals[0].id, 'goal-2');
    });

    test('does nothing when id does not exist', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());
      final notifier = container.read(goalsProvider.notifier);

      await notifier.setGoal(FitnessGoal(
        id: 'goal-1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      ));

      await notifier.removeGoal('nonexistent');

      final state = container.read(goalsProvider);
      expect(state.goals, hasLength(1));
    });
  });

  group('clearAllGoals', () {
    test('removes all goals', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());
      final notifier = container.read(goalsProvider.notifier);

      await notifier.setGoal(FitnessGoal(
        id: 'goal-1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      ));

      await notifier.clearAllGoals();

      final state = container.read(goalsProvider);
      expect(state.goals, isEmpty);
    });
  });

  group('updateProgress', () {
    test('calculates sessions progress from heatmap dates', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());
      final notifier = container.read(goalsProvider.notifier);

      await notifier.setGoal(FitnessGoal(
        id: 'goal-1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      ));

      await notifier.updateProgress(heatmapDates: [
        '2026-05-01',
        '2026-05-03',
        '2026-05-05',
      ]);

      final state = container.read(goalsProvider);
      expect(state.goals[0].currentValue, 3);
      expect(state.goals[0].progress, 0.75);
    });

    test('calculates volume progress from volume history', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());
      final notifier = container.read(goalsProvider.notifier);

      await notifier.setGoal(FitnessGoal(
        id: 'goal-1',
        type: GoalType.volume,
        targetValue: 10000,
        startDate: DateTime(2026, 5, 1),
      ));

      await notifier.updateProgress(volumeHistory: [
        VolumePoint(date: DateTime(2026, 5, 1), volume: 3000),
        VolumePoint(date: DateTime(2026, 5, 3), volume: 4000),
        VolumePoint(date: DateTime(2026, 5, 5), volume: 2000),
      ]);

      final state = container.read(goalsProvider);
      expect(state.goals[0].currentValue, 9000);
      expect(state.goals[0].progress, 0.9);
    });

    test('sets PR progress to 1.0 when personal records exist', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());
      final notifier = container.read(goalsProvider.notifier);

      await notifier.setGoal(FitnessGoal(
        id: 'goal-1',
        type: GoalType.pr,
        targetValue: 1,
        startDate: DateTime(2026, 5, 1),
        exerciseName: 'Bench Press',
      ));

      await notifier.updateProgress(prs: [
        PersonalRecord(
          id: 'pr-1',
          clientId: 'client-1',
          exerciseId: 'exercise-1',
          workoutSessionId: 'session-1',
          recordType: '1RM',
          value: 100,
          achievedAt: DateTime(2026, 5, 3),
        ),
      ]);

      final state = container.read(goalsProvider);
      expect(state.goals[0].currentValue, 1.0);
      expect(state.goals[0].progress, 1.0);
    });

    test('sets PR progress to 0.0 when no personal records', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());
      final notifier = container.read(goalsProvider.notifier);

      await notifier.setGoal(FitnessGoal(
        id: 'goal-1',
        type: GoalType.pr,
        targetValue: 1,
        startDate: DateTime(2026, 5, 1),
      ));

      await notifier.updateProgress(prs: []);

      final state = container.read(goalsProvider);
      expect(state.goals[0].currentValue, 0.0);
      expect(state.goals[0].progress, 0.0);
    });

    test('updates multiple goals of different types', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());
      final notifier = container.read(goalsProvider.notifier);

      await notifier.setGoal(FitnessGoal(
        id: 'g-sessions',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      ));
      await notifier.setGoal(FitnessGoal(
        id: 'g-volume',
        type: GoalType.volume,
        targetValue: 10000,
        startDate: DateTime(2026, 5, 1),
      ));
      await notifier.setGoal(FitnessGoal(
        id: 'g-pr',
        type: GoalType.pr,
        targetValue: 1,
        startDate: DateTime(2026, 5, 1),
      ));

      await notifier.updateProgress(
        heatmapDates: ['2026-05-01', '2026-05-02'],
        volumeHistory: [
          VolumePoint(date: DateTime(2026, 5, 1), volume: 5000),
        ],
        prs: [
          PersonalRecord(
            id: 'pr-1',
            clientId: 'client-1',
            exerciseId: 'exercise-1',
            workoutSessionId: 'session-1',
            recordType: '1RM',
            value: 100,
            achievedAt: DateTime(2026, 5, 3),
          ),
        ],
      );

      final state = container.read(goalsProvider);
      expect(state.goals, hasLength(3));
      expect(state.goals[0].currentValue, 2); // sessions
      expect(state.goals[1].currentValue, 5000); // volume
      expect(state.goals[2].currentValue, 1.0); // pr
    });
  });

  group('persistence', () {
    test('loads goals from SharedPreferences on init', () async {
      final goal = FitnessGoal(
        id: 'persisted-1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      );

      final container = await createIsolatedContainer(
        prefs: {'fitness_goals': jsonEncode([goal.toJson()])},
      );
      addTearDown(() => container.dispose());

      final state = container.read(goalsProvider);
      expect(state.goals, hasLength(1));
      expect(state.goals[0].id, 'persisted-1');
      expect(state.goals[0].targetValue, 4);
    });

    test('saves goals to SharedPreferences on setGoal', () async {
      final container = await createIsolatedContainer();
      addTearDown(() => container.dispose());

      await container.read(goalsProvider.notifier).setGoal(FitnessGoal(
            id: 'g1',
            type: GoalType.sessions,
            targetValue: 3,
            startDate: DateTime(2026, 5, 1),
          ));

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('fitness_goals');
      expect(saved, isNotNull);
      final parsed = jsonDecode(saved!) as List;
      expect(parsed, hasLength(1));
      expect(parsed[0]['id'], 'g1');
    });

    test('handles corrupted JSON gracefully', () async {
      final container = await createIsolatedContainer(
        prefs: {'fitness_goals': 'invalid json{{{'},
      );
      addTearDown(() => container.dispose());

      final state = container.read(goalsProvider);
      expect(state.goals, isEmpty);
      expect(state.error, isNull);
    });
  });

  group('FitnessGoal model', () {
    test('progress clamps to 1.0', () {
      final goal = FitnessGoal(
        id: 'g1',
        type: GoalType.sessions,
        targetValue: 4,
        currentValue: 10,
        startDate: DateTime(2026, 5, 1),
      );
      expect(goal.progress, 1.0);
    });

    test('progress returns 0 for zero targetValue', () {
      final goal = FitnessGoal(
        id: 'g1',
        type: GoalType.sessions,
        targetValue: 0,
        currentValue: 5,
        startDate: DateTime(2026, 5, 1),
      );
      expect(goal.progress, 0.0);
    });

    test('fromJson/toJson roundtrip', () {
      final original = FitnessGoal(
        id: 'g1',
        type: GoalType.volume,
        targetValue: 10000,
        currentValue: 5000,
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 6, 1),
        exerciseName: 'Bench Press',
      );

      final json = original.toJson();
      final restored = FitnessGoal.fromJson(json);

      expect(restored, equals(original));
      expect(restored.hashCode, equals(original.hashCode));
    });

    test('equality and hashCode', () {
      final a = FitnessGoal(
        id: 'g1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      );
      final b = FitnessGoal(
        id: 'g1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      );
      final c = FitnessGoal(
        id: 'g2',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString contains fields', () {
      final goal = FitnessGoal(
        id: 'g1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      );
      final str = goal.toString();
      expect(str, contains('FitnessGoal('));
      expect(str, contains('g1'));
      expect(str, contains('sessions'));
    });

    test('GoalType serialization', () {
      expect(GoalType.sessions.toJson(), 'SESSIONS');
      expect(GoalType.volume.toJson(), 'VOLUME');
      expect(GoalType.pr.toJson(), 'PR');

      expect(GoalType.fromJson('SESSIONS'), GoalType.sessions);
      expect(GoalType.fromJson('VOLUME'), GoalType.volume);
      expect(GoalType.fromJson('PR'), GoalType.pr);
      expect(GoalType.fromJson('sessions'), GoalType.sessions);
    });

    test('copyWith replaces fields', () {
      final a = FitnessGoal(
        id: 'g1',
        type: GoalType.sessions,
        targetValue: 4,
        startDate: DateTime(2026, 5, 1),
      );
      final b = a.copyWith(currentValue: 2.0);
      expect(b.currentValue, 2.0);
      expect(b.id, a.id);
      expect(b.type, a.type);
    });
  });
}
