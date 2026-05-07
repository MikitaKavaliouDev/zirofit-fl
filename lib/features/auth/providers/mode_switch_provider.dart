import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

/// Represents the current display mode.
///
/// - [trainer]: Trainer-oriented UI and auth context.
/// - [personal]: Client/personal UI and auth context.
enum ModeState {
  trainer,
  personal,
}

/// Provider for the mode switch state.
///
/// Watched by the router to determine the correct shell and dashboard
/// route for the currently active mode.
final modeSwitchProvider =
    StateNotifierProvider<ModeSwitchNotifier, ModeState>(
  (ref) => ModeSwitchNotifier(ref),
);

/// Manages switching between [ModeState.trainer] and [ModeState.personal].
///
/// Persists the mode preference in [SharedPreferences] so the choice
/// survives app restarts.  Each mode maintains its own auth token set
/// in [SecureStorage], allowing a user to be logged in as a trainer
/// and as a client simultaneously.
class ModeSwitchNotifier extends StateNotifier<ModeState> {
  final Ref _ref;

  ModeSwitchNotifier(this._ref) : super(ModeState.trainer);

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Load the persisted mode preference (defaults to [ModeState.trainer]).
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_mode');
    if (saved != null) {
      state = saved == 'personal' ? ModeState.personal : ModeState.trainer;
    }
  }

  // ---------------------------------------------------------------------------
  // Mode switching
  // ---------------------------------------------------------------------------

  /// Toggle between [ModeState.trainer] and [ModeState.personal].
  ///
  /// The current mode's auth tokens are backed up to [SharedPreferences]
  /// under a mode-specific key, then the new mode's tokens are restored
  /// into [SecureStorage].  Finally the auth notifier is re-initialized
  /// so the app picks up the new identity.
  Future<void> switchMode() async {
    final newMode =
        state == ModeState.trainer ? ModeState.personal : ModeState.trainer;
    final secureStorage = _ref.read(secureStorageProvider);
    final prefs = await SharedPreferences.getInstance();

    // -- 1.  Backup current mode's tokens --
    final currentAccess = await secureStorage.getAccessToken();
    final currentRefresh = await secureStorage.getRefreshToken();
    if (currentAccess != null) {
      await prefs.setString(
        '${_modePrefix(state)}_access_token',
        currentAccess,
      );
      await prefs.setString(
        '${_modePrefix(state)}_refresh_token',
        currentRefresh ?? '',
      );
    }

    // -- 2.  Clear and restore the new mode's tokens --
    await secureStorage.clearTokens();
    final newAccess = prefs.getString('${_modePrefix(newMode)}_access_token');
    final newRefresh =
        prefs.getString('${_modePrefix(newMode)}_refresh_token');
    if (newAccess != null &&
        newRefresh != null &&
        newRefresh.isNotEmpty) {
      await secureStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
    }

    // -- 3.  Persist mode preference --
    state = newMode;
    await prefs.setString('app_mode', _modePrefix(newMode));

    // -- 4.  Re-initialise auth with the new token set --
    await _ref.read(authProvider.notifier).initialize();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// SharedPreferences key prefix for the given [mode].
  String _modePrefix(ModeState mode) =>
      mode == ModeState.trainer ? 'trainer' : 'personal';
}
