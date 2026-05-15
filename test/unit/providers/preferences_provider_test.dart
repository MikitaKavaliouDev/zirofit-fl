import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  // ===========================================================================
  // Without API client (null) — existing SharedPrefs behavior
  // ===========================================================================

  group('without API client', () {
    late PreferencesNotifier notifier;

    setUp(() {
      notifier = PreferencesNotifier();
    });

    test('loadPreferences loads defaults when SharedPrefs is empty', () async {
      SharedPreferences.setMockInitialValues({});

      await notifier.loadPreferences();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.themeMode, 'system');
      expect(notifier.state.language, 'en');
      expect(notifier.state.pushNotifications, true);
      expect(notifier.state.emailNotifications, true);
      expect(notifier.state.workoutReminders, true);
      expect(notifier.state.bookingAlerts, true);
      expect(notifier.state.showTrainerNotificationsInClientMode, true);
      expect(notifier.state.showClientNotificationsInTrainerMode, true);
      expect(notifier.state.isCustomModeEnabled, false);
      expect(notifier.state.isDailyTargetsEnabled, false);
      expect(notifier.state.isVoiceFeedbackEnabled, false);
      expect(notifier.state.isRoutinesEnabled, false);
      expect(notifier.state.syncToAppleCalendar, false);
      expect(notifier.state.sharingDuration, 'forever');
      expect(notifier.state.error, isNull);
    });

    test('loadPreferences reads saved SharedPrefs values', () async {
      SharedPreferences.setMockInitialValues({
        'pref_themeMode': 'dark',
        'pref_language': 'es',
        'pref_pushNotifications': false,
        'pref_emailNotifications': false,
        'pref_workoutReminders': false,
        'pref_bookingAlerts': false,
        'pref_showTrainerNotificationsInClientMode': false,
        'pref_showClientNotificationsInTrainerMode': false,
        'pref_isCustomModeEnabled': true,
        'pref_isDailyTargetsEnabled': true,
        'pref_isVoiceFeedbackEnabled': true,
        'pref_isRoutinesEnabled': true,
        'pref_syncToAppleCalendar': true,
        'pref_sharingDuration': '30_days',
      });

      await notifier.loadPreferences();

      expect(notifier.state.themeMode, 'dark');
      expect(notifier.state.language, 'es');
      expect(notifier.state.pushNotifications, false);
      expect(notifier.state.emailNotifications, false);
      expect(notifier.state.workoutReminders, false);
      expect(notifier.state.bookingAlerts, false);
      expect(notifier.state.showTrainerNotificationsInClientMode, false);
      expect(notifier.state.showClientNotificationsInTrainerMode, false);
      expect(notifier.state.isCustomModeEnabled, true);
      expect(notifier.state.isDailyTargetsEnabled, true);
      expect(notifier.state.isVoiceFeedbackEnabled, true);
      expect(notifier.state.isRoutinesEnabled, true);
      expect(notifier.state.syncToAppleCalendar, true);
      expect(notifier.state.sharingDuration, '30_days');
    });

    test('setThemeMode persists to SharedPrefs', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      await notifier.setThemeMode('dark');

      expect(notifier.state.themeMode, 'dark');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_themeMode'), 'dark');
    });

    test('setLanguage persists to SharedPrefs', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      await notifier.setLanguage('fr');

      expect(notifier.state.language, 'fr');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_language'), 'fr');
    });

    test('push notification toggle persists to SharedPrefs', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      await notifier.setPushNotifications(false);

      expect(notifier.state.pushNotifications, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pref_pushNotifications'), false);
    });

    test('setSharingDuration persists to SharedPrefs', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      await notifier.setSharingDuration('90_days');

      expect(notifier.state.sharingDuration, '90_days');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_sharingDuration'), '90_days');
    });

    test('resetToDefaults clears all SharedPrefs and resets state', () async {
      SharedPreferences.setMockInitialValues({
        'pref_themeMode': 'dark',
        'pref_language': 'fr',
      });
      await notifier.loadPreferences();
      expect(notifier.state.themeMode, 'dark');

      await notifier.resetToDefaults();

      expect(notifier.state.themeMode, 'system');
      expect(notifier.state.language, 'en');
      expect(notifier.state.error, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('pref_themeMode'), false);
    });
  });

  // ===========================================================================
  // With API client — API call is attempted on load
  // ===========================================================================

  group('with API client', () {
    late PreferencesNotifier notifier;

    setUp(() {
      notifier = PreferencesNotifier(apiClient: mockApiClient);
    });

    test('loadPreferences calls API and maps response fields', () async {
      final responseData = <String, dynamic>{
        'data': <String, dynamic>{
          'theme_mode': 'dark',
          'language': 'fr',
          'push_notifications': false,
          'email_notifications': false,
          'workout_reminders': true,
          'booking_alerts': false,
          'show_trainer_notifications_in_client_mode': false,
          'show_client_notifications_in_trainer_mode': true,
          'is_custom_mode_enabled': true,
          'is_daily_targets_enabled': false,
          'is_voice_feedback_enabled': true,
          'is_routines_enabled': false,
          'sync_to_apple_calendar': true,
          'sharing_duration': '30_days',
        },
      };
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          )).thenAnswer((_) async => responseData);

      await notifier.loadPreferences();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.themeMode, 'dark');
      expect(notifier.state.language, 'fr');
      expect(notifier.state.pushNotifications, false);
      expect(notifier.state.emailNotifications, false);
      expect(notifier.state.workoutReminders, true);
      expect(notifier.state.bookingAlerts, false);
      expect(notifier.state.showTrainerNotificationsInClientMode, false);
      expect(notifier.state.showClientNotificationsInTrainerMode, true);
      expect(notifier.state.isCustomModeEnabled, true);
      expect(notifier.state.isDailyTargetsEnabled, false);
      expect(notifier.state.isVoiceFeedbackEnabled, true);
      expect(notifier.state.isRoutinesEnabled, false);
      expect(notifier.state.syncToAppleCalendar, true);
      expect(notifier.state.sharingDuration, '30_days');
      expect(notifier.state.error, isNull);

      verify(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          )).called(1);
    });

    test('loadPreferences handles direct response without data wrapper',
        () async {
      final responseData = <String, dynamic>{
        'theme_mode': 'light',
        'language': 'en',
      };
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          )).thenAnswer((_) async => responseData);

      await notifier.loadPreferences();

      expect(notifier.state.themeMode, 'light');
      expect(notifier.state.language, 'en');
    });

    test('loadPreferences uses defaults when API response fields are missing',
        () async {
      final responseData = <String, dynamic>{
        'data': <String, dynamic>{},
      };
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          )).thenAnswer((_) async => responseData);

      await notifier.loadPreferences();

      expect(notifier.state.themeMode, 'system');
      expect(notifier.state.language, 'en');
      expect(notifier.state.pushNotifications, true);
      expect(notifier.state.isCustomModeEnabled, false);
      expect(notifier.state.sharingDuration, 'forever');
    });

    test('setThemeMode calls API after local save', () async {
      SharedPreferences.setMockInitialValues({});
      when(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.setThemeMode('dark');

      verify(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: {'theme_mode': 'dark'},
          )).called(1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_themeMode'), 'dark');
    });

    test('setLanguage calls API after local save', () async {
      SharedPreferences.setMockInitialValues({});
      when(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.setLanguage('de');

      verify(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: {'language': 'de'},
          )).called(1);
    });

    test('push notification toggle calls API', () async {
      SharedPreferences.setMockInitialValues({});
      when(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.setPushNotifications(false);

      verify(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: {'push_notifications': false},
          )).called(1);
    });
  });

  // ===========================================================================
  // With API client on failure — falls back gracefully
  // ===========================================================================

  group('API failure fallback', () {
    late PreferencesNotifier notifier;

    setUp(() {
      notifier = PreferencesNotifier(apiClient: mockApiClient);
    });

    test('loadPreferences falls back to SharedPrefs when API throws', () async {
      SharedPreferences.setMockInitialValues({
        'pref_themeMode': 'dark',
        'pref_language': 'es',
      });
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          )).thenThrow(Exception('Network error'));

      await notifier.loadPreferences();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.themeMode, 'dark');
      expect(notifier.state.language, 'es');
      expect(notifier.state.error, isNull); // silent fallback, no error set
    });

    test('setThemeMode does not propagate API error', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      when(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: any(named: 'body'),
          )).thenThrow(Exception('API error'));

      await notifier.setThemeMode('dark');

      // State should still be updated despite API failure
      expect(notifier.state.themeMode, 'dark');
      expect(notifier.state.error, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_themeMode'), 'dark');
    });

    test('setPushNotifications ignores API failure', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      when(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: any(named: 'body'),
          )).thenThrow(Exception('API error'));

      await notifier.setPushNotifications(false);

      expect(notifier.state.pushNotifications, false);
      expect(notifier.state.error, isNull);
    });
  });
}
