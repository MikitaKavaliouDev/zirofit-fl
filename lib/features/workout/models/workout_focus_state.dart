// Workout session input focus system
// Mirrors iOS WorkoutSessionView SessionFocusField enum
// and WorkoutInputOverlay state management

/// Represents which field in a set row is currently focused
/// for keyboard/overlay input.
sealed class SessionFocusField {
  const SessionFocusField();

  String get setId;
  bool get isWeight => this is _WeightField;
  bool get isReps => this is _RepsField;
  bool get isTempo => this is _TempoField;
  bool get isRpe => this is _RpeField;

  static SessionFocusField weight(String setId) => _WeightField(setId);
  static SessionFocusField reps(String setId) => _RepsField(setId);
  static SessionFocusField tempo(String setId) => _TempoField(setId);
  static SessionFocusField rpe(String setId) => _RpeField(setId);
}

class _WeightField extends SessionFocusField {
  @override final String setId;
  const _WeightField(this.setId);
}

class _RepsField extends SessionFocusField {
  @override final String setId;
  const _RepsField(this.setId);
}

class _TempoField extends SessionFocusField {
  @override final String setId;
  const _TempoField(this.setId);
}

class _RpeField extends SessionFocusField {
  @override final String setId;
  const _RpeField(this.setId);
}

/// The active input overlay mode in the workout session.
enum WorkoutInputOverlay {
  /// No overlay shown (normal state)
  none,

  /// Custom numeric keyboard for weight/reps input
  keyboard,

  /// Plate calculator visual overlay
  plateCalculator,

  /// RPE picker overlay
  rpePicker,
}

/// Tracks the current input state during workout session.
/// Used by ActiveWorkoutScreen to manage the advanced input system.
class WorkoutInputState {
  const WorkoutInputState({
    this.overlay = WorkoutInputOverlay.none,
    this.focusedField,
    this.activeSetId,
    this.activeText = '',
    this.isInputSelected = false,
  });

  final WorkoutInputOverlay overlay;
  final SessionFocusField? focusedField;
  final String? activeSetId;
  final String activeText;
  final bool isInputSelected;

  bool get isActive => overlay != WorkoutInputOverlay.none && focusedField != null;

  WorkoutInputState copyWith({
    WorkoutInputOverlay? overlay,
    SessionFocusField? focusedField,
    String? activeSetId,
    String? activeText,
    bool? isInputSelected,
    bool clearField = false,
  }) {
    return WorkoutInputState(
      overlay: overlay ?? this.overlay,
      focusedField: clearField ? null : (focusedField ?? this.focusedField),
      activeSetId: clearField ? null : (activeSetId ?? this.activeSetId),
      activeText: clearField ? '' : (activeText ?? this.activeText),
      isInputSelected: clearField ? false : (isInputSelected ?? this.isInputSelected),
    );
  }

  /// Find the next set ID after the current one for keyboard navigation.
  String? findNextSetId(Map<String, List<String>> setsPerExercise, String currentSetId) {
    // Flatten all set IDs in order
    final allSetIds = <String>[];
    for (final sets in setsPerExercise.values) {
      allSetIds.addAll(sets);
    }
    final index = allSetIds.indexOf(currentSetId);
    if (index >= 0 && index + 1 < allSetIds.length) {
      return allSetIds[index + 1];
    }
    return null;
  }
}

/// Extension for equality comparison on SessionFocusField.
extension SessionFocusFieldX on SessionFocusField {
  bool isEqualTo(SessionFocusField other) {
    return setId == other.setId && runtimeType == other.runtimeType;
  }

  // Note: hashCode is inherited from Object, no override needed
}