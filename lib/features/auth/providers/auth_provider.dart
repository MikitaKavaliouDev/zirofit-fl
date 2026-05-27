import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/auth_interceptor.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';
import 'package:zirofit_fl/core/services/subscription_manager.dart';
import 'package:zirofit_fl/features/auth/services/apple_sign_in_helper.dart';
import 'package:zirofit_fl/features/auth/services/google_sign_in_helper.dart';

// ---------------------------------------------------------------------------
// User model
// ---------------------------------------------------------------------------

/// Minimal user model returned from auth endpoints.
class User {
  final String id;
  final String email;
  final String? name;
  final String? emailConfirmedAt;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.emailConfirmedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      name: json['name'] as String?,
      emailConfirmedAt: json['emailConfirmedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'emailConfirmedAt': emailConfirmedAt,
  };
}

// ---------------------------------------------------------------------------
// Auth status & state
// ---------------------------------------------------------------------------

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? role;
  final bool hasCompletedOnboarding;
  final bool isFreeAccessMode;
  final bool isPro;
  final String? error;
  final String? tier;

  // -- convenience getters --

  bool get isTrainer => role == 'trainer';
  bool get isClient => role == 'client';
  bool get isAdmin => role == 'admin';
  bool get isPending => role == 'pending';

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => error != null;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.role,
    this.hasCompletedOnboarding = false,
    this.isFreeAccessMode = false,
    this.isPro = true, // Hardcoded true for BETA period
    this.error,
    this.tier,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? role,
    bool? hasCompletedOnboarding,
    bool? isFreeAccessMode,
    bool? isPro,
    String? error,
    String? tier,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isFreeAccessMode: isFreeAccessMode ?? this.isFreeAccessMode,
      isPro: isPro ?? this.isPro,
      error: clearError ? null : (error ?? this.error),
      tier: tier ?? this.tier,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(apiClient: apiClient, secureStorage: secureStorage);
});

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;
  User? _cachedTrainerUser;
  User? _cachedClientUser;

  AuthNotifier({
    required ApiClient apiClient,
    required SecureStorage secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage,
       super(const AuthState());

  // ========================================================================
  // Role detection
  // ========================================================================

  /// Maps a raw role string from the backend to the app's internal role.
  ///
  /// The following roles are treated as `trainer`:
  ///   trainer, coach, instructor, admin, staff, owner
  ///
  /// Everything else maps to `client`.
  static String detectRole(String role) {
    final normalized = role.toLowerCase().trim();
    const trainerRoles = {
      'trainer',
      'coach',
      'instructor',
      'admin',
      'staff',
      'owner',
    };
    if (trainerRoles.contains(normalized)) return 'trainer';
    return 'client';
  }

  /// Migrates stored role tokens from an old role key to a new one, so
  /// account switching works correctly even when the backend changes its
  /// role naming.
  Future<void> _migrateRoleTokensIfNeeded(
    String detectedRole,
    String accessToken,
    String refreshToken,
  ) async {
    final currentRole = state.role;
    if (currentRole != null && currentRole != detectedRole) {
      // Save tokens under the newly detected role so account-switching
      // keys are consistent.
      await _secureStorage.saveRoleTokens(
        detectedRole,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }

  // ========================================================================
  // JWT helpers
  // ========================================================================

  /// Decodes the payload segment of a JWT (base64-encoded JSON) and returns
  /// it as a [Map]. Returns an empty map on failure.
  static Map<String, dynamic> decodeJwtPayload(String token) {
    return AuthInterceptor.decodeJwtPayload(token);
  }

  // ========================================================================
  // Initialize: check stored tokens, attempt auto-login
  // ========================================================================

  Future<void> initialize() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final hasTokens = await _secureStorage.hasTokens();
      if (!hasTokens) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // Attempt to refresh the session with the stored refresh token
      await refreshSession();
    } catch (e, st) {
      debugPrint('AUTH_INIT_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      await _secureStorage.clearTokens();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ========================================================================
  // Login
  // ========================================================================

  Future<AsyncValue<User>> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final Map<String, dynamic> response = await _apiClient.post(
        ApiConstants.login,
        body: {'email': email, 'password': password},
      );

      final data = response['data'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final userData = data['user'] as Map<String, dynamic>;
      final role = data['role'] as String?;

      // Persist tokens
      await _secureStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      final user = User.fromJson(userData);

      // Fetch extended profile
      final meData = await fetchMe();

      final rawRole = role ?? meData['role'] as String?;
      final resolvedRole = rawRole != null ? detectRole(rawRole) : null;

      // Save tokens under the resolved role for later account switching.
      if (resolvedRole != null) {
        await _secureStorage.saveRoleTokens(
          resolvedRole,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        role: resolvedRole,
        hasCompletedOnboarding:
            meData['hasCompletedOnboarding'] as bool? ?? false,
        isFreeAccessMode: meData['isFreeAccessModeEnabled'] as bool? ?? false,
        isPro: SubscriptionManager().isPro,
        tier: meData['tier'] as String?,
      );

      // Set auth mode based on the resolved role.
      _apiClient.setMode(resolvedRole == 'trainer');
      _cacheCurrentUser();

      return AsyncValue.data(user);
    } catch (e, st) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
      return AsyncValue.error(message, st);
    }
  }

  // ========================================================================
  // Register
  // ========================================================================

  Future<AsyncValue<void>> register(
    String name,
    String email,
    String password, {
    String? role,
    String? trainerId,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
      };
      if (role != null) body['role'] = role;
      if (trainerId != null) body['trainerId'] = trainerId;

      await _apiClient.post(ApiConstants.register, body: body);

      state = state.copyWith(status: AuthStatus.unauthenticated);
      return const AsyncValue.data(null);
    } catch (e, st) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
      return AsyncValue.error(message, st);
    }
  }

  // ========================================================================
  // OAuth
  // ========================================================================

  Future<void> signInWithOAuth(String provider) async {
    if (provider == 'apple') {
      await _signInWithApple();
      return;
    }

    if (provider == 'google') {
      await _signInWithGoogle();
      return;
    }

    // Fallback for other providers — opens the URL in the system browser.
    // The server redirects back to zirofitapp://auth/callback?access_token=...
    // which is handled by the deep link service and AuthCallbackScreen.
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/auth/mobile-signin',
    ).replace(queryParameters: {'provider': provider});

    await _launchUrl(uri.toString());
  }

  /// In-app Google Sign In via [GoogleSignInHelper] (mirrors iOS
  /// [GoogleSignInHelper] with [ASWebAuthenticationSession]).
  Future<void> _signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final helper = GoogleSignInHelper();
      final result = await helper.signIn();

      // User cancelled the in-app browser — return to unauthenticated state
      // without an error.
      state = state.copyWith(status: AuthStatus.unauthenticated);

      // Persist tokens from the OAuth callback.
      await _secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      // Save tokens under the role key for account switching.
      if (result.role != null) {
        await _secureStorage.saveRoleTokens(
          result.role!,
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
        );
      }

      // Bootstrap the full auth state (fetch user profile etc.).
      await refreshSession();
    } on GoogleSignInException catch (e) {
      // User cancellation is handled above; other Google-specific errors.
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.message,
      );
    } catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    }
  }

  /// Native Apple Sign In via [AppleSignInHelper].
  Future<void> _signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      const helper = AppleSignInHelper();
      final result = await helper.signIn();

      // User cancelled the native dialog — return to unauthenticated state
      // without an error.
      if (result == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // Exchange the Apple identity token for our JWT tokens.
      final Map<String, dynamic> response = await _apiClient.post(
        ApiConstants.mobileSignin,
        body: {
          'provider': 'apple',
          'id_token': result.identityToken,
        },
      );

      final data = response['data'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final userData = data['user'] as Map<String, dynamic>;
      final role = data['role'] as String?;

      // Persist tokens
      await _secureStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      final user = User.fromJson(userData);

      // Fetch extended profile
      final meData = await fetchMe();

      final rawRole = role ?? meData['role'] as String?;
      final resolvedRole = rawRole != null ? detectRole(rawRole) : null;

      // Save tokens under the resolved role for later account switching.
      if (resolvedRole != null) {
        await _secureStorage.saveRoleTokens(
          resolvedRole,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        role: resolvedRole,
        hasCompletedOnboarding:
            meData['hasCompletedOnboarding'] as bool? ?? false,
        isFreeAccessMode: meData['isFreeAccessModeEnabled'] as bool? ?? false,
        isPro: SubscriptionManager().isPro,
        tier: meData['tier'] as String?,
      );

      // Set auth mode based on the resolved role.
      _apiClient.setMode(resolvedRole == 'trainer');
      _cacheCurrentUser();
    } catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    }
  }

  // ========================================================================
  // Account Switching
  // ========================================================================

  /// Saves the current session's tokens under the current role key
  /// so they can be restored when switching back.
  Future<void> _saveCurrentRoleTokens() async {
    final role = state.role;
    if (role == null) return;
    final accessToken = await _secureStorage.getAccessToken();
    final refreshToken = await _secureStorage.getRefreshToken();
    if (accessToken != null && refreshToken != null) {
      await _secureStorage.saveRoleTokens(
        role,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }

  /// Switches the active auth session to [targetRole] (e.g. "trainer" or
  /// "client").
  ///
  /// 1. Saves current tokens under the current role.
  /// 2. Loads the target role's stored tokens as the active session.
  /// 3. Calls [refreshSession] to verify and populate auth state.
  ///
  /// Returns `true` if the switch succeeded and the new role matches
  /// [targetRole]. Returns `false` if no saved tokens exist for the target
  /// role (caller should show a login flow instead).
  Future<bool> switchToRole(String targetRole) async {
    // 1. Cache the current user before switching.
    _cacheCurrentUser();

    // 2. Save the current session.
    await _saveCurrentRoleTokens();

    // 3. Check for target role tokens.
    final targetTokens = await _secureStorage.getRoleTokens(targetRole);
    if (targetTokens == null) return false;

    // 4. Overwrite active tokens with the target role's tokens.
    await _secureStorage.saveTokens(
      accessToken: targetTokens['accessToken']!,
      refreshToken: targetTokens['refreshToken']!,
    );

    // 5. Switch the API client mode **before** refreshing so that the refresh
    //    request uses the correct auth method (cookies for trainer, token for
    //    client).
    _apiClient.setMode(targetRole == 'trainer');

    // 6. Use cached user data if available to avoid a network fetch.
    final cachedUser = targetRole == 'trainer'
        ? _cachedTrainerUser
        : _cachedClientUser;
    if (cachedUser != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: cachedUser,
        role: targetRole,
      );

      // Fire a background refresh to keep tokens fresh — errors are non-fatal.
      try {
        await refreshSession();
      } catch (_) {
        // Silently ignore background refresh errors.
      }

      return true;
    }

    // 7. No cached user — fall back to the full refresh flow.
    await refreshSession();

    return state.isAuthenticated && state.role == targetRole;
  }

  /// Returns the other role that the user can switch to.
  String? get otherRole =>
      state.role == 'trainer' ? 'client' : state.role == 'client' ? 'trainer' : null;

  /// Human-readable label for a role.
  static String roleLabel(String role) =>
      role == 'trainer' ? 'Professional' : role == 'client' ? 'Personal' : role;

  // ========================================================================
  // Mode-Specific Logout
  // ========================================================================

  /// Surgically logs out only the specified [mode] ('trainer' or 'client')
  /// without affecting the other role's session.
  ///
  /// 1. Calls the server logout endpoint.
  /// 2. Clears only the target mode's tokens from secure storage.
  /// 3. Clears cookies for the target mode.
  /// 4. Clears the relevant user cache.
  /// 5. If [mode] matches the currently active role, resets auth state
  ///    to unauthenticated.
  Future<void> logout({required String mode}) async {
    final isActiveMode = state.role == mode;

    // 1. Call server logout (best-effort).
    try {
      // Switch API client mode temporarily so the signout request uses the
      // correct auth method for the mode being logged out.
      final wasTrainer = mode == 'trainer';
      _apiClient.setMode(wasTrainer);
      await _apiClient.post(ApiConstants.signout);
    } catch (_) {
      // Continue with local cleanup even if the backend call fails.
    } finally {
      // Restore API client mode if we're not logging out the active mode.
      if (!isActiveMode && state.role != null) {
        _apiClient.setMode(state.role == 'trainer');
      }
    }

    // 2. Clear only the target mode's tokens.
    await _secureStorage.clearRoleTokens(mode);

    // 3. Clear cookies for the target mode.
    try {
      await _apiClient.clearCookiesForRole(mode);
    } catch (_) {
      // Best-effort.
    }

    // 4. Clear the relevant user cache.
    if (mode == 'trainer') {
      _cachedTrainerUser = null;
    } else {
      _cachedClientUser = null;
    }

    // 5. If logging out the active mode, reset the auth state.
    if (isActiveMode) {
      // Clear the active tokens too.
      await _secureStorage.clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // ========================================================================
  // Sign Out (full — clears everything)
  // ========================================================================

  Future<void> signOut() async {
    try {
      await _apiClient.post(ApiConstants.signout);
    } catch (_) {
      // Continue with local cleanup even if the backend call fails
    }

    // Clear cookies for the active role before wiping tokens.
    if (state.role != null) {
      await _apiClient.clearCookiesForRole(state.role!);
    }

    _cachedTrainerUser = null;
    _cachedClientUser = null;
    await _secureStorage.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ========================================================================
  // Session Expired Handler
  // ========================================================================

  /// Called when a 401 response could not be resolved by a token refresh
  /// for the given [failingMode].
  ///
  /// Surgically clears only the failing mode's tokens. If the failing mode
  /// is the currently active mode, it resets the auth state so the router
  /// redirects the user to the login screen.
  Future<void> handleUnauthorized(String failingMode) async {
    // Clear the failing mode's role tokens.
    await _secureStorage.clearRoleTokens(failingMode);

    // Clear cookies for the failing mode.
    try {
      await _apiClient.clearCookiesForRole(failingMode);
    } catch (_) {
      // Best-effort.
    }

    // Clear the relevant user cache.
    if (failingMode == 'trainer') {
      _cachedTrainerUser = null;
    } else {
      _cachedClientUser = null;
    }

    // If the failing mode is the active mode, reset to unauthenticated.
    if (state.role == failingMode) {
      await _secureStorage.clearTokens();
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Session expired. Please login again.',
      );
    }
  }

  // ========================================================================
  // Delete Account
  // ========================================================================

  Future<void> deleteAccount({String? reason}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;

      await _apiClient.post(ApiConstants.deleteAccount, body: body);

      await _secureStorage.clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e, st) {
      debugPrint('AUTH_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(
        status: AuthStatus.authenticated,
        error: _extractErrorMessage(e),
      );
      rethrow;
    }
  }

  // ========================================================================
  // Refresh Session
  // ========================================================================

  Future<void> refreshSession() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final Map<String, dynamic> response = await _apiClient.post(
        ApiConstants.refresh,
        body: {'refreshToken': refreshToken},
      );

      // Backend returns { data: { accessToken, refreshToken, expiresAt, user } }
      final data = response['data'] as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await _secureStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      // Fetch profile after successful refresh
      final meData = await fetchMe();

      final rawRole = meData['role'] as String?;
      final refreshedRole = rawRole != null ? detectRole(rawRole) : null;

      // Save tokens under the resolved role for account switching.
      if (refreshedRole != null) {
        await _secureStorage.saveRoleTokens(
          refreshedRole,
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Migrate tokens if the detected role differs from current.
        await _migrateRoleTokensIfNeeded(
          refreshedRole,
          newAccessToken,
          newRefreshToken,
        );
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        user: meData['id'] != null
            ? User(
                id: (meData['id'] ?? '') as String,
                email: (meData['email'] ?? '') as String,
                name: meData['name'] as String?,
              )
            : null,
        role: refreshedRole,
        hasCompletedOnboarding:
            meData['hasCompletedOnboarding'] as bool? ?? false,
        isFreeAccessMode: meData['isFreeAccessModeEnabled'] as bool? ?? false,
        isPro: SubscriptionManager().isPro,
        tier: meData['tier'] as String?,
      );

      // Sync API client mode with the refreshed role.
      if (refreshedRole != null) {
        _apiClient.setMode(refreshedRole == 'trainer');
      }
      _cacheCurrentUser();
    } catch (e, st) {
      debugPrint('AUTH_REFRESH_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      await _secureStorage.clearTokens();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ========================================================================
  // Forgot Password
  // ========================================================================

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _apiClient.post(
        ApiConstants.forgotPassword,
        body: {'email': email},
      );
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _extractErrorMessage(e),
      );
      rethrow;
    }
  }

  // ========================================================================
  // Update Password
  // ========================================================================

  Future<void> updatePassword(String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _apiClient.post(
        ApiConstants.updatePassword,
        body: {'password': password},
      );
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e, st) {
      debugPrint('AUTH_ERROR: $e');
      debugPrint('STACKTRACE: $st');
      state = state.copyWith(
        status: AuthStatus.authenticated,
        error: _extractErrorMessage(e),
      );
      rethrow;
    }
  }

  // ========================================================================
  // Complete Onboarding
  // ========================================================================

  Future<void> completeOnboarding({String? role}) async {
    try {
      await _apiClient.post(ApiConstants.completeOnboarding);
      state = state.copyWith(
        hasCompletedOnboarding: true,
        role: role ?? state.role,
      );
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
      rethrow;
    }
  }

  // ========================================================================
  // Fetch Me
  // ========================================================================

  Future<Map<String, dynamic>> fetchMe() async {
    final Map<String, dynamic> response = await _apiClient.get(ApiConstants.me);
    return (response['data'] as Map<String, dynamic>?) ?? (response);
  }

  // ========================================================================
  // Helpers
  // ========================================================================

  /// Caches the current [state.user] under the role-specific cache field
  /// so that role switching can avoid a network fetch.
  void _cacheCurrentUser() {
    final user = state.user;
    if (user == null) return;
    switch (state.role) {
      case 'trainer':
        _cachedTrainerUser = user;
      case 'client':
        _cachedClientUser = user;
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final errorData = error.response!.data as Map;
        if (errorData['error'] is Map) {
          return (errorData['error'] as Map)['message'] as String? ??
              'An error occurred';
        }
        if (errorData['message'] is String) {
          return errorData['message'] as String;
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 401) {
            return 'Invalid email or password';
          }
          if (error.response?.statusCode == 429) {
            return 'Too many attempts. Please try again later.';
          }
          break;
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
