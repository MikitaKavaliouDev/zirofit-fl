import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/features/progress/models/analytics_widget_config.dart';

/// Provider for managing analytics widget visibility and ordering.
///
/// Stored in SharedPreferences as JSON, mirroring iOS @AppStorage behavior.
final widgetConfigProvider =
    StateNotifierProvider<WidgetConfigNotifier, List<AnalyticsWidgetConfig>>(
        (ref) {
  return WidgetConfigNotifier();
});

class WidgetConfigNotifier extends StateNotifier<List<AnalyticsWidgetConfig>> {
  static const String _storageKey = 'analytics_widgets';

  WidgetConfigNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final list = (jsonDecode(jsonString) as List)
            .map((e) =>
                AnalyticsWidgetConfig.fromJson(e as Map<String, dynamic>))
            .toList();
        state = _mergeDefaults(list);
        return;
      } catch (_) {
        // Corrupted data — start fresh.
      }
    }
    state = List.from(AnalyticsWidgetConfig.defaults);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        jsonEncode(state.map((w) => w.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Merges loaded widgets with defaults to ensure new widget types appear.
  List<AnalyticsWidgetConfig> _mergeDefaults(List<AnalyticsWidgetConfig> loaded) {
    final merged = [...loaded];
    for (final defaultWidget in AnalyticsWidgetConfig.defaults) {
      if (!merged.any((w) => w.type == defaultWidget.type)) {
        merged.add(defaultWidget);
      }
    }
    merged.sort((a, b) => a.order.compareTo(b.order));
    return merged;
  }

  /// Toggles visibility of a widget by type.
  Future<void> toggleVisibility(AnalyticsWidgetType type) async {
    state = state.map((w) {
      if (w.type == type) {
        return w.copyWith(isVisible: !w.isVisible);
      }
      return w;
    }).toList();
    await _save();
  }

  /// Sets visibility of a widget.
  Future<void> setVisibility(AnalyticsWidgetType type, bool visible) async {
    state = state.map((w) {
      if (w.type == type) {
        return w.copyWith(isVisible: visible);
      }
      return w;
    }).toList();
    await _save();
  }

  /// Removes a widget from the active list.
  Future<void> removeWidget(AnalyticsWidgetType type) async {
    state = state.map((w) {
      if (w.type == type) {
        return w.copyWith(isVisible: false);
      }
      return w;
    }).toList();
    await _save();
  }

  /// Adds a widget (makes it visible) with the next available order.
  Future<void> addWidget(AnalyticsWidgetType type) async {
    state = state.map((w) {
      if (w.type == type) {
        return w.copyWith(isVisible: true, order: state.length);
      }
      return w;
    }).toList();
    await _save();
  }

  /// Reorders widgets (called after drag-and-drop).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final widgets = [...state];
    final moved = widgets.removeAt(oldIndex);
    widgets.insert(newIndex, moved);
    state = widgets.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();
    await _save();
  }
}
