import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/network/api_client.dart';
import 'core/network/secure_storage.dart';
import 'core/router/app_router.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_routing.dart';
import 'data/models/profile.dart';
import 'data/sync/sync_provider.dart';
import 'features/auth/providers/auth_provider.dart';

/// Application initialization orchestration.
///
/// Run once at startup before [ZiroFitApp] mounts.
/// Sets up: API client, auth (token restore), initial sync, connectivity listener,
/// and deep link handling.
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

    // 4. Initialize deep link service — handle zirofitapp:// URLs
    final deepLinkService = DeepLinkService();
    await deepLinkService.initialize();

    deepLinkService.onRoute.listen((route) async {
      final router = container.read(routerProvider);

      switch (route.type) {
        case DeepLinkRouteType.authCallback:
          final token = route.accessToken;
          if (token != null && token.isNotEmpty) {
            // Auth route — the auth provider's redirect logic will handle
            // navigation after token processing. Navigate to login which
            // will pick up the auth state change.
            router.go('/auth/login');
          }

        case DeepLinkRouteType.eventDetail:
          final eventId = route.eventId;
          if (eventId != null) {
            router.go('/events/$eventId');
          }

        case DeepLinkRouteType.trainerProfile:
          final trainerId = route.trainerId;
          if (trainerId != null) {
            await _navigateToTrainerProfile(trainerId, router, container);
          }

        case DeepLinkRouteType.workout:
          final workoutId = route.workoutId;
          if (workoutId != null) {
            router.go('/workout/$workoutId');
          }
      }
    });

    // 5. Initialize Firebase (must be done before any Firebase services).
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase initialization may fail on platforms without Google Play
      // Services (emulator, web, etc.). Non-fatal.
    }

    // 6. Initialize FCM (Firebase Cloud Messaging) — push notifications
    try {
      final fcmService = container.read(fcmServiceProvider);
      await fcmService.initialize();

      // Navigate when the user taps a notification (background / terminated).
      // Uses NotificationRoutingService to map notification_type to routes.
      fcmService.onMessage
          .where((m) =>
              m.type == FcmMessageType.background ||
              m.type == FcmMessageType.terminated)
          .listen((message) {
        final router = container.read(routerProvider);
        NotificationRoutingService.handleNotificationTap(
          message.message.data,
          router,
        );
      });
    } catch (_) {
      // FCM initialization may fail on platforms without Google Play
      // Services (emulator, web, etc.). Non-fatal.
    }
  }

  /// Navigate to the public trainer profile, fetching the profile data first.
  static Future<void> _navigateToTrainerProfile(
    String trainerId,
    GoRouter router,
    ProviderContainer container,
  ) async {
    try {
      final apiClient = container.read(apiClientProvider);
      final profile = await apiClient.get<Profile>(
        '/trainers/$trainerId',
        fromJson: (json) => Profile.fromJson(json as Map<String, dynamic>),
      );
      router.go('/public-trainer/$trainerId', extra: profile);
    } catch (_) {
      // If profile fetch fails, navigate to the profile page anyway — the
      // page builder will show an appropriate fallback state.
      router.go('/public-trainer/$trainerId');
    }
  }
}
