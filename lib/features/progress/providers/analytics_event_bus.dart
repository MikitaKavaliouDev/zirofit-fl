import 'package:flutter/foundation.dart';

/// Simple event bus for analytics-related events.
///
/// Used by [PersonalAnalyticsScreen] to auto-refresh when a workout is
/// completed or a check-in is submitted, mirroring iOS
/// [PersonalAnalyticsViewModel]'s notification-based refresh mechanism.
class AnalyticsEventBus {
  static final AnalyticsEventBus _instance = AnalyticsEventBus._();
  factory AnalyticsEventBus() => _instance;
  AnalyticsEventBus._();

  final _workoutCompleted = ValueNotifier<int>(0);
  final _checkInSubmitted = ValueNotifier<int>(0);

  ValueNotifier<int> get onWorkoutCompleted => _workoutCompleted;
  ValueNotifier<int> get onCheckInSubmitted => _checkInSubmitted;

  void notifyWorkoutCompleted() => _workoutCompleted.value++;
  void notifyCheckInSubmitted() => _checkInSubmitted.value++;
}
