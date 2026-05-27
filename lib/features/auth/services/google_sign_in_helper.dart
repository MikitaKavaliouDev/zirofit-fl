import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';

/// Result returned by [GoogleSignInHelper.signIn] when the user successfully
/// authenticates with Google via the Supabase OAuth flow (mirrors iOS).
class GoogleSignInResult {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String? role;

  const GoogleSignInResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    this.role,
  });
}

/// Helper class that encapsulates the Google OAuth web flow using an in-app
/// browser session, mirroring the iOS [GoogleSignInHelper] which uses
/// [ASWebAuthenticationSession].
///
/// The flow:
/// 1. Opens the Supabase mobile-signin URL for the `google` provider in an
///    in-app browser (ASWebAuthenticationSession on iOS, Chrome Custom Tabs
///    on Android).
/// 2. The server completes the OAuth dance and redirects to
///    `zirofitapp://auth/callback?access_token=...&refresh_token=...&user_id=...`
/// 3. The callback URL is intercepted by the session and parsed for tokens.
/// 4. Returns a [GoogleSignInResult] with the extracted credentials.
class GoogleSignInHelper {
  /// The custom URL scheme registered for the app.
  static const String _callbackScheme = 'zirofitapp';

  /// Presents an in-app browser for Google OAuth and waits for the callback.
  ///
  /// Returns a [GoogleSignInResult] on success.
  ///
  /// Throws a [GoogleSignInException] when:
  /// - The user cancels sign-in.
  /// - The callback URL is malformed or missing required tokens.
  /// - The underlying web auth session fails.
  Future<GoogleSignInResult> signIn() async {
    final url = '${ApiConstants.baseUrl}/auth/mobile-signin?provider=google';

    try {
      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: _callbackScheme,
        options: const FlutterWebAuth2Options(
          preferEphemeral: true, // Don't share cookies with Safari — more secure
        ),
      );

      return _parseCallbackUrl(callbackUrl);
    } on Exception catch (e) {
      // flutter_web_auth_2 throws a FormatException when the user cancels.
      final message = e.toString();
      if (message.contains('Canceled') ||
          message.contains('cancelled') ||
          message.contains('USER_CANCELED') ||
          message.contains('CANCEL')) {
        throw const GoogleSignInException('Sign in cancelled');
      }
      throw GoogleSignInException('Authentication failed: $e');
    }
  }

  /// Parses the callback URL and extracts tokens.
  ///
  /// Expected format:
  ///   zirofitapp://auth/callback?access_token=...&refresh_token=...&user_id=...
  GoogleSignInResult _parseCallbackUrl(String rawUrl) {
    final uri = Uri.parse(rawUrl);

    // Some implementations return the path as the callback; handle both.
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final userId = uri.queryParameters['user_id'];
    final role = uri.queryParameters['role'];

    if (accessToken == null || refreshToken == null || userId == null) {
      throw const GoogleSignInException(
        'Missing tokens in authentication callback',
      );
    }

    return GoogleSignInResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      role: role,
    );
  }
}

/// Exception thrown by [GoogleSignInHelper] for non-success outcomes.
class GoogleSignInException implements Exception {
  final String message;

  const GoogleSignInException(this.message);

  @override
  String toString() => 'GoogleSignInException: $message';
}
