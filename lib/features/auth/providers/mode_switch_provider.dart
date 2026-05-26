import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/services/app_event_bus.dart';

/// Represents the current display mode.
///
/// This is a **UI-only** preference — it does NOT change auth sessions
/// or swap tokens. The mode only alters the visual presentation of the
/// tab bar icons/labels and certain screens.
///
/// - [trainer]: Trainer-oriented UI.
/// - [personal]: Client/personal UI.
enum AppMode {
  trainer,
  personal,
}

/// Provider for the mode switch state.
///
/// Watched by shells to determine tab labels, icons, and colours.
/// Mode changes are instant (no auth re-init, no token swap).
final modeSwitchProvider =
    StateNotifierProvider<ModeSwitchNotifier, AppMode>(
  (ref) => ModeSwitchNotifier(),
);

/// Manages switching between [AppMode.trainer] and [AppMode.personal].
///
/// This is purely a display preference. Changes are instant —
/// no token swap, no auth re-initialization. The preference is
/// persisted in [SharedPreferences] to survive app restarts.
class ModeSwitchNotifier extends StateNotifier<AppMode> {
  ModeSwitchNotifier() : super(AppMode.trainer);

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Load the persisted mode preference (defaults to [AppMode.trainer]).
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_mode');
    if (saved != null) {
      state = saved == 'personal' ? AppMode.personal : AppMode.trainer;
    }
  }

  // ---------------------------------------------------------------------------
  // Mode switching (UI only)
  // ---------------------------------------------------------------------------

  /// Toggle between [AppMode.trainer] and [AppMode.personal].
  ///
  /// Instant — no auth operations, no loading state. Just updates
  /// the display mode and persists the preference.
  Future<void> switchMode() async {
    final newMode =
        state == AppMode.trainer ? AppMode.personal : AppMode.trainer;

    // Notify listeners before changing state (iOS .appUserContextWillChange)
    AppEventBus().notifyAppUserContextWillChange();

    state = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_mode', newMode.name);
  }

  /// Force-set the display mode to match [mode].
  Future<void> setMode(AppMode mode) async {
    if (state == mode) return;

    // Notify listeners before changing state (iOS .appUserContextWillChange)
    AppEventBus().notifyAppUserContextWillChange();

    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_mode', mode.name);
  }
}
