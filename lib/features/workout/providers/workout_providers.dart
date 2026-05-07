import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/core/services/haptic_service.dart';

/// Provider for managing the current exercise being performed
final currentExerciseProvider = StateNotifierProvider<CurrentExerciseNotifier, Exercise?>((ref) {
  return CurrentExerciseNotifier();
});

class CurrentExerciseNotifier extends StateNotifier<Exercise?> {
  CurrentExerciseNotifier() : super(null);

  void setExercise(Exercise exercise) {
    state = exercise;
  }

  void clear() {
    state = null;
  }

  String? get exerciseId => state?.id;
  String? get exerciseName => state?.name;
}

/// Provider for managing sets logged in current workout
final loggedSetsProvider = StateNotifierProvider<LoggedSetsNotifier, List<WorkoutSet>>((ref) {
  return LoggedSetsNotifier();
});

class LoggedSetsNotifier extends StateNotifier<List<WorkoutSet>> {
  final HapticService _haptic;
  
  LoggedSetsNotifier({HapticService? haptic}) : 
    _haptic = haptic ?? HapticService(),
    super([]);

  void addSet(WorkoutSet set) {
    state = [...state, set];
    _haptic.lightImpact();  // Light for set log
  }

  void updateSet(int index, WorkoutSet set) {
    if (index >= 0 && index < state.length) {
      final newState = [...state];
      newState[index] = set;
      state = newState;
    }
  }

  void removeSet(int index) {
    if (index >= 0 && index < state.length) {
      final newState = [...state];
      newState.removeAt(index);
      state = newState;
    }
  }

  void clear() {
    state = [];
  }

  List<WorkoutSet> getSetsForExercise(String exerciseId) {
    return state.where((s) => s.id == exerciseId).toList();
  }

  WorkoutSet? getLatestSetForExercise(String exerciseId) {
    final sets = getSetsForExercise(exerciseId);
    if (sets.isEmpty) return null;
    return sets.last;
  }
}

/// Provider for tracking PRs achieved in current workout
final personalRecordsProvider = StateNotifierProvider<PersonalRecordsNotifier, List<String>>((ref) {
  return PersonalRecordsNotifier();
});

class PersonalRecordsNotifier extends StateNotifier<List<String>> {
  PersonalRecordsNotifier() : super([]);

  bool hasPR(String exerciseId) => state.contains(exerciseId);

  void markPR(String exerciseId) {
    if (!state.contains(exerciseId)) {
      state = [...state, exerciseId];
    }
  }

  void clear() {
    state = [];
  }
}

/// Provider for rest timer
final restTimerProvider = StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

class RestTimerState {
  final bool isActive;
  final int secondsRemaining;
  final int totalSeconds;

  const RestTimerState({
    this.isActive = false,
    this.secondsRemaining = 0,
    this.totalSeconds = 90,
  });

  RestTimerState copyWith({
    bool? isActive,
    int? secondsRemaining,
    int? totalSeconds,
  }) {
    return RestTimerState(
      isActive: isActive ?? this.isActive,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      totalSeconds: totalSeconds ?? this.totalSeconds,
    );
  }

  double get progress => totalSeconds > 0 ? secondsRemaining / totalSeconds : 0;
  /// isComplete: true when timer was active and has completed (secondsRemaining <= 0 and isActive just ended)
  bool get isComplete => secondsRemaining <= 0;
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  RestTimerNotifier() : super(const RestTimerState());

  void start({int seconds = 90}) {
    state = RestTimerState(
      isActive: true,
      secondsRemaining: seconds,
      totalSeconds: seconds,
    );
  }

  void tick() {
    if (!state.isActive) return;
    
    final newSeconds = state.secondsRemaining - 1;
    if (newSeconds <= 0) {
      state = state.copyWith(isActive: false, secondsRemaining: 0);
    } else {
      state = state.copyWith(secondsRemaining: newSeconds);
    }
  }

  void cancel() {
    state = const RestTimerState();
  }

  void addTime(int seconds) {
    if (!state.isActive) return;
    state = state.copyWith(
      secondsRemaining: state.secondsRemaining + seconds,
      totalSeconds: state.totalSeconds + seconds,
    );
  }
}

/// Provider for tracking current set count in workout
final setCountProvider = StateProvider<int>((ref) => 0);

/// Provider for tracking workout volume (total reps * weight)
final workoutVolumeProvider = StateProvider<double>((ref) => 0.0);

/// Helper to calculate volume from a set
double calculateSetVolume(WorkoutSet set) {
  if (set.weight == null || set.reps == null) return 0;
  return set.weight! * set.reps!;
}

/// Provider for managing offline queue
final offlineQueueProvider = StateNotifierProvider<OfflineQueueNotifier, List<PendingSync>>((ref) {
  return OfflineQueueNotifier();
});

class PendingSync {
  final String id;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  PendingSync({
    required this.id,
    required this.timestamp,
    required this.data,
  });
}

class OfflineQueueNotifier extends StateNotifier<List<PendingSync>> {
  OfflineQueueNotifier() : super([]);

  void addToQueue(PendingSync sync) {
    state = [...state, sync];
  }

  void removeFromQueue(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  void clearQueue() {
    state = [];
  }

  bool get hasPending => state.isNotEmpty;
  int get queueLength => state.length;
}