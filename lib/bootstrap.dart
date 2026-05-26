import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/network/api_client.dart';
import 'core/network/secure_storage.dart';
import 'core/providers/fcm_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/app_event_bus.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/language_manager.dart';
import 'core/services/fcm_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_routing.dart';
import 'core/services/stripe_connect_service.dart';
import 'core/utils/provider_state_logger.dart';
import 'data/models/profile.dart';
import 'data/sync/sync_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/mode_switch_provider.dart';
import 'features/clients/providers/client_list_provider.dart';
import 'features/workout/providers/active_workout_provider.dart';

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
      onUnauthorized: (String mode) {
        // Called by AuthInterceptor when a 401 cannot be resolved by a token
        // refresh. Surgically clears only the failing mode's tokens and shows
        // a session-expired message if the active mode is affected.
        try {
          container.read(authProvider.notifier).handleUnauthorized(mode);
        } catch (_) {
          // Container may not be fully ready if called early.
        }
      },
    );

    // 1. Initialize auth — check stored tokens, attempt auto-login
    final authNotifier = container.read(authProvider.notifier);
    await authNotifier.initialize();

    // 2. Sync display mode to match the authenticated role.
    //    A trainer always lands on /trainer/*, a client on /client/* — regardless
    //    of any stored mode preference.  The user can still toggle via the
    //    bottom-nav button (switchMode()).
    final authState = container.read(authProvider);
    if (authState.role == 'client') {
      final modeNotifier = container.read(modeSwitchProvider.notifier);
      await modeNotifier.setMode(AppMode.personal);
    } else if (authState.role == 'trainer') {
      final modeNotifier = container.read(modeSwitchProvider.notifier);
      await modeNotifier.setMode(AppMode.trainer);
    }

    // Log initial provider states after auth initialization
    if (kDebugMode) {
      ProviderStateLogger.logAllProviders(container);
    }

    // 2. Ghost session recovery — check local DB for an in-progress workout
    //    so the mini-player or full workout UI appears on app restart.
    try {
      await container.read(activeWorkoutProvider.notifier).checkForActiveSession();
    } catch (_) {
      // Best-effort; local DB query failures should never block startup.
    }

    // 3. Wire appUserContextWillChange → session reset
    //    When user switches trainer↔personal mode, reset the active workout
    //    session (stop timer, clear session, clear logs/caches).
    AppEventBus().onAppUserContextWillChange.addListener(() {
      try {
        container.read(activeWorkoutProvider.notifier).reset();
      } catch (_) {
        // Provider may not be ready yet.
      }
    });

    // 4. Pre-fetch clients on login (cache-first)
    //    This loads the client list from the API and caches it so the
    //    client list screen renders instantly on first visit.
    if (authState.role == 'trainer') {
      try {
        final clientListNotifier =
            container.read(clientListProvider.notifier);
        // Attempt a background fetch to warm the cache
        clientListNotifier.fetchClients();
      } catch (_) {
        // Best-effort; client list fetch should never block startup.
      }
    }

    // 5. Trigger initial sync (runs in background; failures are non-fatal)
    try {
      final syncEngine = container.read(syncEngineProvider);
      await syncEngine.sync();
    } catch (_) {
      // Sync failure on first launch is acceptable (offline, no account, etc.)
    }

    // 6. Set up connectivity listener — auto-sync when coming back online
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

    // 7. Initialize deep link service — handle zirofitapp:// URLs
    final deepLinkService = DeepLinkService();
    await deepLinkService.initialize();

    deepLinkService.onRoute.listen((route) async {
      final router = container.read(routerProvider);

      switch (route.type) {
        case DeepLinkRouteType.authCallback:
          final token = route.accessToken;
          final refreshToken = route.refreshToken;
          if (token != null && token.isNotEmpty) {
            // Save tokens then navigate to the callback screen which will
            // process them and refresh the session.
            final secureStorage = SecureStorage();
            await secureStorage.saveTokens(
              accessToken: token,
              refreshToken: refreshToken ?? '',
            );
            router.go(
              '/auth/callback?access_token=$token&refresh_token=$refreshToken',
            );
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

        case DeepLinkRouteType.authUpdatePassword:
          final token = route.resetToken;
          if (token != null && token.isNotEmpty) {
            // Save the reset token as the access token so the API client
            // can authenticate the update-password request.
            final secureStorage = SecureStorage();
            await secureStorage.saveTokens(
              accessToken: token,
              refreshToken: '',
            );
            router.go('/auth/reset-password?token=$token');
          }

        case DeepLinkRouteType.stripeReturn:
          // Forward the raw URI to StripeConnectService for processing.
          if (route.rawUri != null) {
            StripeConnectService().handleDeepLink(route.rawUri!);
          }
      }
    });

    // 8. Initialize LanguageManager — load persisted language preference
    try {
      await container.read(languageManagerProvider.notifier).initialize();
    } catch (_) {
      // Language initialization is best-effort.
    }

    // 9. Initialize Firebase (must be done before any Firebase services).
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase initialization may fail on platforms without Google Play
      // Services (emulator, web, etc.). Non-fatal.
    }

    // 10. Initialize FCM (Firebase Cloud Messaging) — push notifications
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

    // 10. Initialize location service — request position early so it's ready
    //    when screens need it. Best-effort, never blocks startup.
    try {
      final locationService = LocationService();
      locationService.requestLocation();
    } catch (_) {
      // Location initialization is best-effort.
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
        fromJson: (json) => Profile.fromJson(json),
      );
      router.go('/public-trainer/$trainerId', extra: profile);
    } catch (_) {
      // If profile fetch fails, navigate to the profile page anyway — the
      // page builder will show an appropriate fallback state.
      router.go('/public-trainer/$trainerId');
    }
  }
}
