import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/settings/providers/dashboard_prompts_provider.dart';

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
    late DashboardPromptsNotifier notifier;

    setUp(() {
      notifier = DashboardPromptsNotifier();
    });

    test('loadPreferences loads defaults when SharedPrefs is empty', () async {
      SharedPreferences.setMockInitialValues({});

      await notifier.loadPreferences();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.coachBannerDismissed, false);
      expect(notifier.state.checkInBannerDismissed, false);
      expect(notifier.state.error, isNull);
    });

    test('loadPreferences reads saved SharedPrefs values', () async {
      SharedPreferences.setMockInitialValues({
        'coachBannerDismissed': true,
        'checkInBannerDismissed': false,
      });

      await notifier.loadPreferences();

      expect(notifier.state.coachBannerDismissed, true);
      expect(notifier.state.checkInBannerDismissed, false);
    });

    test('setCoachBannerDismissed persists to SharedPrefs', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      await notifier.setCoachBannerDismissed(true);

      expect(notifier.state.coachBannerDismissed, true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('coachBannerDismissed'), true);
    });

    test('setCheckInBannerDismissed persists to SharedPrefs', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      await notifier.setCheckInBannerDismissed(true);

      expect(notifier.state.checkInBannerDismissed, true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('checkInBannerDismissed'), true);
    });

    test('setCoachBannerShown inverts dismissed', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      await notifier.setCoachBannerShown(true);

      expect(notifier.state.coachBannerDismissed, false);
    });

    test('setCheckInBannerShown inverts dismissed', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      await notifier.setCheckInBannerShown(false);

      expect(notifier.state.checkInBannerDismissed, true);
    });
  });

  // ===========================================================================
  // With API client — API call is attempted
  // ===========================================================================

  group('with API client', () {
    late DashboardPromptsNotifier notifier;

    setUp(() {
      notifier = DashboardPromptsNotifier(apiClient: mockApiClient);
    });

    test('loadPreferences calls API and maps response fields', () async {
      final responseData = <String, dynamic>{
        'data': <String, dynamic>{
          'coach_banner_dismissed': true,
          'check_in_banner_dismissed': false,
        },
      };
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          )).thenAnswer((_) async => responseData);

      await notifier.loadPreferences();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.coachBannerDismissed, true);
      expect(notifier.state.checkInBannerDismissed, false);
      expect(notifier.state.error, isNull);

      verify(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          )).called(1);
    });

    test('loadPreferences handles direct response without data wrapper',
        () async {
      final responseData = <String, dynamic>{
        'coach_banner_dismissed': true,
        'check_in_banner_dismissed': true,
      };
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          )).thenAnswer((_) async => responseData);

      await notifier.loadPreferences();

      expect(notifier.state.coachBannerDismissed, true);
      expect(notifier.state.checkInBannerDismissed, true);
    });

    test('loadPreferences uses defaults when API fields are missing', () async {
      final responseData = <String, dynamic>{
        'data': <String, dynamic>{},
      };
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          )).thenAnswer((_) async => responseData);

      await notifier.loadPreferences();

      expect(notifier.state.coachBannerDismissed, false);
      expect(notifier.state.checkInBannerDismissed, false);
    });

    test('setCoachBannerDismissed calls API after local save', () async {
      SharedPreferences.setMockInitialValues({});
      when(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.setCoachBannerDismissed(true);

      verify(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: {'coach_banner_dismissed': true},
          )).called(1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('coachBannerDismissed'), true);
    });

    test('setCheckInBannerDismissed calls API after local save', () async {
      SharedPreferences.setMockInitialValues({});
      when(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.setCheckInBannerDismissed(true);

      verify(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: {'check_in_banner_dismissed': true},
          )).called(1);
    });
  });

  // ===========================================================================
  // With API client on failure — falls back gracefully
  // ===========================================================================

  group('API failure fallback', () {
    late DashboardPromptsNotifier notifier;

    setUp(() {
      notifier = DashboardPromptsNotifier(apiClient: mockApiClient);
    });

    test('loadPreferences falls back to SharedPrefs when API throws', () async {
      SharedPreferences.setMockInitialValues({
        'coachBannerDismissed': true,
        'checkInBannerDismissed': false,
      });
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.userPreferences,
          )).thenThrow(Exception('Network error'));

      await notifier.loadPreferences();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.coachBannerDismissed, true);
      expect(notifier.state.checkInBannerDismissed, false);
      expect(notifier.state.error, isNull);
    });

    test('setCoachBannerDismissed silently ignores API error', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      when(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: any(named: 'body'),
          )).thenThrow(Exception('API error'));

      await notifier.setCoachBannerDismissed(true);

      expect(notifier.state.coachBannerDismissed, true);
      expect(notifier.state.error, isNull);
    });

    test('setCheckInBannerDismissed silently ignores API error', () async {
      SharedPreferences.setMockInitialValues({});
      await notifier.loadPreferences();

      when(() => mockApiClient.put(
            ApiConstants.userPreferences,
            body: any(named: 'body'),
          )).thenThrow(Exception('API error'));

      await notifier.setCheckInBannerDismissed(true);

      expect(notifier.state.checkInBannerDismissed, true);
      expect(notifier.state.error, isNull);
    });
  });
}
