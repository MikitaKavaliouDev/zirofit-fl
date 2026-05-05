import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// DailyTarget model
// ---------------------------------------------------------------------------

class DailyTarget {
  final String id;
  final String title;
  final String? description;
  final String type; // 'steps', 'water', 'calories', 'protein', 'sleep', 'workout', 'custom'
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime date;
  final bool isCompleted;

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
          isCompleted == other.isCompleted;

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
      );

  @override
  String toString() =>
      'DailyTarget(id: $id, title: $title, type: $type, '
      'targetValue: $targetValue, currentValue: $currentValue, '
      'unit: $unit, date: $date, isCompleted: $isCompleted)';
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DailyTargetState {
  final List<DailyTarget> targets;
  final bool isLoading;

  const DailyTargetState({
    this.targets = const [],
    this.isLoading = false,
  });

  DailyTargetState copyWith({
    List<DailyTarget>? targets,
    bool? isLoading,
  }) {
    return DailyTargetState(
      targets: targets ?? this.targets,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DailyTargetNotifier extends StateNotifier<DailyTargetState> {
  DailyTargetNotifier() : super(const DailyTargetState());

  static const _storageKey = 'daily_targets';

  /// Loads daily targets from SharedPreferences for a given [date].
  Future<void> loadTargets(DateTime date) async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);

      if (stored == null) {
        state = state.copyWith(targets: [], isLoading: false);
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
          .toList();

      state = state.copyWith(targets: filtered, isLoading: false);
    } catch (_) {
      state = state.copyWith(targets: [], isLoading: false);
    }
  }

  /// Adds a new daily target.
  Future<void> addTarget(DailyTarget target) async {
    final prefs = await SharedPreferences.getInstance();
    final allTargets = await _loadAllTargets(prefs);

    allTargets.add(target);
    await _saveAllTargets(prefs, allTargets);

    // Refresh current view if state is empty or date matches the displayed date
    if (state.targets.isEmpty ||
        target.date.toIso8601String().split('T')[0] ==
            state.targets.first.date.toIso8601String().split('T')[0]) {
      state = state.copyWith(targets: [...state.targets, target]);
    }
  }

  /// Updates the current progress value for a target by [id].
  Future<void> updateProgress(String id, double value) async {
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
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dailyTargetProvider =
    StateNotifierProvider<DailyTargetNotifier, DailyTargetState>((ref) {
  return DailyTargetNotifier();
});
