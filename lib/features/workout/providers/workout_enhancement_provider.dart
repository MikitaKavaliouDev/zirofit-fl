import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/plate_calculation.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final workoutEnhancementProvider = StateNotifierProvider<
    WorkoutEnhancementNotifier, WorkoutEnhancementState>((ref) {
  return WorkoutEnhancementNotifier();
});

// ---------------------------------------------------------------------------
// Rest timer settings
// ---------------------------------------------------------------------------

class RestTimerSettings {
  final int defaultSeconds;
  final List<int> presets;
  final int customMinutes;
  final int customSeconds;

  const RestTimerSettings({
    this.defaultSeconds = 90,
    this.presets = const [30, 60, 90, 120, 180],
    this.customMinutes = 0,
    this.customSeconds = 0,
  });

  RestTimerSettings copyWith({
    int? defaultSeconds,
    List<int>? presets,
    int? customMinutes,
    int? customSeconds,
  }) {
    return RestTimerSettings(
      defaultSeconds: defaultSeconds ?? this.defaultSeconds,
      presets: presets ?? this.presets,
      customMinutes: customMinutes ?? this.customMinutes,
      customSeconds: customSeconds ?? this.customSeconds,
    );
  }
}

// ---------------------------------------------------------------------------
// RPE state
// ---------------------------------------------------------------------------

class RpeState {
  final double? currentRpe;
  final double? currentRir;
  final bool showRpePicker;

  const RpeState({
    this.currentRpe,
    this.currentRir,
    this.showRpePicker = false,
  });

  RpeState copyWith({
    double? currentRpe,
    double? currentRir,
    bool? showRpePicker,
    bool clearRpe = false,
    bool clearRir = false,
  }) {
    return RpeState(
      currentRpe: clearRpe ? null : (currentRpe ?? this.currentRpe),
      currentRir: clearRir ? null : (currentRir ?? this.currentRir),
      showRpePicker: showRpePicker ?? this.showRpePicker,
    );
  }
}

// ---------------------------------------------------------------------------
// Superset group
// ---------------------------------------------------------------------------

class SupersetGroup {
  final String key;
  final List<String> exerciseIds;
  final int completedSets;
  final int totalSets;

  const SupersetGroup({
    required this.key,
    this.exerciseIds = const [],
    this.completedSets = 0,
    this.totalSets = 0,
  });

  SupersetGroup copyWith({
    String? key,
    List<String>? exerciseIds,
    int? completedSets,
    int? totalSets,
  }) {
    return SupersetGroup(
      key: key ?? this.key,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      completedSets: completedSets ?? this.completedSets,
      totalSets: totalSets ?? this.totalSets,
    );
  }
}

// ---------------------------------------------------------------------------
// Combined enhancement state
// ---------------------------------------------------------------------------

class WorkoutEnhancementState {
  final RestTimerSettings restTimerSettings;
  final RpeState rpeState;
  final List<SupersetGroup> supersetGroups;
  final PlateCalculation? plateCalculation;

  const WorkoutEnhancementState({
    this.restTimerSettings = const RestTimerSettings(),
    this.rpeState = const RpeState(),
    this.supersetGroups = const [],
    this.plateCalculation,
  });

  WorkoutEnhancementState copyWith({
    RestTimerSettings? restTimerSettings,
    RpeState? rpeState,
    List<SupersetGroup>? supersetGroups,
    PlateCalculation? plateCalculation,
    bool clearPlateCalculation = false,
  }) {
    return WorkoutEnhancementState(
      restTimerSettings: restTimerSettings ?? this.restTimerSettings,
      rpeState: rpeState ?? this.rpeState,
      supersetGroups: supersetGroups ?? this.supersetGroups,
      plateCalculation:
          clearPlateCalculation ? null : (plateCalculation ?? this.plateCalculation),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class WorkoutEnhancementNotifier
    extends StateNotifier<WorkoutEnhancementState> {
  WorkoutEnhancementNotifier() : super(const WorkoutEnhancementState());

  // ---------------------------------------------------------------------------
  // Rest timer
  // ---------------------------------------------------------------------------

  /// Sets the default rest timer duration in seconds.
  void setDefaultSeconds(int seconds) {
    state = state.copyWith(
      restTimerSettings: state.restTimerSettings.copyWith(
        defaultSeconds: seconds,
      ),
    );
  }

  /// Sets a custom rest timer duration.
  void setCustomTime(int minutes, int seconds) {
    state = state.copyWith(
      restTimerSettings: state.restTimerSettings.copyWith(
        customMinutes: minutes,
        customSeconds: seconds,
        defaultSeconds: minutes * 60 + seconds,
      ),
    );
  }

  /// Selects a preset rest timer value.
  void selectPreset(int seconds) {
    state = state.copyWith(
      restTimerSettings: state.restTimerSettings.copyWith(
        defaultSeconds: seconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RPE
  // ---------------------------------------------------------------------------

  /// Shows or hides the RPE picker overlay.
  void showRpePicker() {
    state = state.copyWith(
      rpeState: state.rpeState.copyWith(showRpePicker: true),
    );
  }

  /// Hides the RPE picker overlay without clearing values.
  void hideRpePicker() {
    state = state.copyWith(
      rpeState: state.rpeState.copyWith(showRpePicker: false),
    );
  }

  /// Sets the RPE value for the current set.
  void setRpe(double rpe) {
    state = state.copyWith(
      rpeState: state.rpeState.copyWith(
        currentRpe: rpe,
        clearRir: false,
      ),
    );
  }

  /// Sets the RIR (Reps in Reserve) for the current set.
  void setRir(double rir) {
    state = state.copyWith(
      rpeState: state.rpeState.copyWith(
        currentRir: rir,
        clearRpe: false,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Supersets
  // ---------------------------------------------------------------------------

  /// Creates a new superset group with the given [key] (e.g. 'A', 'B', 'C').
  void createGroup(String key) {
    final existing = state.supersetGroups.indexWhere((g) => g.key == key);
    if (existing >= 0) return; // Group already exists

    state = state.copyWith(
      supersetGroups: [
        ...state.supersetGroups,
        SupersetGroup(key: key),
      ],
    );
  }

  /// Adds an [exerciseId] to an existing superset group identified by [key].
  void addToGroup(String key, String exerciseId) {
    state = state.copyWith(
      supersetGroups: state.supersetGroups.map((group) {
        if (group.key != key) return group;
        if (group.exerciseIds.contains(exerciseId)) return group;
        return group.copyWith(
          exerciseIds: [...group.exerciseIds, exerciseId],
        );
      }).toList(),
    );
  }

  /// Removes an [exerciseId] from a superset group identified by [key].
  void removeFromGroup(String key, String exerciseId) {
    state = state.copyWith(
      supersetGroups: state.supersetGroups.map((group) {
        if (group.key != key) return group;
        return group.copyWith(
          exerciseIds: group.exerciseIds.where((id) => id != exerciseId).toList(),
        );
      }).toList(),
    );
  }

  /// Increments the completed set count for a superset group.
  void incrementCompleted(String key) {
    state = state.copyWith(
      supersetGroups: state.supersetGroups.map((group) {
        if (group.key != key) return group;
        return group.copyWith(
          completedSets: group.completedSets + 1,
        );
      }).toList(),
    );
  }

  /// Resets a superset group's completion state.
  void resetGroup(String key) {
    state = state.copyWith(
      supersetGroups: state.supersetGroups.map((group) {
        if (group.key != key) return group;
        return group.copyWith(completedSets: 0);
      }).toList(),
    );
  }

  /// Creates a superset with the given exercise IDs.
  void createSuperset(List<String> exerciseIds) {
    if (exerciseIds.isEmpty) return;

    // Find next available key (A, B, C, etc.)
    final existingKeys = state.supersetGroups.map((g) => g.key).toSet();
    String nextKey = 'A';
    for (var i = 0; i < 26; i++) {
      final key = String.fromCharCode(65 + i);
      if (!existingKeys.contains(key)) {
        nextKey = key;
        break;
      }
    }

    state = state.copyWith(
      supersetGroups: [
        ...state.supersetGroups,
        SupersetGroup(key: nextKey, exerciseIds: exerciseIds),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Plate calculator
  // ---------------------------------------------------------------------------

  /// Calculates the plate configuration for a given [totalWeight].
  void calculateForWeight(double totalWeight) {
    final plates = calculatePlates(totalWeight);
    state = state.copyWith(
      plateCalculation: PlateCalculation(
        totalWeight: totalWeight,
        platesPerSide: plates,
      ),
    );
  }

  /// Calculates plates with a custom [barWeight].
  void calculateForWeightWithBar(double totalWeight, {double barWeight = 20.0}) {
    final plates = calculatePlates(totalWeight, barWeight: barWeight);
    state = state.copyWith(
      plateCalculation: PlateCalculation(
        totalWeight: totalWeight,
        barWeight: barWeight,
        platesPerSide: plates,
      ),
    );
  }

  /// Clears the current plate calculation.
  void clearPlateCalculation() {
    state = state.copyWith(clearPlateCalculation: true);
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Resets all enhancement state to defaults.
  void reset() {
    state = const WorkoutEnhancementState();
  }
}
