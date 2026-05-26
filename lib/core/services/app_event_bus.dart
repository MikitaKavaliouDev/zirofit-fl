import 'package:flutter/foundation.dart';

/// Simple event bus for app-wide cross-component events.
///
/// Mirrors iOS NotificationCenter events such as:
/// - `.appUserContextWillChange` → [onAppUserContextWillChange]
/// - client list did change → [onClientListDidChange]
///
/// Uses [ValueNotifier] counters so Riverpod consumers can watch changes
/// without tight coupling between providers.
class AppEventBus {
  static final AppEventBus _instance = AppEventBus._();
  factory AppEventBus() => _instance;
  AppEventBus._();

  // ---------------------------------------------------------------------------
  // appUserContextWillChange – fired when the user switches trainer↔personal
  // ---------------------------------------------------------------------------
  final _appUserContextWillChange = ValueNotifier<int>(0);

  ValueNotifier<int> get onAppUserContextWillChange =>
      _appUserContextWillChange;

  void notifyAppUserContextWillChange() {
    debugPrint('[AppEventBus] appUserContextWillChange');
    _appUserContextWillChange.value++;
  }

  // ---------------------------------------------------------------------------
  // clientListDidChange – fired when an invite succeeds or when re-fetching
  // ---------------------------------------------------------------------------
  final _clientListDidChange = ValueNotifier<int>(0);

  ValueNotifier<int> get onClientListDidChange => _clientListDidChange;

  void notifyClientListDidChange() {
    _clientListDidChange.value++;
  }
}
