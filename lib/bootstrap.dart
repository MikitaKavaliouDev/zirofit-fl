import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/api_client.dart';
import 'core/network/secure_storage.dart';
import 'data/sync/sync_provider.dart';
import 'features/auth/providers/auth_provider.dart';

/// Application initialization orchestration.
///
/// Run once at startup before [ZiroFitApp] mounts.
/// Sets up: API client, auth (token restore), initial sync, connectivity listener.
class AppBootstrap {
  static Future<void> initialize(ProviderContainer container) async {
    // 0. Configure API client singleton
    ApiClient.configure(
      secureStorage: SecureStorage(),
      onLogout: () {
        // AuthNotifier handles state reset; router redirects to login
      },
    );

    // 1. Initialize auth — check stored tokens, attempt auto-login
    final authNotifier = container.read(authProvider.notifier);
    await authNotifier.initialize();

    // 2. Trigger initial sync (runs in background; failures are non-fatal)
    try {
      final syncEngine = container.read(syncEngineProvider);
      await syncEngine.sync();
    } catch (_) {
      // Sync failure on first launch is acceptable (offline, no account, etc.)
    }

    // 3. Set up connectivity listener — auto-sync when coming back online
    final connectivityChecker = Connectivity();
    connectivityChecker.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
      if (isOnline) {
        try {
          final engine = container.read(syncEngineProvider);
          engine.sync();
        } catch (_) {
          // Silently retry on next connectivity change
        }
      }
    });
  }
}
