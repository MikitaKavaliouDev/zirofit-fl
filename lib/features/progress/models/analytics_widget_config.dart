/// Types of analytics widgets available in the Personal Analytics screen.
///
/// Mirrors iOS [AnalyticsWidgetType].
enum AnalyticsWidgetType {
  workoutsPerWeek,
  consistency,
  volumeProgression,
  muscleFocus,
  prs,
  heatMap,
  weightHistory,
  insights,
  goal,
  recovery;

  String get displayName {
    switch (this) {
      case AnalyticsWidgetType.workoutsPerWeek:
        return 'Workouts Per Week';
      case AnalyticsWidgetType.consistency:
        return 'Consistency';
      case AnalyticsWidgetType.volumeProgression:
        return 'Volume Progression';
      case AnalyticsWidgetType.muscleFocus:
        return 'Muscle Focus';
      case AnalyticsWidgetType.prs:
        return 'Personal Records';
      case AnalyticsWidgetType.heatMap:
        return 'Activity Heat Map';
      case AnalyticsWidgetType.weightHistory:
        return 'Weight History';
      case AnalyticsWidgetType.insights:
        return 'Personal Insights';
      case AnalyticsWidgetType.goal:
        return 'Fitness Goal';
      case AnalyticsWidgetType.recovery:
        return 'Recovery & Load';
    }
  }

  String get icon {
    switch (this) {
      case AnalyticsWidgetType.workoutsPerWeek:
        return 'directions_run';
      case AnalyticsWidgetType.consistency:
        return 'bar_chart';
      case AnalyticsWidgetType.volumeProgression:
        return 'show_chart';
      case AnalyticsWidgetType.muscleFocus:
        return 'fitness_center';
      case AnalyticsWidgetType.prs:
        return 'emoji_events';
      case AnalyticsWidgetType.heatMap:
        return 'calendar_month';
      case AnalyticsWidgetType.weightHistory:
        return 'monitor_weight';
      case AnalyticsWidgetType.insights:
        return 'tips_and_updates';
      case AnalyticsWidgetType.goal:
        return 'track_changes';
      case AnalyticsWidgetType.recovery:
        return 'favorite';
    }
  }
}

/// Configuration for a single analytics widget in the user's dashboard.
///
/// Mirrors iOS [AnalyticsWidget].
class AnalyticsWidgetConfig {
  final AnalyticsWidgetType type;
  final bool isVisible;
  final int order;

  const AnalyticsWidgetConfig({
    required this.type,
    this.isVisible = true,
    required this.order,
  });

  AnalyticsWidgetConfig copyWith({
    AnalyticsWidgetType? type,
    bool? isVisible,
    int? order,
  }) {
    return AnalyticsWidgetConfig(
      type: type ?? this.type,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'isVisible': isVisible,
        'order': order,
      };

  factory AnalyticsWidgetConfig.fromJson(Map<String, dynamic> json) =>
      AnalyticsWidgetConfig(
        type: AnalyticsWidgetType.values.firstWhere(
          (e) => e.name == json['type'] as String,
        ),
        isVisible: json['isVisible'] as bool? ?? true,
        order: json['order'] as int,
      );

  static const List<AnalyticsWidgetConfig> defaults = [
    AnalyticsWidgetConfig(type: AnalyticsWidgetType.workoutsPerWeek, order: 0),
    AnalyticsWidgetConfig(type: AnalyticsWidgetType.consistency, order: 1),
    AnalyticsWidgetConfig(
        type: AnalyticsWidgetType.volumeProgression, order: 2),
    AnalyticsWidgetConfig(type: AnalyticsWidgetType.muscleFocus, order: 3),
    AnalyticsWidgetConfig(type: AnalyticsWidgetType.prs, order: 4),
    AnalyticsWidgetConfig(type: AnalyticsWidgetType.heatMap, order: 5),
    AnalyticsWidgetConfig(type: AnalyticsWidgetType.weightHistory, order: 6),
    AnalyticsWidgetConfig(type: AnalyticsWidgetType.insights, order: 7),
    AnalyticsWidgetConfig(type: AnalyticsWidgetType.goal, order: 8),
    AnalyticsWidgetConfig(type: AnalyticsWidgetType.recovery, order: 9),
  ];
}
