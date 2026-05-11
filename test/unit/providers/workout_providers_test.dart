import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/workout/providers/workout_providers.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/data/models/exercise.dart';

void main() {
  // Initialize Flutter binding for tests that use services
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurrentExerciseNotifier', () {
    late ProviderContainer container;
    late CurrentExerciseNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(currentExerciseProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is null', () {
      expect(notifier.state, null);
    });

    test('setExercise updates state', () {
      final exercise = Exercise(
        id: 'ex1',
        name: 'Bench Press',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        equipment: 'barbell',
      );
      notifier.setExercise(exercise);
      
      expect(notifier.state, exercise);
    });

    test('clear resets state to null', () {
      final exercise = Exercise(
        id: 'ex1',
        name: 'Bench Press',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        equipment: 'barbell',
      );
      notifier.setExercise(exercise);
      notifier.clear();
      
      expect(notifier.state, null);
    });

    test('exerciseId returns correct id', () {
      final exercise = Exercise(
        id: 'ex1',
        name: 'Bench Press',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        equipment: 'barbell',
      );
      notifier.setExercise(exercise);
      
      expect(notifier.exerciseId, 'ex1');
    });

    test('exerciseName returns correct name', () {
      final exercise = Exercise(
        id: 'ex1',
        name: 'Bench Press',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        equipment: 'barbell',
      );
      notifier.setExercise(exercise);
      
      expect(notifier.exerciseName, 'Bench Press');
    });
  });

  group('LoggedSetsNotifier', () {
    late ProviderContainer container;
    late LoggedSetsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(loggedSetsProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty list', () {
      expect(notifier.state, isEmpty);
    });

    test('addSet adds set to list', () {
      const set = WorkoutSet(
        id: 'ex1',
        logId: 'log1',
        reps: 10,
        weight: 100,
      );
      notifier.addSet(set);
      
      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, 'ex1');
    });

    test('updateSet replaces set at index', () {
      const set1 = WorkoutSet(id: 'ex1', logId: 'log1', reps: 10, weight: 100);
      const set2 = WorkoutSet(id: 'ex1', logId: 'log2', reps: 10, weight: 105);
      
      notifier.addSet(set1);
      notifier.addSet(set2);
      notifier.updateSet(0, set2);
      
      expect(notifier.state[0].weight, 105);
    });

    test('removeSet removes set at index', () {
      const set = WorkoutSet(id: 'ex1', logId: 'log1', reps: 10, weight: 100);
      notifier.addSet(set);
      notifier.removeSet(0);
      
      expect(notifier.state, isEmpty);
    });

    test('clear empties the list', () {
      const set = WorkoutSet(id: 'ex1', logId: 'log1', reps: 10, weight: 100);
      notifier.addSet(set);
      notifier.clear();
      
      expect(notifier.state, isEmpty);
    });

    test('getSetsForExercise returns correct sets', () {
      const set1 = WorkoutSet(id: 'ex1', logId: 'log1', reps: 10, weight: 100);
      const set2 = WorkoutSet(id: 'ex2', logId: 'log2', reps: 5, weight: 150);
      const set3 = WorkoutSet(id: 'ex1', logId: 'log3', reps: 8, weight: 105);
      
      notifier.addSet(set1);
      notifier.addSet(set2);
      notifier.addSet(set3);
      
      final benchSets = notifier.getSetsForExercise('ex1');
      expect(benchSets.length, 2);
    });

    test('getLatestSetForExercise returns last set', () {
      const set1 = WorkoutSet(id: 'ex1', logId: 'log1', reps: 10, weight: 100);
      const set2 = WorkoutSet(id: 'ex1', logId: 'log2', reps: 8, weight: 105);
      
      notifier.addSet(set1);
      notifier.addSet(set2);
      
      final latest = notifier.getLatestSetForExercise('ex1');
      expect(latest?.weight, 105);
    });
  });

  group('PersonalRecordsNotifier', () {
    late ProviderContainer container;
    late PersonalRecordsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(personalRecordsProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty', () {
      expect(notifier.state, isEmpty);
    });

    test('hasPR returns false for non-PR', () {
      expect(notifier.hasPR('ex1'), false);
    });

    test('markPR adds exercise to list', () {
      notifier.markPR('ex1');
      expect(notifier.hasPR('ex1'), true);
    });

    test('markPR does not duplicate', () {
      notifier.markPR('ex1');
      notifier.markPR('ex1');
      expect(notifier.state.where((id) => id == 'ex1').length, 1);
    });

    test('clear resets state', () {
      notifier.markPR('ex1');
      notifier.clear();
      expect(notifier.state, isEmpty);
    });
  });

  group('RestTimerState', () {
    test('initial state has default values', () {
      const state = RestTimerState();
      expect(state.isActive, false);
      expect(state.secondsRemaining, 0);
      expect(state.totalSeconds, 90);
    });

    test('progress calculates correctly', () {
      const state = RestTimerState(isActive: true, secondsRemaining: 45, totalSeconds: 90);
      expect(state.progress, 0.5);
    });

    test('isComplete returns true when timer done', () {
      const state = RestTimerState(isActive: false, secondsRemaining: 0);
      expect(state.isComplete, true);
    });

    test('copyWith creates new instance', () {
      const state = RestTimerState();
      final newState = state.copyWith(isActive: true, secondsRemaining: 60);
      expect(newState.isActive, true);
      expect(newState.secondsRemaining, 60);
    });
  });

  group('RestTimerNotifier', () {
    late ProviderContainer container;
    late RestTimerNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(restTimerProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is inactive', () {
      expect(notifier.state.isActive, false);
    });

    test('start activates timer', () {
      notifier.start(seconds: 60);
      expect(notifier.state.isActive, true);
      expect(notifier.state.secondsRemaining, 60);
      expect(notifier.state.totalSeconds, 60);
    });

    test('cancel resets state', () {
      notifier.start(seconds: 60);
      notifier.cancel();
      expect(notifier.state.isActive, false);
    });

    test('addTime extends timer', () {
      notifier.start(seconds: 60);
      notifier.addTime(30);
      expect(notifier.state.secondsRemaining, 90);
      expect(notifier.state.totalSeconds, 90);
    });
  });

  group('calculateSetVolume', () {
    test('calculates volume correctly', () {
      const set = WorkoutSet(
        id: 'ex1',
        logId: 'log1',
        weight: 100,
        reps: 10,
      );
      expect(calculateSetVolume(set), 1000);
    });

    test('returns 0 for null values', () {
      const set = WorkoutSet(
        id: 'ex1',
        logId: 'log1',
        weight: null,
        reps: null,
      );
      expect(calculateSetVolume(set), 0);
    });
  });

  group('OfflineQueueNotifier', () {
    late ProviderContainer container;
    late OfflineQueueNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(offlineQueueProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty', () {
      expect(notifier.state, isEmpty);
    });

    test('addToQueue adds item', () {
      final pending = PendingSync(
        id: 'sync1',
        timestamp: DateTime.now(),
        data: {'action': 'logSet'},
      );
      notifier.addToQueue(pending);
      expect(notifier.state.length, 1);
    });

    test('removeFromQueue removes item', () {
      final pending = PendingSync(
        id: 'sync1',
        timestamp: DateTime.now(),
        data: {'action': 'logSet'},
      );
      notifier.addToQueue(pending);
      notifier.removeFromQueue('sync1');
      expect(notifier.state, isEmpty);
    });

    test('clearQueue empties list', () {
      final pending = PendingSync(
        id: 'sync1',
        timestamp: DateTime.now(),
        data: {'action': 'logSet'},
      );
      notifier.addToQueue(pending);
      notifier.clearQueue();
      expect(notifier.state, isEmpty);
    });

    test('hasPending returns correct bool', () {
      expect(notifier.hasPending, false);
      final pending = PendingSync(
        id: 'sync1',
        timestamp: DateTime.now(),
        data: {'action': 'logSet'},
      );
      notifier.addToQueue(pending);
      expect(notifier.hasPending, true);
    });

    test('queueLength returns count', () {
      notifier.addToQueue(PendingSync(id: '1', timestamp: DateTime.now(), data: {}));
      notifier.addToQueue(PendingSync(id: '2', timestamp: DateTime.now(), data: {}));
      expect(notifier.queueLength, 2);
    });
  });
}