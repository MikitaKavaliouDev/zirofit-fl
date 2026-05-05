import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/providers/system_config_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> _configJson() => {
      'allow_registrations': true,
      'max_bookings_per_day': 10,
      'feature_ai_coach': true,
      'maintenance_mode': false,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      systemConfigProvider.overrideWith(
        (ref) => SystemConfigNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('SystemConfigNotifier', () {
    test('initial state has empty flags, not loading, no error', () {
      final state = container.read(systemConfigProvider);
      expect(state.flags, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchConfig populates the config flags', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _configJson(),
          });

      await container.read(systemConfigProvider.notifier).fetchConfig();

      final state = container.read(systemConfigProvider);
      expect(state.flags['allow_registrations'], isTrue);
      expect(state.flags['max_bookings_per_day'], 10);
      expect(state.flags['feature_ai_coach'], isTrue);
      expect(state.flags['maintenance_mode'], isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchConfig handles null data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': null,
          });

      await container.read(systemConfigProvider.notifier).fetchConfig();

      final state = container.read(systemConfigProvider);
      expect(state.flags, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchConfig handles missing data key gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
          )).thenAnswer((_) async => <String, dynamic>{});

      await container.read(systemConfigProvider.notifier).fetchConfig();

      final state = container.read(systemConfigProvider);
      expect(state.flags, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchConfig sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
          )).thenThrow(Exception('Config error'));

      await container.read(systemConfigProvider.notifier).fetchConfig();

      final state = container.read(systemConfigProvider);
      expect(state.flags, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('clearError clears the error', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.systemConfig,
          )).thenThrow(Exception('Error'));

      await container.read(systemConfigProvider.notifier).fetchConfig();
      expect(container.read(systemConfigProvider).error, isNotNull);

      container.read(systemConfigProvider.notifier).clearError();

      expect(container.read(systemConfigProvider).error, isNull);
    });
  });
}
