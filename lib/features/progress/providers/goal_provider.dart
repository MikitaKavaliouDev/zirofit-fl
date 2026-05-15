import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/fitness_goal.dart';
import 'package:zirofit_fl/data/models/personal_record.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

/// A single data point of training volume for a given date.
///
/// Used by [GoalsNotifier.updateProgress] to calculate volume goal progress.
class VolumePoint {
  final DateTime date;
  final double volume;

  const VolumePoint({required this.date, required this.volume});
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class GoalsState {
  final List<FitnessGoal> goals;
  final bool isLoading;
  final String? error;

  const GoalsState({
    this.goals = const [],
    this.isLoading = false,
    this.error,
  });

  GoalsState copyWith({
    List<FitnessGoal>? goals,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, GoalsState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return GoalsNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class GoalsNotifier extends StateNotifier<GoalsState> {
  static const String _storageKey = 'fitness_goals';
  final ApiClient? _apiClient;
  late final Future<void> _initDone;

  GoalsNotifier({ApiClient? apiClient})
      : _apiClient = apiClient,
        super(const GoalsState()) {
    _initDone = _loadGoals();
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Loads goals — tries API first, falls back to SharedPreferences.
  Future<void> _loadGoals() async {
    // Try API first
    if (_apiClient != null) {
      try {
        final response = await _apiClient!.get<Map<String, dynamic>>(
          ApiConstants.fitnessGoals,
        );
        final data = response['data'];
        if (data is List) {
          final goals = data
              .map((e) => FitnessGoal.fromJson(e as Map<String, dynamic>))
              .toList();
          state = state.copyWith(goals: goals);
          // Also persist locally as cache
          await _saveGoals();
          return;
        }
      } catch (_) {
        // API failed, fall through to local
      }
    }

    // Fallback: load from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final list = (jsonDecode(jsonString) as List)
            .map((e) => FitnessGoal.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(goals: list);
      } catch (_) {
        // Corrupted data — start fresh.
        state = state.copyWith(goals: []);
      }
    }
  }

  /// Ensures that [goalsProvider] has finished loading from
  /// SharedPreferences before any CRUD operation proceeds.
  Future<void> _ensureInitialized() async {
    await _initDone;
  }

  /// Persists the current goals list to SharedPreferences.
  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        jsonEncode(state.goals.map((g) => g.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Adds a new goal or updates an existing one (matched by [id]).
  ///
  /// Tries the API first; persists to SharedPreferences as fallback or cache.
  Future<void> setGoal(FitnessGoal goal) async {
    await _ensureInitialized();

    // Try API first
    if (_apiClient != null) {
      try {
        await _apiClient!.post(
          ApiConstants.fitnessGoals,
          body: goal.toJson(),
        );
      } catch (_) {
        // API failed, proceed with local save as fallback
      }
    }

    // Always persist locally
    final goals = [...state.goals];
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      goals[index] = goal;
    } else {
      goals.add(goal);
    }
    state = state.copyWith(goals: goals);
    await _saveGoals();
  }

  /// Removes a goal by [goalId].
  ///
  /// Tries the API first; persists to SharedPreferences as fallback or cache.
  Future<void> removeGoal(String goalId) async {
    await _ensureInitialized();

    // Try API first
    if (_apiClient != null) {
      try {
        await _apiClient!.delete(ApiConstants.fitnessGoal(goalId));
      } catch (_) {
        // API failed, proceed with local save as fallback
      }
    }

    // Always persist locally
    final goals = state.goals.where((g) => g.id != goalId).toList();
    state = state.copyWith(goals: goals);
    await _saveGoals();
  }

  /// Removes all goals.
  Future<void> clearAllGoals() async {
    await _ensureInitialized();
    state = state.copyWith(goals: []);
    await _saveGoals();
  }

  // ---------------------------------------------------------------------------
  // Progress calculation
  // ---------------------------------------------------------------------------

  /// Recalculates [currentValue] for every goal based on the latest analytics
  /// data and persists the updated values.
  Future<void> updateProgress({
    List<String> heatmapDates = const [],
    List<VolumePoint> volumeHistory = const [],
    List<PersonalRecord> prs = const [],
  }) async {
    await _ensureInitialized();
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day - 7);

    final updated = state.goals.map((goal) {
      double currentValue;

      switch (goal.type) {
        case GoalType.sessions:
          // Count completed workout dates in the last 7 days.
          currentValue = heatmapDates
              .where((dateStr) {
                final date = DateTime.tryParse(dateStr);
                return date != null &&
                    !date.isBefore(sevenDaysAgo) &&
                    !date.isAfter(now);
              })
              .length
              .toDouble();
          break;

        case GoalType.volume:
          // Sum training volume from the last 7 days.
          currentValue = volumeHistory
              .where((vp) =>
                  !vp.date.isBefore(sevenDaysAgo) && !vp.date.isAfter(now))
              .fold<double>(0.0, (sum, vp) => sum + vp.volume);
          break;

        case GoalType.pr:
          // Has the user attained at least one personal record?
          currentValue = prs.isNotEmpty ? 1.0 : 0.0;
          break;
      }

      if (goal.currentValue == currentValue) return goal;
      return goal.copyWith(currentValue: currentValue);
    }).toList();

    state = state.copyWith(goals: updated);
    await _saveGoals();
  }
}
