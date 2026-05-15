import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class PreferencesState {
  final String themeMode; // 'light' | 'dark' | 'system'
  final String language; // 'en' | 'es' | 'fr' | 'de' | 'pt' | 'it' | 'ja' | 'zh'
  final bool pushNotifications;
  final bool emailNotifications;
  final bool workoutReminders;
  final bool bookingAlerts;
  final bool showTrainerNotificationsInClientMode;
  final bool showClientNotificationsInTrainerMode;
  final bool isCustomModeEnabled;
  final bool isDailyTargetsEnabled;
  final bool isVoiceFeedbackEnabled;
  final bool isRoutinesEnabled;
  final bool syncToAppleCalendar;
  final String sharingDuration; // '30_days' | '90_days' | 'forever'
  final bool isLoading;
  final String? error;

  const PreferencesState({
    this.themeMode = 'system',
    this.language = 'en',
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.workoutReminders = true,
    this.bookingAlerts = true,
    this.showTrainerNotificationsInClientMode = true,
    this.showClientNotificationsInTrainerMode = true,
    this.isCustomModeEnabled = false,
    this.isDailyTargetsEnabled = false,
    this.isVoiceFeedbackEnabled = false,
    this.isRoutinesEnabled = false,
    this.syncToAppleCalendar = false,
    this.sharingDuration = 'forever',
    this.isLoading = false,
    this.error,
  });

  PreferencesState copyWith({
    String? themeMode,
    String? language,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? workoutReminders,
    bool? bookingAlerts,
    bool? showTrainerNotificationsInClientMode,
    bool? showClientNotificationsInTrainerMode,
    bool? isCustomModeEnabled,
    bool? isDailyTargetsEnabled,
    bool? isVoiceFeedbackEnabled,
    bool? isRoutinesEnabled,
    bool? syncToAppleCalendar,
    String? sharingDuration,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PreferencesState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      workoutReminders: workoutReminders ?? this.workoutReminders,
      bookingAlerts: bookingAlerts ?? this.bookingAlerts,
      showTrainerNotificationsInClientMode:
          showTrainerNotificationsInClientMode ??
              this.showTrainerNotificationsInClientMode,
      showClientNotificationsInTrainerMode:
          showClientNotificationsInTrainerMode ??
              this.showClientNotificationsInTrainerMode,
      isCustomModeEnabled:
          isCustomModeEnabled ?? this.isCustomModeEnabled,
      isDailyTargetsEnabled:
          isDailyTargetsEnabled ?? this.isDailyTargetsEnabled,
      isVoiceFeedbackEnabled:
          isVoiceFeedbackEnabled ?? this.isVoiceFeedbackEnabled,
      isRoutinesEnabled: isRoutinesEnabled ?? this.isRoutinesEnabled,
      syncToAppleCalendar:
          syncToAppleCalendar ?? this.syncToAppleCalendar,
      sharingDuration: sharingDuration ?? this.sharingDuration,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// SharedPreferences keys
// ---------------------------------------------------------------------------

const _kThemeMode = 'pref_themeMode';
const _kLanguage = 'pref_language';
const _kPushNotifications = 'pref_pushNotifications';
const _kEmailNotifications = 'pref_emailNotifications';
const _kWorkoutReminders = 'pref_workoutReminders';
const _kBookingAlerts = 'pref_bookingAlerts';
const _kShowTrainerNotificationsInClientMode =
    'pref_showTrainerNotificationsInClientMode';
const _kShowClientNotificationsInTrainerMode =
    'pref_showClientNotificationsInTrainerMode';
const _kIsCustomModeEnabled = 'pref_isCustomModeEnabled';
const _kIsDailyTargetsEnabled = 'pref_isDailyTargetsEnabled';
const _kIsVoiceFeedbackEnabled = 'pref_isVoiceFeedbackEnabled';
const _kIsRoutinesEnabled = 'pref_isRoutinesEnabled';
const _kSyncToAppleCalendar = 'pref_syncToAppleCalendar';
const _kSharingDuration = 'pref_sharingDuration';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class PreferencesNotifier extends StateNotifier<PreferencesState> {
  final ApiClient? _apiClient;

  PreferencesNotifier({ApiClient? apiClient})
      : _apiClient = apiClient,
        super(const PreferencesState());

  // -- Load preferences from disk --

  /// Reads all stored preference values from SharedPreferences.
  /// Falls back to defaults when a key is missing.
  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Try API first
      if (_apiClient != null) {
        try {
          final response = await _apiClient!.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          );
          final data = response['data'] ?? response;
          if (data is Map<String, dynamic>) {
            state = PreferencesState(
              themeMode: data['theme_mode'] as String? ?? 'system',
              language: data['language'] as String? ?? 'en',
              pushNotifications:
                  data['push_notifications'] as bool? ?? true,
              emailNotifications:
                  data['email_notifications'] as bool? ?? true,
              workoutReminders:
                  data['workout_reminders'] as bool? ?? true,
              bookingAlerts: data['booking_alerts'] as bool? ?? true,
              showTrainerNotificationsInClientMode:
                  data['show_trainer_notifications_in_client_mode']
                          as bool? ??
                      true,
              showClientNotificationsInTrainerMode:
                  data['show_client_notifications_in_trainer_mode']
                          as bool? ??
                      true,
              isCustomModeEnabled:
                  data['is_custom_mode_enabled'] as bool? ?? false,
              isDailyTargetsEnabled:
                  data['is_daily_targets_enabled'] as bool? ?? false,
              isVoiceFeedbackEnabled:
                  data['is_voice_feedback_enabled'] as bool? ?? false,
              isRoutinesEnabled:
                  data['is_routines_enabled'] as bool? ?? false,
              syncToAppleCalendar:
                  data['sync_to_apple_calendar'] as bool? ?? false,
              sharingDuration:
                  data['sharing_duration'] as String? ?? 'forever',
              isLoading: false,
            );

            // Persist API response to SharedPrefs
            final prefs = await SharedPreferences.getInstance();
            await Future.wait([
              prefs.setString(_kThemeMode, state.themeMode),
              prefs.setString(_kLanguage, state.language),
              prefs.setBool(_kPushNotifications, state.pushNotifications),
              prefs.setBool(
                  _kEmailNotifications, state.emailNotifications),
              prefs.setBool(
                  _kWorkoutReminders, state.workoutReminders),
              prefs.setBool(_kBookingAlerts, state.bookingAlerts),
              prefs.setBool(
                  _kShowTrainerNotificationsInClientMode,
                  state.showTrainerNotificationsInClientMode),
              prefs.setBool(
                  _kShowClientNotificationsInTrainerMode,
                  state.showClientNotificationsInTrainerMode),
              prefs.setBool(
                  _kIsCustomModeEnabled, state.isCustomModeEnabled),
              prefs.setBool(
                  _kIsDailyTargetsEnabled, state.isDailyTargetsEnabled),
              prefs.setBool(
                  _kIsVoiceFeedbackEnabled, state.isVoiceFeedbackEnabled),
              prefs.setBool(
                  _kIsRoutinesEnabled, state.isRoutinesEnabled),
              prefs.setBool(
                  _kSyncToAppleCalendar, state.syncToAppleCalendar),
              prefs.setString(
                  _kSharingDuration, state.sharingDuration),
            ]);
            return;
          }
        } catch (_) {
          // API failed, fall through to SharedPrefs
        }
      }

      // Fallback: existing SharedPrefs loading code
      final prefs = await SharedPreferences.getInstance();

      state = PreferencesState(
        themeMode: prefs.getString(_kThemeMode) ?? 'system',
        language: prefs.getString(_kLanguage) ?? 'en',
        pushNotifications:
            prefs.getBool(_kPushNotifications) ?? true,
        emailNotifications:
            prefs.getBool(_kEmailNotifications) ?? true,
        workoutReminders:
            prefs.getBool(_kWorkoutReminders) ?? true,
        bookingAlerts: prefs.getBool(_kBookingAlerts) ?? true,
        showTrainerNotificationsInClientMode:
            prefs.getBool(_kShowTrainerNotificationsInClientMode) ??
                true,
        showClientNotificationsInTrainerMode:
            prefs.getBool(_kShowClientNotificationsInTrainerMode) ??
                true,
        isCustomModeEnabled:
            prefs.getBool(_kIsCustomModeEnabled) ?? false,
        isDailyTargetsEnabled:
            prefs.getBool(_kIsDailyTargetsEnabled) ?? false,
        isVoiceFeedbackEnabled:
            prefs.getBool(_kIsVoiceFeedbackEnabled) ?? false,
        isRoutinesEnabled:
            prefs.getBool(_kIsRoutinesEnabled) ?? false,
        syncToAppleCalendar:
            prefs.getBool(_kSyncToAppleCalendar) ?? false,
        sharingDuration:
            prefs.getString(_kSharingDuration) ?? 'forever',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Theme mode --

  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeMode, mode);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'theme_mode': mode},
        );
      } catch (_) {}
    }
  }

  // -- Language --

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguage, language);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'language': language},
        );
      } catch (_) {}
    }
  }

  // -- Notification toggles --

  Future<void> setPushNotifications(bool enabled) async {
    state =
        state.copyWith(pushNotifications: enabled, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPushNotifications, enabled);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'push_notifications': enabled},
        );
      } catch (_) {}
    }
  }

  Future<void> setEmailNotifications(bool enabled) async {
    state =
        state.copyWith(emailNotifications: enabled, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEmailNotifications, enabled);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'email_notifications': enabled},
        );
      } catch (_) {}
    }
  }

  Future<void> setWorkoutReminders(bool enabled) async {
    state =
        state.copyWith(workoutReminders: enabled, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kWorkoutReminders, enabled);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'workout_reminders': enabled},
        );
      } catch (_) {}
    }
  }

  Future<void> setBookingAlerts(bool enabled) async {
    state = state.copyWith(bookingAlerts: enabled, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kBookingAlerts, enabled);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'booking_alerts': enabled},
        );
      } catch (_) {}
    }
  }

  Future<void> setShowTrainerNotificationsInClientMode(
      bool enabled) async {
    state = state.copyWith(
      showTrainerNotificationsInClientMode: enabled,
      clearError: true,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _kShowTrainerNotificationsInClientMode,
        enabled,
      );
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {
            'show_trainer_notifications_in_client_mode': enabled,
          },
        );
      } catch (_) {}
    }
  }

  Future<void> setShowClientNotificationsInTrainerMode(
      bool enabled) async {
    state = state.copyWith(
      showClientNotificationsInTrainerMode: enabled,
      clearError: true,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _kShowClientNotificationsInTrainerMode,
        enabled,
      );
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {
            'show_client_notifications_in_trainer_mode': enabled,
          },
        );
      } catch (_) {}
    }
  }

  // -- Feature toggles --

  Future<void> setCustomModeEnabled(bool enabled) async {
    state = state.copyWith(
        isCustomModeEnabled: enabled, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsCustomModeEnabled, enabled);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'is_custom_mode_enabled': enabled},
        );
      } catch (_) {}
    }
  }

  Future<void> setDailyTargetsEnabled(bool enabled) async {
    state = state.copyWith(
        isDailyTargetsEnabled: enabled, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsDailyTargetsEnabled, enabled);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'is_daily_targets_enabled': enabled},
        );
      } catch (_) {}
    }
  }

  Future<void> setVoiceFeedbackEnabled(bool enabled) async {
    state = state.copyWith(
        isVoiceFeedbackEnabled: enabled, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsVoiceFeedbackEnabled, enabled);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'is_voice_feedback_enabled': enabled},
        );
      } catch (_) {}
    }
  }

  Future<void> setRoutinesEnabled(bool enabled) async {
    state =
        state.copyWith(isRoutinesEnabled: enabled, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsRoutinesEnabled, enabled);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'is_routines_enabled': enabled},
        );
      } catch (_) {}
    }
  }

  // -- Calendar sync --

  Future<void> setSyncToAppleCalendar(bool enabled) async {
    state = state.copyWith(
        syncToAppleCalendar: enabled, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSyncToAppleCalendar, enabled);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'sync_to_apple_calendar': enabled},
        );
      } catch (_) {}
    }
  }

  // -- Sharing duration --

  Future<void> setSharingDuration(String duration) async {
    state =
        state.copyWith(sharingDuration: duration, clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSharingDuration, duration);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }

    if (_apiClient != null) {
      try {
        await _apiClient!.put(
          ApiConstants.userPreferences,
          body: {'sharing_duration': duration},
        );
      } catch (_) {}
    }
  }

  // -- Reset all preferences to defaults --

  Future<void> resetToDefaults() async {
    state = state.copyWith(clearError: true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.remove(_kThemeMode),
        prefs.remove(_kLanguage),
        prefs.remove(_kPushNotifications),
        prefs.remove(_kEmailNotifications),
        prefs.remove(_kWorkoutReminders),
        prefs.remove(_kBookingAlerts),
        prefs.remove(_kShowTrainerNotificationsInClientMode),
        prefs.remove(_kShowClientNotificationsInTrainerMode),
        prefs.remove(_kIsCustomModeEnabled),
        prefs.remove(_kIsDailyTargetsEnabled),
        prefs.remove(_kIsVoiceFeedbackEnabled),
        prefs.remove(_kIsRoutinesEnabled),
        prefs.remove(_kSyncToAppleCalendar),
        prefs.remove(_kSharingDuration),
      ]);

      state = const PreferencesState();
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
    }
  }

  // -- Helpers --

  String _extractErrorMessage(dynamic error) {
    // SharedPreferences errors are typically platform-level issues.
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, PreferencesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PreferencesNotifier(apiClient: apiClient);
});
