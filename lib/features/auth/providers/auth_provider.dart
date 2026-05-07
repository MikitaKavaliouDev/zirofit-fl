import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';

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
      id: json['id'] as String,
      email: json['email'] as String,
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
    this.error,
    this.tier,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? role,
    bool? hasCompletedOnboarding,
    bool? isFreeAccessMode,
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

  AuthNotifier({
    required ApiClient apiClient,
    required SecureStorage secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage,
       super(const AuthState());

  // -- Initialize: check stored tokens, attempt auto-login --

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
    } catch (e) {
      await _secureStorage.clearTokens();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Login --

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

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        role: role ?? meData['role'] as String?,
        hasCompletedOnboarding:
            meData['hasCompletedOnboarding'] as bool? ?? false,
        isFreeAccessMode: meData['isFreeAccessModeEnabled'] as bool? ?? false,
        tier: meData['tier'] as String?,
      );

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

  // -- Register --

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

  // -- OAuth --

  Future<void> signInWithOAuth(String provider) async {
    // Opens the mobile-signin URL in the browser.
    // The OAuth callback is handled via deep link → AuthCallbackScreen.
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/auth/mobile-signin',
    ).replace(queryParameters: {'provider': provider});

    await _launchUrl(uri.toString());
  }

  // -- Sign Out --

  Future<void> signOut() async {
    try {
      await _apiClient.post(ApiConstants.signout);
    } catch (_) {
      // Continue with local cleanup even if the backend call fails
    }

    await _secureStorage.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // -- Delete Account --

  Future<void> deleteAccount({String? reason}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;

      await _apiClient.post(ApiConstants.deleteAccount, body: body);

      await _secureStorage.clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        error: _extractErrorMessage(e),
      );
      rethrow;
    }
  }

  // -- Refresh Session --

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

      final data = response['data'] as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await _secureStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      // Fetch profile after successful refresh
      final meData = await fetchMe();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: meData['id'] != null
            ? User(
                id: meData['id'] as String,
                email: meData['email'] as String,
                name: meData['name'] as String?,
              )
            : null,
        role: meData['role'] as String?,
        hasCompletedOnboarding:
            meData['hasCompletedOnboarding'] as bool? ?? false,
        isFreeAccessMode: meData['isFreeAccessModeEnabled'] as bool? ?? false,
        tier: meData['tier'] as String?,
      );
    } catch (e) {
      await _secureStorage.clearTokens();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Forgot Password --

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

  // -- Update Password --

  Future<void> updatePassword(String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _apiClient.post(
        ApiConstants.updatePassword,
        body: {'password': password},
      );
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        error: _extractErrorMessage(e),
      );
      rethrow;
    }
  }

  // -- Complete Onboarding --

  Future<void> completeOnboarding() async {
    try {
      await _apiClient.post(ApiConstants.completeOnboarding);
      state = state.copyWith(hasCompletedOnboarding: true);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
      rethrow;
    }
  }

  // -- Fetch Me --

  Future<Map<String, dynamic>> fetchMe() async {
    final Map<String, dynamic> response = await _apiClient.get(ApiConstants.me);
    return (response['data'] as Map<String, dynamic>?) ?? (response);
  }

  // -- Helpers --

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
