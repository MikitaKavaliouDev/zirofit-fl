import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Holds the current state of dashboard prompt visibility toggles.
///
/// Each boolean represents whether the corresponding banner has been
/// *dismissed* (mirroring the `SharedPreferences` keys).  The UI toggles
/// expose the inverse — whether the banner is *shown*.
class DashboardPromptsState {
  final bool coachBannerDismissed;
  final bool checkInBannerDismissed;
  final bool isLoading;
  final String? error;

  const DashboardPromptsState({
    this.coachBannerDismissed = false,
    this.checkInBannerDismissed = false,
    this.isLoading = false,
    this.error,
  });

  DashboardPromptsState copyWith({
    bool? coachBannerDismissed,
    bool? checkInBannerDismissed,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DashboardPromptsState(
      coachBannerDismissed:
          coachBannerDismissed ?? this.coachBannerDismissed,
      checkInBannerDismissed:
          checkInBannerDismissed ?? this.checkInBannerDismissed,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// SharedPreferences keys
// ---------------------------------------------------------------------------

const _kCoachBannerDismissed = 'coachBannerDismissed';
const _kCheckInBannerDismissed = 'checkInBannerDismissed';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages dashboard prompt dismissal toggles, persisted via SharedPreferences.
///
/// The raw stored value indicates whether a banner has been *dismissed*.
/// UI consumers typically invert the value to display a "shown" state.
class DashboardPromptsNotifier extends StateNotifier<DashboardPromptsState> {
  DashboardPromptsNotifier() : super(const DashboardPromptsState());

  /// Loads both persisted values from SharedPreferences.
  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();

      state = DashboardPromptsState(
        coachBannerDismissed:
            prefs.getBool(_kCoachBannerDismissed) ?? false,
        checkInBannerDismissed:
            prefs.getBool(_kCheckInBannerDismissed) ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sets whether the "Need a Coach?" banner is dismissed.
  Future<void> setCoachBannerDismissed(bool dismissed) async {
    state = state.copyWith(coachBannerDismissed: dismissed, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCoachBannerDismissed, dismissed);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Sets whether the "Weekly Check-in" banner is dismissed.
  Future<void> setCheckInBannerDismissed(bool dismissed) async {
    state =
        state.copyWith(checkInBannerDismissed: dismissed, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCheckInBannerDismissed, dismissed);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // -- Convenience helpers for "shown" (inverse of dismissed) --------------

  /// Convenience: sets the coach banner *shown* state (inverts dismissed).
  Future<void> setCoachBannerShown(bool shown) async {
    await setCoachBannerDismissed(!shown);
  }

  /// Convenience: sets the check-in banner *shown* state (inverts dismissed).
  Future<void> setCheckInBannerShown(bool shown) async {
    await setCheckInBannerDismissed(!shown);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dashboardPromptsProvider = StateNotifierProvider<
    DashboardPromptsNotifier, DashboardPromptsState>((ref) {
  return DashboardPromptsNotifier();
});
