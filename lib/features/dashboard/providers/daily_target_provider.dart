import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// DailyTarget model
// ---------------------------------------------------------------------------

class DailyTarget {
  final String id;
  final String title;
  final String? description;
  final String type; // 'steps', 'water', 'calories', 'protein', 'sleep', 'workout', 'custom', 'exercise'
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime date;
  final bool isCompleted;
  final int order;

  const DailyTarget({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    required this.date,
    this.isCompleted = false,
    this.order = 0,
  });

  DailyTarget copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    double? targetValue,
    double? currentValue,
    String? unit,
    DateTime? date,
    bool? isCompleted,
    int? order,
  }) {
    return DailyTarget(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }

  factory DailyTarget.fromJson(Map<String, dynamic> json) => DailyTarget(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        type: json['type'] as String,
        targetValue: (json['target_value'] as num).toDouble(),
        currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String,
        date: DateTime.parse(json['date'] as String),
        isCompleted: (json['is_completed'] as bool?) ?? false,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type,
        'target_value': targetValue,
        'current_value': currentValue,
        'unit': unit,
        'date': date.toIso8601String(),
        'is_completed': isCompleted,
        'order': order,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTarget &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          type == other.type &&
          targetValue == other.targetValue &&
          currentValue == other.currentValue &&
          unit == other.unit &&
          date == other.date &&
          isCompleted == other.isCompleted &&
          order == other.order;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        type,
        targetValue,
        currentValue,
        unit,
        date,
        isCompleted,
        order,
      );

  @override
  String toString() =>
      'DailyTarget(id: $id, title: $title, type: $type, '
      'targetValue: $targetValue, currentValue: $currentValue, '
      'unit: $unit, date: $date, isCompleted: $isCompleted, order: $order)';
}

// ---------------------------------------------------------------------------
// DailyChallenge model
// ---------------------------------------------------------------------------

class DailyChallenge {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final int completedDays;
  final bool isActive;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.totalDays = 7,
    this.completedDays = 0,
    this.isActive = true,
  });

  DailyChallenge copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    int? completedDays,
    bool? isActive,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      completedDays: completedDays ?? this.completedDays,
      isActive: isActive ?? this.isActive,
    );
  }

  double get progress => totalDays > 0 ? (completedDays / totalDays).clamp(0.0, 1.0) : 0.0;

  Duration get remainingTime => endDate.difference(DateTime.now());

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
        id: json['id'] as String,
        title: json['title'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        totalDays: (json['total_days'] as num?)?.toInt() ?? 7,
        completedDays: (json['completed_days'] as num?)?.toInt() ?? 0,
        isActive: (json['is_active'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'total_days': totalDays,
        'completed_days': completedDays,
        'is_active': isActive,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyChallenge &&
          id == other.id &&
          title == other.title &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          totalDays == other.totalDays &&
          completedDays == other.completedDays &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        id, title, startDate, endDate, totalDays, completedDays, isActive,
      );

  @override
  String toString() =>
      'DailyChallenge(id: $id, title: $title, completedDays: $completedDays/$totalDays, isActive: $isActive)';
}

// ---------------------------------------------------------------------------
// Type utilities
// ---------------------------------------------------------------------------

/// Known target types with their default units and icons.
class TargetTypeInfo {
  final String key;
  final String label;
  final String defaultUnit;
  final int sortOrder;

  const TargetTypeInfo({
    required this.key,
    required this.label,
    required this.defaultUnit,
    required this.sortOrder,
  });

  static const List<TargetTypeInfo> all = [
    TargetTypeInfo(key: 'steps', label: 'Steps', defaultUnit: 'steps', sortOrder: 0),
    TargetTypeInfo(key: 'water', label: 'Water', defaultUnit: 'ml', sortOrder: 1),
    TargetTypeInfo(key: 'calories', label: 'Calories', defaultUnit: 'kcal', sortOrder: 2),
    TargetTypeInfo(key: 'protein', label: 'Protein', defaultUnit: 'g', sortOrder: 3),
    TargetTypeInfo(key: 'sleep', label: 'Sleep', defaultUnit: 'hours', sortOrder: 4),
    TargetTypeInfo(key: 'workout', label: 'Workout', defaultUnit: 'min', sortOrder: 5),
    TargetTypeInfo(key: 'exercise', label: 'Exercise', defaultUnit: 'reps', sortOrder: 6),
    TargetTypeInfo(key: 'custom', label: 'Custom', defaultUnit: '', sortOrder: 7),
  ];

  static TargetTypeInfo? fromKey(String key) {
    try {
      return all.firstWhere((t) => t.key == key);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DailyTargetState {
  final List<DailyTarget> targets;
  final bool isLoading;
  final int streak;
  final DailyChallenge? challenge;

  const DailyTargetState({
    this.targets = const [],
    this.isLoading = false,
    this.streak = 0,
    this.challenge,
  });

  DailyTargetState copyWith({
    List<DailyTarget>? targets,
    bool? isLoading,
    int? streak,
    DailyChallenge? challenge,
    bool clearChallenge = false,
  }) {
    return DailyTargetState(
      targets: targets ?? this.targets,
      isLoading: isLoading ?? this.isLoading,
      streak: streak ?? this.streak,
      challenge: clearChallenge ? null : (challenge ?? this.challenge),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DailyTargetNotifier extends StateNotifier<DailyTargetState> {
  final ApiClient? _apiClient;

  DailyTargetNotifier({ApiClient? apiClient})
      : _apiClient = apiClient,
        super(const DailyTargetState());

  static const _storageKey = 'daily_targets';
  static const _challengeKey = 'daily_challenge';

  /// Loads daily targets — tries API first, falls back to SharedPreferences.
  Future<void> loadTargets(DateTime date) async {
    state = state.copyWith(isLoading: true);

    try {
      // --- Try API first ---------------------------------------------------
      if (_apiClient != null) {
        final loaded = await _tryLoadFromApi(date);
        if (loaded) return;
      }

      // --- Fallback: load from SharedPreferences ---------------------------
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);

      if (stored == null) {
        state = state.copyWith(
          targets: [],
          isLoading: false,
          streak: 0,
        );
        return;
      }

      final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
      final allTargets = decoded
          .map((e) => DailyTarget.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter targets matching the requested date
      final dateStr = date.toIso8601String().split('T')[0];
      final filtered = allTargets
          .where((t) => t.date.toIso8601String().split('T')[0] == dateStr)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      // Calculate streak
      final streak = _calculateStreak(allTargets, date);

      // Load challenge
      final challenge = await _loadChallenge(prefs);

      state = state.copyWith(
        targets: filtered,
        isLoading: false,
        streak: streak,
        challenge: challenge,
      );
    } catch (_) {
      state = state.copyWith(targets: [], isLoading: false, streak: 0);
    }
  }

  /// Tries to load targets from the API.
  /// Returns `true` if the API call succeeded and state was updated.
  Future<bool> _tryLoadFromApi(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _apiClient!.get<Map<String, dynamic>>(
        ApiConstants.dailyTargets,
        queryParams: {'date': dateStr},
      );

      final List<dynamic>? rawTargets = response['targets'] as List<dynamic>?;
      if (rawTargets == null) return false;

      final apiTargets = rawTargets
          .map((e) => DailyTarget.fromJson(e as Map<String, dynamic>))
          .toList();

      // Cache API data back to SharedPreferences as local fallback
      final prefs = await SharedPreferences.getInstance();
      final allTargets = await _loadAllTargets(prefs);
      for (final t in apiTargets) {
        final idx = allTargets.indexWhere((at) => at.id == t.id);
        if (idx != -1) {
          allTargets[idx] = t;
        } else {
          allTargets.add(t);
        }
      }
      await _saveAllTargets(prefs, allTargets);

      final streak = (response['streak'] as num?)?.toInt() ??
          _calculateStreak(allTargets, date);

      DailyChallenge? challenge;
      if (response['challenge'] != null) {
        try {
          challenge = DailyChallenge.fromJson(
            response['challenge'] as Map<String, dynamic>,
          );
        } catch (_) {
          // Malformed challenge from API — ignore
        }
      }
      challenge ??= await _loadChallenge(prefs);

      state = state.copyWith(
        targets: apiTargets..sort((a, b) => a.order.compareTo(b.order)),
        isLoading: false,
        streak: streak,
        challenge: challenge,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Adds a new daily target.
  Future<void> addTarget(DailyTarget target) async {
    // Best-effort API call
    if (_apiClient != null) {
      try {
        await _apiClient!.post(
          ApiConstants.dailyTargets,
          body: target.toJson(),
        );
      } catch (_) {
        // API unavailable — proceed with local-only save
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final allTargets = await _loadAllTargets(prefs);

    final orderedTarget = target.copyWith(order: state.targets.length);
    allTargets.add(orderedTarget);
    await _saveAllTargets(prefs, allTargets);

    // Refresh current view if state is empty or date matches the displayed date
    if (state.targets.isEmpty ||
        target.date.toIso8601String().split('T')[0] ==
            state.targets.first.date.toIso8601String().split('T')[0]) {
      state = state.copyWith(targets: [...state.targets, orderedTarget]);
    }
  }

  /// Updates the current progress value for a target by [id].
  Future<void> updateProgress(String id, double value) async {
    // Best-effort API call
    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          '${ApiConstants.dailyTargets}/$id',
          body: {'current_value': value},
        );
      } catch (_) {
        // API unavailable — proceed with local-only save
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final allTargets = await _loadAllTargets(prefs);

    final index = allTargets.indexWhere((t) => t.id == id);
    if (index == -1) return;

    allTargets[index] = allTargets[index].copyWith(currentValue: value);
    await _saveAllTargets(prefs, allTargets);

    // Update state if the target is in the current view
    state = state.copyWith(
      targets: state.targets.map((t) {
        if (t.id == id) return t.copyWith(currentValue: value);
        return t;
      }).toList(),
    );
  }

  /// Toggles the completed state of a target by [id].
  Future<void> toggleCompleted(String id) async {
    // Best-effort API call
    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          '${ApiConstants.dailyTargets}/$id',
          body: {'toggle_completed': true}, // server flips the completed state
        );
      } catch (_) {
        // API unavailable — proceed with local-only save
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final allTargets = await _loadAllTargets(prefs);

    final index = allTargets.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final toggled = !allTargets[index].isCompleted;
    allTargets[index] = allTargets[index].copyWith(isCompleted: toggled);
    await _saveAllTargets(prefs, allTargets);

    // Update state if the target is in the current view
    state = state.copyWith(
      targets: state.targets.map((t) {
        if (t.id == id) return t.copyWith(isCompleted: toggled);
        return t;
      }).toList(),
    );
  }

  /// Removes a target by [id].
  Future<void> removeTarget(String id) async {
    // Best-effort API call
    if (_apiClient != null) {
      try {
        await _apiClient!.delete('${ApiConstants.dailyTargets}/$id');
      } catch (_) {
        // API unavailable — proceed with local-only remove
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final allTargets = await _loadAllTargets(prefs);

    allTargets.removeWhere((t) => t.id == id);
    await _saveAllTargets(prefs, allTargets);

    state = state.copyWith(
      targets: state.targets.where((t) => t.id != id).toList(),
    );
  }

  /// Calculates progress (0.0 - 1.0) for a target by [id].
  double calculateProgress(String id) {
    final target = state.targets.firstWhere((t) => t.id == id);
    if (target.targetValue <= 0) return 0.0;
    return (target.currentValue / target.targetValue).clamp(0.0, 1.0);
  }

  /// Adjusts progress by [delta] (e.g. +1 or -1) for the target with [id].
  Future<void> adjustProgress(String id, double delta) async {
    final target = state.targets.firstWhere((t) => t.id == id);
    final newValue = (target.currentValue + delta).clamp(0.0, target.targetValue);
    await updateProgress(id, newValue);
  }

  /// Reorders targets. Accepts the same arguments as [List.reorder].
  Future<void> reorderTargets(int oldIndex, int newIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final allTargets = await _loadAllTargets(prefs);

    // Reorder in allTargets for persistence
    final currentDateTargets = allTargets
        .where((t) =>
            t.date.toIso8601String().split('T')[0] ==
            state.targets.first.date.toIso8601String().split('T')[0])
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (oldIndex < newIndex) newIndex -= 1;
    final item = currentDateTargets.removeAt(oldIndex);
    currentDateTargets.insert(newIndex, item);

    // Update order values
    for (var i = 0; i < currentDateTargets.length; i++) {
      final idx = allTargets.indexWhere((t) => t.id == currentDateTargets[i].id);
      if (idx != -1) {
        allTargets[idx] = allTargets[idx].copyWith(order: i);
      }
    }

    await _saveAllTargets(prefs, allTargets);

    // Update local state
    final updated = [...state.targets]..sort((a, b) => a.order.compareTo(b.order));
    if (oldIndex < newIndex) newIndex += 1;
    final localItem = updated.removeAt(oldIndex);
    updated.insert(newIndex, localItem);
    for (var i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(order: i);
    }
    state = state.copyWith(targets: updated);
  }

  // ---------------------------------------------------------------------------
  // Challenge management
  // ---------------------------------------------------------------------------

  /// Starts a new 7-day challenge.
  Future<void> startChallenge({String title = '7-Day Streak'}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final challenge = DailyChallenge(
      id: const Uuid().v4(),
      title: title,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      totalDays: 7,
      completedDays: 0,
      isActive: true,
    );

    await prefs.setString(_challengeKey, jsonEncode(challenge.toJson()));
    state = state.copyWith(challenge: challenge);
  }

  /// Marks today as completed for the active challenge.
  Future<void> completeChallengeDay() async {
    if (state.challenge == null || !state.challenge!.isActive) return;

    final updated = state.challenge!.copyWith(
      completedDays: state.challenge!.completedDays + 1,
    );

    // If all days completed, mark challenge as done
    final finalState = updated.completedDays >= updated.totalDays
        ? updated.copyWith(isActive: false)
        : updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_challengeKey, jsonEncode(finalState.toJson()));
    state = state.copyWith(challenge: finalState);
  }

  // ---------------------------------------------------------------------------
  // Streak calculation
  // ---------------------------------------------------------------------------

  /// Counts consecutive days (ending at [today]) where all targets were completed.
  int _calculateStreak(List<DailyTarget> allTargets, DateTime today) {
    if (allTargets.isEmpty) return 0;

    int streak = 0;
    var checkDate = today;

    for (var i = 0; i < 365; i++) {
      final dateStr = checkDate.toIso8601String().split('T')[0];
      final dayTargets = allTargets
          .where((t) => t.date.toIso8601String().split('T')[0] == dateStr)
          .toList();

      if (dayTargets.isEmpty) break; // No targets set for this day

      final allCompleted = dayTargets.every((t) => t.isCompleted);
      if (!allCompleted) break;

      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<List<DailyTarget>> _loadAllTargets(SharedPreferences prefs) async {
    final stored = prefs.getString(_storageKey);
    if (stored == null) return [];

    final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
    return decoded
        .map((e) => DailyTarget.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllTargets(
    SharedPreferences prefs,
    List<DailyTarget> targets,
  ) async {
    final encoded = jsonEncode(targets.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<DailyChallenge?> _loadChallenge(SharedPreferences prefs) async {
    final stored = prefs.getString(_challengeKey);
    if (stored == null) return null;

    try {
      final challenge = DailyChallenge.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      if (!challenge.isActive) return null;
      if (challenge.endDate.isBefore(DateTime.now())) return null;
      return challenge;
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dailyTargetProvider =
    StateNotifierProvider<DailyTargetNotifier, DailyTargetState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DailyTargetNotifier(apiClient: apiClient);
});
