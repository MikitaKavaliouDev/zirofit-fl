import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/services/fcm_service.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// FCM Service provider
// ---------------------------------------------------------------------------

/// Provides the singleton [FcmService] instance.
final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService.create();
  ref.onDispose(() => service.dispose());
  return service;
});

// ---------------------------------------------------------------------------
// Token state
// ---------------------------------------------------------------------------

/// Holds the current FCM device token and registration status.
class FcmTokenState {
  /// The current FCM token, or `null` before retrieval.
  final String? token;

  /// Whether the token has been successfully registered with the backend.
  final bool isRegistered;

  /// Whether a registration request is in flight.
  final bool isLoading;

  /// Non-null when the last registration attempt failed.
  final String? error;

  const FcmTokenState({
    this.token,
    this.isRegistered = false,
    this.isLoading = false,
    this.error,
  });

  FcmTokenState copyWith({
    String? token,
    bool? isRegistered,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FcmTokenState(
      token: token ?? this.token,
      isRegistered: isRegistered ?? this.isRegistered,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FcmTokenState &&
          token == other.token &&
          isRegistered == other.isRegistered &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => Object.hash(token, isRegistered, isLoading, error);
}

// ---------------------------------------------------------------------------
// FCM Token notifier
// ---------------------------------------------------------------------------

final fcmTokenProvider =
    StateNotifierProvider<FcmTokenNotifier, FcmTokenState>((ref) {
  final fcmService = ref.watch(fcmServiceProvider);
  final apiClient = ref.watch(apiClientProvider);

  final notifier = FcmTokenNotifier(
    fcmService: fcmService,
    apiClient: apiClient,
  );

  // Auto-register token when the user authenticates.
  // On sign-out, unregister the token with the backend so the device no
  // longer receives user-specific push notifications.
  ref.listen(authProvider, (previous, next) {
    if (next.status == AuthStatus.authenticated) {
      notifier.registerToken();
    } else if (next.status == AuthStatus.unauthenticated) {
      notifier.unregisterToken();
    }
  });

  return notifier;
});

class FcmTokenNotifier extends StateNotifier<FcmTokenState> {
  final FcmService _fcmService;
  final ApiClient _apiClient;
  StreamSubscription<String>? _tokenSub;

  FcmTokenNotifier({
    required FcmService fcmService,
    required ApiClient apiClient,
  })  : _fcmService = fcmService,
        _apiClient = apiClient,
        super(const FcmTokenState()) {
    // Capture any token already available from the service.
    final initial = _fcmService.currentToken;
    if (initial != null) {
      state = state.copyWith(token: initial);
    }

    // React to token refreshes from the FCM service.
    _tokenSub = _fcmService.onToken.listen((token) {
      state = state.copyWith(token: token, isRegistered: false);
    });
  }

  @override
  void dispose() {
    _tokenSub?.cancel();
    super.dispose();
  }

  /// Registers the current FCM token with the backend.
  ///
  /// Skips silently when:
  /// - No token is available yet
  /// - A registration is already in flight
  /// - The token is already registered with the backend
  Future<void> registerToken() async {
    final token = state.token;
    if (token == null || token.isEmpty) return;
    if (state.isLoading) return;
    if (state.isRegistered) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.post(
        ApiConstants.registerDeviceToken,
        body: {'token': token, 'platform': 'mobile'},
      );
      state = state.copyWith(isRegistered: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Unregisters the current device token from the backend.
  ///
  /// Called automatically on sign-out so the device stops receiving
  /// user-targeted push notifications. Skips when no token is available or
  /// an unregister request is already in flight. Errors are silently caught
  /// since a failed unregister should not block sign-out.
  Future<void> unregisterToken() async {
    final token = state.token;
    if (token == null || token.isEmpty) {
      state = state.copyWith(isRegistered: false, clearError: true);
      return;
    }
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete(ApiConstants.unregisterDeviceToken);
    } catch (_) {
      // Non-fatal: backend unregister failure should not block sign-out.
    } finally {
      state = state.copyWith(isRegistered: false, isLoading: false);
    }
  }

  /// Clears the registration flag (e.g. on sign-out) so that a subsequent
  /// login triggers a fresh registration.
  ///
  /// Unlike [unregisterToken], this is synchronous and does not call the
  /// backend. Useful for immediate state resets without a network call.
  void clearRegistration() {
    state = state.copyWith(isRegistered: false, clearError: true);
  }

  static String _extractErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString();
    }
    return error.toString();
  }
}
