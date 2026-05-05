import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';
import 'package:zirofit_fl/data/sync/connectivity_manager.dart';
import 'package:zirofit_fl/data/sync/sync_engine.dart';
import 'package:zirofit_fl/data/sync/sync_models.dart';
import 'package:zirofit_fl/data/sync/sync_provider.dart';
import 'package:zirofit_fl/data/sync/sync_remote_source.dart';
import '../../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------------

class MockSecureStorage extends Mock implements SecureStorage {}

class MockSyncEngine extends Mock implements SyncEngine {}

// ---------------------------------------------------------------------------
// syncRemoteSourceProvider
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('syncRemoteSourceProvider', () {
    setUp(() {
      ApiClient.reset();
      ApiClient.configure(secureStorage: MockSecureStorage());
    });

    tearDown(() {
      ApiClient.reset();
    });

    test('creates SyncRemoteSource with ApiClient dio', () {
      final container = createTestContainer();

      final source = container.read(syncRemoteSourceProvider);

      expect(source, isA<SyncRemoteSource>());
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // connectivityManagerProvider
  // ---------------------------------------------------------------------------

  group('connectivityManagerProvider', () {
    test('creates a ConnectivityManager instance', () {
      final container = createTestContainer();

      final manager = container.read(connectivityManagerProvider);

      expect(manager, isA<ConnectivityManager>());
      // NOTE: Cannot call container.dispose() here because
      // ConnectivityManager.dispose() references late field _subscription
      // which is only populated by initialize(). The SyncEngine calls
      // initialize(), but standalone provider reads don't trigger it.
    });

    test('returns the same instance within the same container', () {
      final container = createTestContainer();

      final manager1 = container.read(connectivityManagerProvider);
      final manager2 = container.read(connectivityManagerProvider);

      expect(manager1, same(manager2));
    });
  });

  // ---------------------------------------------------------------------------
  // syncStatusProvider
  // ---------------------------------------------------------------------------

  group('syncStatusProvider', () {
    late StreamController<SyncUiStatus> controller;
    late MockSyncEngine mockEngine;

    setUp(() {
      controller = StreamController<SyncUiStatus>.broadcast();
      mockEngine = MockSyncEngine();
      when(() => mockEngine.statusStream).thenAnswer((_) => controller.stream);
    });

    tearDown(() async {
      await controller.close();
    });

    test('initial state is loading before stream emits', () {
      final container = createTestContainer(overrides: [
        syncEngineProvider.overrideWithValue(mockEngine),
      ]);

      final status = container.read(syncStatusProvider);

      expect(status, isA<AsyncLoading<SyncUiStatus>>());
      container.dispose();
    });

    test('emits synced status', () async {
      final container = createTestContainer(overrides: [
        syncEngineProvider.overrideWithValue(mockEngine),
      ]);

      // Read to trigger stream subscription
      container.read(syncStatusProvider);

      controller.add(SyncUiStatus.synced);
      await Future<void>.delayed(Duration.zero);

      final status = container.read(syncStatusProvider);
      expect(status.hasValue, isTrue);
      expect(status.value, SyncUiStatus.synced);

      container.dispose();
    });

    test('emits error status', () async {
      final container = createTestContainer(overrides: [
        syncEngineProvider.overrideWithValue(mockEngine),
      ]);

      container.read(syncStatusProvider);

      controller.add(SyncUiStatus.error);
      await Future<void>.delayed(Duration.zero);

      final status = container.read(syncStatusProvider);
      expect(status.hasValue, isTrue);
      expect(status.value, SyncUiStatus.error);

      container.dispose();
    });

    test('emits multiple status values in sequence', () async {
      final container = createTestContainer(overrides: [
        syncEngineProvider.overrideWithValue(mockEngine),
      ]);

      container.read(syncStatusProvider);

      controller.add(SyncUiStatus.syncing);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(syncStatusProvider).value, SyncUiStatus.syncing);

      controller.add(SyncUiStatus.synced);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(syncStatusProvider).value, SyncUiStatus.synced);

      controller.add(SyncUiStatus.offline);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(syncStatusProvider).value, SyncUiStatus.offline);

      container.dispose();
    });

    test('disposes cleanly with container', () async {
      final container = createTestContainer(overrides: [
        syncEngineProvider.overrideWithValue(mockEngine),
      ]);

      container.read(syncStatusProvider);
      controller.add(SyncUiStatus.synced);
      await Future<void>.delayed(Duration.zero);

      expect(() => container.dispose(), returnsNormally);
    });
  });
}
