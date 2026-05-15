import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/progress/models/analytics_widget_config.dart';
import 'package:zirofit_fl/features/progress/providers/widget_config_provider.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Drains the microtask queue to allow async constructor init (`_load`) to
/// complete before assertions.
Future<void> drainMicrotasks() async {
  for (int i = 0; i < 5; i++) {
    await Future<void>(() {});
  }
}

void main() {
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  group('WidgetConfigNotifier', () {
    // =========================================================================
    // Without ApiClient (local-only mode)
    // =========================================================================

    group('without apiClient', () {
      test('loads defaults when nothing is stored', () async {
        SharedPreferences.setMockInitialValues({});

        final notifier = WidgetConfigNotifier();
        await drainMicrotasks();

        expect(notifier.state.length,
            equals(AnalyticsWidgetConfig.defaults.length));
        expect(notifier.state[0].type, AnalyticsWidgetType.workoutsPerWeek);
      });

      test('loads from SharedPreferences when data exists', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_widgets': jsonEncode([
            {'type': 'workoutsPerWeek', 'isVisible': true, 'order': 0},
            {'type': 'consistency', 'isVisible': false, 'order': 1},
          ]),
        });

        final notifier = WidgetConfigNotifier();
        await drainMicrotasks();

        expect(notifier.state.isNotEmpty, true);
        expect(notifier.state[0].type, AnalyticsWidgetType.workoutsPerWeek);
        expect(notifier.state[0].isVisible, true);
      });

      test('skips corrupted SharedPreferences data and uses defaults',
          () async {
        SharedPreferences.setMockInitialValues({
          'analytics_widgets': 'not-valid-json',
        });

        final notifier = WidgetConfigNotifier();
        await drainMicrotasks();

        expect(notifier.state.length,
            equals(AnalyticsWidgetConfig.defaults.length));
      });

      test('toggleVisibility updates state without calling API', () async {
        SharedPreferences.setMockInitialValues({});

        final notifier = WidgetConfigNotifier();
        await drainMicrotasks();

        final targetType = notifier.state.first.type;
        await notifier.toggleVisibility(targetType);

        expect(
            notifier.state.firstWhere((w) => w.type == targetType).isVisible,
            false);
      });

      test('setVisibility, removeWidget, addWidget, reorder work without API',
          () async {
        SharedPreferences.setMockInitialValues({});

        final notifier = WidgetConfigNotifier();
        await drainMicrotasks();

        final targetType = notifier.state.first.type;

        // setVisibility
        await notifier.setVisibility(targetType, false);
        expect(
            notifier.state.firstWhere((w) => w.type == targetType).isVisible,
            false);

        // removeWidget (sets visible=false)
        await notifier.removeWidget(targetType);

        // addWidget (sets visible=true)
        await notifier.addWidget(targetType);
        expect(
            notifier.state.firstWhere((w) => w.type == targetType).isVisible,
            true);

        // reorder
        final before = notifier.state.first.order;
        await notifier.reorder(0, 1);
        // After reorder, the first element's order may have changed
        expect(notifier.state.length,
            equals(AnalyticsWidgetConfig.defaults.length));
      });
    });

    // =========================================================================
    // With ApiClient
    // =========================================================================

    group('with apiClient', () {
      test('loads from API when apiClient is provided and API succeeds',
          () async {
        final apiData = [
          {'type': 'workoutsPerWeek', 'isVisible': true, 'order': 0},
          {'type': 'consistency', 'isVisible': false, 'order': 1},
        ];

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {'data': apiData});

        SharedPreferences.setMockInitialValues({});

        final notifier = WidgetConfigNotifier(apiClient: mockApiClient);
        await drainMicrotasks();

        // Should be merged with defaults
        expect(notifier.state.length,
            equals(AnalyticsWidgetConfig.defaults.length));
        expect(notifier.state[0].type, AnalyticsWidgetType.workoutsPerWeek);
        verify(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).called(1);
      });

      test('falls back to SharedPreferences when API fails', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_widgets': jsonEncode([
            {'type': 'workoutsPerWeek', 'isVisible': true, 'order': 0},
          ]),
        });

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(Exception('API error'));

        final notifier = WidgetConfigNotifier(apiClient: mockApiClient);
        await drainMicrotasks();

        expect(notifier.state.isNotEmpty, true);
        expect(notifier.state[0].type, AnalyticsWidgetType.workoutsPerWeek);
        verify(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).called(1);
      });

      test('adds default widgets when API returns partial data', () async {
        // Only 2 widgets from API; remaining should come from defaults
        final apiData = [
          {'type': 'workoutsPerWeek', 'isVisible': true, 'order': 0},
        ];

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {'data': apiData});

        SharedPreferences.setMockInitialValues({});

        final notifier = WidgetConfigNotifier(apiClient: mockApiClient);
        await drainMicrotasks();

        // All default widgets should be present
        expect(notifier.state.length,
            equals(AnalyticsWidgetConfig.defaults.length));
      });

      test('toggleVisibility updates state and calls API', () async {
        SharedPreferences.setMockInitialValues({});

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(Exception('API error'));

        when(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
            )).thenAnswer((_) async => {});

        final notifier = WidgetConfigNotifier(apiClient: mockApiClient);
        await drainMicrotasks();

        final targetType = notifier.state.first.type;
        await notifier.toggleVisibility(targetType);

        expect(
            notifier.state.firstWhere((w) => w.type == targetType).isVisible,
            false);
        verify(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
            )).called(1);
      });

      test('setVisibility calls the API via _syncToApi', () async {
        SharedPreferences.setMockInitialValues({});

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(Exception('API error'));

        when(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
            )).thenAnswer((_) async => {});

        final notifier = WidgetConfigNotifier(apiClient: mockApiClient);
        await drainMicrotasks();

        final targetType = notifier.state.first.type;
        await notifier.setVisibility(targetType, false);

        verify(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
        )).called(1);
      });

      test('removeWidget calls the API via _syncToApi', () async {
        SharedPreferences.setMockInitialValues({});

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(Exception('API error'));

        when(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
            )).thenAnswer((_) async => {});

        final notifier = WidgetConfigNotifier(apiClient: mockApiClient);
        await drainMicrotasks();

        final targetType = notifier.state.first.type;
        await notifier.removeWidget(targetType);

        verify(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
        )).called(1);
      });

      test('addWidget calls the API via _syncToApi', () async {
        SharedPreferences.setMockInitialValues({});

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(Exception('API error'));

        when(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
            )).thenAnswer((_) async => {});

        final notifier = WidgetConfigNotifier(apiClient: mockApiClient);
        await drainMicrotasks();

        final targetType = notifier.state.first.type;
        await notifier.addWidget(targetType);

        verify(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
        )).called(1);
      });

      test('reorder calls the API via _syncToApi', () async {
        SharedPreferences.setMockInitialValues({});

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(Exception('API error'));

        when(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
            )).thenAnswer((_) async => {});

        final notifier = WidgetConfigNotifier(apiClient: mockApiClient);
        await drainMicrotasks();

        await notifier.reorder(0, 1);

        verify(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
        )).called(1);
      });

      test('API failure in mutation is silent and does not affect local state',
          () async {
        SharedPreferences.setMockInitialValues({});

        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(Exception('API error'));

        // API PUT always fails
        when(() => mockApiClient.put<dynamic>(
              ApiConstants.widgetConfig,
              body: any(named: 'body'),
            )).thenThrow(Exception('API put error'));

        final notifier = WidgetConfigNotifier(apiClient: mockApiClient);
        await drainMicrotasks();

        // Should not throw even though API fails
        final targetType = notifier.state.first.type;
        await notifier.toggleVisibility(targetType);

        // Local state should still be updated
        expect(
            notifier.state.firstWhere((w) => w.type == targetType).isVisible,
            false);
      });

      test('uses correct API endpoint constant', () async {
        when(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(Exception('API error'));

        SharedPreferences.setMockInitialValues({});

        WidgetConfigNotifier(apiClient: mockApiClient);
        await drainMicrotasks();

        verify(() => mockApiClient.get<Map<String, dynamic>>(
              ApiConstants.widgetConfig,
              queryParams: any(named: 'queryParams'),
        )).called(1);
      });
    });
  });
}
