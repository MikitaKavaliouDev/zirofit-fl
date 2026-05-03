import '../common/user_fixture.dart';

/// Factory for generating auth-related JSON payloads.
///
/// All JSON keys use snake_case to match the backend wire format.
class AuthFixture {
  /// Successful login response.
  static Map<String, dynamic> loginResponse() => {
        'message': 'Login successful.',
        'role': 'trainer',
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'user': UserFixture.createJson(),
      };

  /// Successful register response.
  static Map<String, dynamic> registerResponse() => {
        'message':
            'Registration successful. Please check your email to verify your account.',
        'role': 'trainer',
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'user': UserFixture.createJson(),
      };

  /// Token refresh response.
  static Map<String, dynamic> refreshResponse() => {
        'access_token': 'new-access-token',
        'refresh_token': 'new-refresh-token',
      };

  /// Login error — invalid credentials.
  static Map<String, dynamic> invalidCredentialsError() => {
        'error': {
          'message': 'Invalid email or password.',
          'code': 'INVALID_CREDENTIALS',
          'status_code': 401,
        },
      };

  /// Login error — account not verified.
  static Map<String, dynamic> emailNotVerifiedError() => {
        'error': {
          'message': 'Please verify your email before logging in.',
          'code': 'EMAIL_NOT_VERIFIED',
          'status_code': 403,
        },
      };

  /// Refresh error — expired / invalid token.
  static Map<String, dynamic> refreshTokenExpiredError() => {
        'error': {
          'message': 'Refresh token has expired. Please log in again.',
          'code': 'REFRESH_TOKEN_EXPIRED',
          'status_code': 401,
        },
      };

  /// Generic server error.
  static Map<String, dynamic> serverError() => {
        'error': {
          'message': 'Internal server error.',
          'code': 'SERVER_ERROR',
          'status_code': 500,
        },
      };
}
