import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:zirofit_fl/data/models/exercise.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// State container for custom exercises managed by the trainer.
class CustomExercisesState {
  final List<Exercise> customExercises;
  final bool isLoading;
  final String? error;

  const CustomExercisesState({
    this.customExercises = const [],
    this.isLoading = false,
    this.error,
  });

  CustomExercisesState copyWith({
    List<Exercise>? customExercises,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CustomExercisesState(
      customExercises: customExercises ?? this.customExercises,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final customExercisesProvider =
    StateNotifierProvider<CustomExercisesNotifier, CustomExercisesState>((ref) {
  return CustomExercisesNotifier();
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages trainer-created custom exercises, persisted locally in
/// SharedPreferences (there is no dedicated backend CRUD endpoint for
/// custom exercises).
class CustomExercisesNotifier extends StateNotifier<CustomExercisesState> {
  static const String _storageKey = 'custom_exercises';
  late final Future<void> _initDone;

  CustomExercisesNotifier() : super(const CustomExercisesState()) {
    _initDone = _loadExercises();
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Loads custom exercises from SharedPreferences on startup.
  Future<void> _loadExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final list = (jsonDecode(jsonString) as List)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(customExercises: list);
      } catch (_) {
        // Corrupted data — start fresh.
        state = state.copyWith(customExercises: []);
      }
    }
  }

  /// Ensures custom exercises have loaded before any CRUD operation.
  Future<void> _ensureInitialized() async {
    await _initDone;
  }

  /// Persists the current custom exercises list to SharedPreferences.
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      state.customExercises.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_storageKey, jsonString);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Reloads custom exercises from local storage.
  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _loadExercises();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Creates a new custom exercise and persists it.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> createExercise({
    required String name,
    String? muscleGroup,
    String? equipment,
    String? description,
  }) async {
    await _ensureInitialized();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final now = DateTime.now();
      final exercise = Exercise(
        id: const Uuid().v4(),
        name: name,
        muscleGroup: muscleGroup,
        equipment: equipment,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      state = state.copyWith(
        customExercises: [...state.customExercises, exercise],
        isLoading: false,
      );
      await _save();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Removes a custom exercise by [id] and persists the change.
  Future<bool> deleteExercise(String id) async {
    await _ensureInitialized();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      state = state.copyWith(
        customExercises:
            state.customExercises.where((e) => e.id != id).toList(),
        isLoading: false,
      );
      await _save();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
