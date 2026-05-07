import 'package:flutter/services.dart';

/// Types of haptic feedback
enum HapticType {
  impactLight,
  impactMedium,
  impactHeavy,
  selection,
  success,
  warning,
  error,
}

/// Centralized haptic feedback service
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _isEnabled = true;

  /// Enable or disable haptic feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Impact feedback - light tap
  Future<void> lightImpact() async {
    if (!_isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Impact feedback - medium tap
  Future<void> mediumImpact() async {
    if (!_isEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Impact feedback - heavy tap
  Future<void> heavyImpact() async {
    if (!_isEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback
  Future<void> selection() async {
    if (!_isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Notification feedback - success
  Future<void> success() async {
    if (!_isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Notification feedback - warning
  Future<void> warning() async {
    if (!_isEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Notification feedback - error
  Future<void> error() async {
    if (!_isEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Generic impact based on type
  Future<void> impact(HapticType type) async {
    if (!_isEnabled) return;
    switch (type) {
      case HapticType.impactLight:
        await HapticFeedback.lightImpact();
      case HapticType.impactMedium:
        await HapticFeedback.mediumImpact();
      case HapticType.impactHeavy:
        await HapticFeedback.heavyImpact();
      case HapticType.selection:
        await HapticFeedback.selectionClick();
      case HapticType.success:
        await HapticFeedback.lightImpact();
      case HapticType.warning:
        await HapticFeedback.mediumImpact();
      case HapticType.error:
        await HapticFeedback.heavyImpact();
    }
  }
}