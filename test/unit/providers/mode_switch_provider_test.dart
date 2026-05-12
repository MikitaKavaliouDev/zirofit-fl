import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/auth/providers/mode_switch_provider.dart';
import '../../helpers/provider_utils.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

class MockApiClient extends Mock implements ApiClient {}

/// Completer that can be completed later.
class CompleterToken {
  final access = Completer<String?>();
  final refresh = Completer<String?>();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorage mockSecureStorage;
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    mockApiClient = MockApiClient();

    // Default secure storage stubs (return null = no stored tokens)
    when(() => mockSecureStorage.getAccessToken())
        .thenAnswer((_) async => null);
    when(() => mockSecureStorage.getRefreshToken())
        .thenAnswer((_) async => null);
    when(() => mockSecureStorage.hasTokens())
        .thenAnswer((_) async => false);
    when(() => mockSecureStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
    when(() => mockSecureStorage.clearTokens())
        .thenAnswer((_) async {});

    // Default API client stubs (for auth provider initialize)
    when(() => mockApiClient.post(
          any(),
          body: any(named: 'body'),
        )).thenAnswer((_) async => null);

    container = createTestContainer(overrides: [
      secureStorageProvider.overrideWithValue(mockSecureStorage),
      apiClientProvider.overrideWithValue(mockApiClient as ApiClient),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  // ===========================================================================
  // Initial mode
  // ===========================================================================

  group('initial mode', () {
    test('defaults to trainer when no preference is saved', () async {
      SharedPreferences.setMockInitialValues({});

      await container.read(modeSwitchProvider.notifier).initialize();
      expect(container.read(modeSwitchProvider), AppMode.trainer);
    });

    test('reads saved trainer preference', () async {
      SharedPreferences.setMockInitialValues({'app_mode': 'trainer'});

      await container.read(modeSwitchProvider.notifier).initialize();
      expect(container.read(modeSwitchProvider), AppMode.trainer);
    });

    test('reads saved personal preference', () async {
      SharedPreferences.setMockInitialValues({'app_mode': 'personal'});

      await container.read(modeSwitchProvider.notifier).initialize();
      expect(container.read(modeSwitchProvider), AppMode.personal);
    });
  });

  // ===========================================================================
  // switchMode
  // ===========================================================================

  group('switchMode', () {
    test('toggles from trainer to personal', () async {
      SharedPreferences.setMockInitialValues({});
      await container.read(modeSwitchProvider.notifier).initialize();

      expect(container.read(modeSwitchProvider), AppMode.trainer);

      await container.read(modeSwitchProvider.notifier).switchMode();

      expect(container.read(modeSwitchProvider), AppMode.personal);
    });

    test('toggles from personal to trainer', () async {
      SharedPreferences.setMockInitialValues({'app_mode': 'personal'});
      await container.read(modeSwitchProvider.notifier).initialize();

      expect(container.read(modeSwitchProvider), AppMode.personal);

      await container.read(modeSwitchProvider.notifier).switchMode();

      expect(container.read(modeSwitchProvider), AppMode.trainer);
    });

    test('back-to-back toggles return to original', () async {
      SharedPreferences.setMockInitialValues({});
      await container.read(modeSwitchProvider.notifier).initialize();

      await container.read(modeSwitchProvider.notifier).switchMode();
      expect(container.read(modeSwitchProvider), AppMode.personal);

      await container.read(modeSwitchProvider.notifier).switchMode();
      expect(container.read(modeSwitchProvider), AppMode.trainer);
    });
  });

  // ===========================================================================
  // Persistence
  // ===========================================================================

  group('persistence', () {
    test('persists trainer mode across restarts', () async {
      SharedPreferences.setMockInitialValues({});
      await container.read(modeSwitchProvider.notifier).initialize();

      // Switch to personal, then back to trainer
      await container.read(modeSwitchProvider.notifier).switchMode();
      await container.read(modeSwitchProvider.notifier).switchMode();

      // Simulate restart by creating a new container
      container.dispose();
      container = createTestContainer(overrides: [
        secureStorageProvider.overrideWithValue(mockSecureStorage),
        apiClientProvider.overrideWithValue(mockApiClient as ApiClient),
      ]);

      await container.read(modeSwitchProvider.notifier).initialize();
      expect(container.read(modeSwitchProvider), AppMode.trainer);
    });

    test('persists personal mode across restarts', () async {
      SharedPreferences.setMockInitialValues({});
      await container.read(modeSwitchProvider.notifier).initialize();

      await container.read(modeSwitchProvider.notifier).switchMode();

      // Simulate restart
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_mode'), 'personal');

      container.dispose();
      container = createTestContainer(overrides: [
        secureStorageProvider.overrideWithValue(mockSecureStorage),
        apiClientProvider.overrideWithValue(mockApiClient as ApiClient),
      ]);

      await container.read(modeSwitchProvider.notifier).initialize();
      expect(container.read(modeSwitchProvider), AppMode.personal);
    });
  });

  // ===========================================================================
  // Token management
  // ===========================================================================

  group('token management on switch', () {
    test('backup current tokens before clearing on switch', () async {
      SharedPreferences.setMockInitialValues({});
      when(() => mockSecureStorage.getAccessToken())
          .thenAnswer((_) async => 'trainer-access');
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => 'trainer-refresh');

      await container.read(modeSwitchProvider.notifier).switchMode();

      // Verify tokens were backed up to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('trainer_access_token'), 'trainer-access');
      expect(prefs.getString('trainer_refresh_token'), 'trainer-refresh');

      // Verify clearTokens was called
      verify(() => mockSecureStorage.clearTokens()).called(1);
    });

    test('restore new mode tokens after switching', () async {
      SharedPreferences.setMockInitialValues({
        'personal_access_token': 'personal-access',
        'personal_refresh_token': 'personal-refresh',
      });
      when(() => mockSecureStorage.getAccessToken())
          .thenAnswer((_) async => 'trainer-access');
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => 'trainer-refresh');

      await container.read(modeSwitchProvider.notifier).switchMode();

      // Verify personal tokens were restored to secure storage
      verify(() => mockSecureStorage.saveTokens(
            accessToken: 'personal-access',
            refreshToken: 'personal-refresh',
          )).called(1);

      // Verify mode is now personal
      expect(container.read(modeSwitchProvider), AppMode.personal);
    });

    test('graceful when no tokens exist for current mode', () async {
      SharedPreferences.setMockInitialValues({});
      when(() => mockSecureStorage.getAccessToken())
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => null);

      // Should not throw
      await container.read(modeSwitchProvider.notifier).switchMode();

      expect(container.read(modeSwitchProvider), AppMode.personal);
    });
  });

  // ===========================================================================
  // AppMode enum
  // ===========================================================================

  group('AppMode', () {
    test('trainer and personal are distinct values', () {
      expect(AppMode.trainer, isNot(AppMode.personal));
    });

    test('trainer is the default initial value', () {
      // When no preference is loaded, the provider starts as trainer
      final localContainer = createTestContainer();
      expect(localContainer.read(modeSwitchProvider), AppMode.trainer);
      localContainer.dispose();
    });
  });
}
