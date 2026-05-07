import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

class MockSecureStorage extends Mock implements SecureStorage {}

// ---------------------------------------------------------------------------
// Response wrapper — the auth_provider accesses response.data['data'];
// we return a Dio Response object so that .data resolves to the body map.
// ---------------------------------------------------------------------------

Response<Map<String, dynamic>> _jsonResponse(
  String path,
  Map<String, dynamic> body,
) {
  return Response<Map<String, dynamic>>(
    data: body,
    requestOptions: RequestOptions(path: path),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Build the body that the /auth/login endpoint returns on success.
Map<String, dynamic> _loginResponseBody({
  String role = 'trainer',
  String userId = 'user-1',
}) {
  return {
    'data': {
      'accessToken': 'test-access-token',
      'refreshToken': 'test-refresh-token',
      'user': {
        'id': userId,
        'email': 'test@test.com',
        'name': 'Test User',
      },
      'role': role,
    },
  };
}

/// Build the body that the /auth/me endpoint returns on success.
Map<String, dynamic> _meResponseBody({
  String role = 'trainer',
  String userId = 'user-1',
  bool hasCompletedOnboarding = true,
  bool isFreeAccessModeEnabled = false,
  String? tier = 'premium',
}) {
  return {
    'data': {
      'id': userId,
      'email': 'test@test.com',
      'name': 'Test User',
      'role': role,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'isFreeAccessModeEnabled': isFreeAccessModeEnabled,
      'tier': tier,
    },
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late MockSecureStorage mockSecureStorage;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    mockSecureStorage = MockSecureStorage();

    container = createTestContainer(overrides: [
      apiClientProvider.overrideWith((ref) => mockApiClient),
      secureStorageProvider.overrideWith((ref) => mockSecureStorage),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier — login', () {
    test('login succeeds and transitions to authenticated', () async {
      // Arrange
      when(() => mockSecureStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenAnswer((_) async => _loginResponseBody());

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _meResponseBody());

      // Act
      final result = await container
          .read(authProvider.notifier)
          .login('test@test.com', 'password123');

      // Assert
      expect(result.hasValue, isTrue);
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, isNotNull);
      expect(state.user!.email, 'test@test.com');
      expect(state.role, 'trainer');
      expect(state.hasCompletedOnboarding, isTrue);
      expect(state.isFreeAccessMode, isFalse);
      expect(state.tier, 'premium');

      verify(() => mockSecureStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).called(1);
      verify(() => mockApiClient.post(ApiConstants.login, body: any(named: 'body')))
          .called(1);
      verify(() => mockApiClient.get(
            ApiConstants.me,
            queryParams: any(named: 'queryParams'),
          )).called(1);
    });

    test('login fails with 401 and transitions to error state', () async {
      // Arrange
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: ApiConstants.login),
          data: {'error': {'message': 'Invalid email or password'}},
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await container
          .read(authProvider.notifier)
          .login('wrong@test.com', 'wrong-password');

      // Assert
      expect(result.hasError, isTrue);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.hasError, isTrue);
      expect(state.error, contains('Invalid email or password'));
    });

    test('login sets loading state during request', () async {
      // Arrange — delay the response so we can observe the loading state
      when(() => mockSecureStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return _loginResponseBody();
      });

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _meResponseBody());

      // Act — kick off login and immediately check loading
      final loginFuture = container
          .read(authProvider.notifier)
          .login('test@test.com', 'password123');

      // Should be loading after the call starts
      expect(container.read(authProvider).isLoading, isTrue);

      await loginFuture;

      // Should be authenticated after completion
      expect(container.read(authProvider).isAuthenticated, isTrue);
    });
  });

  group('AuthNotifier — register', () {
    test('register succeeds and stays unauthenticated', () async {
      // Arrange
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.register,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'data': <String, dynamic>{}});

      // Act
      final result = await container
          .read(authProvider.notifier)
          .register('New User', 'new@test.com', 'password123', role: 'client');

      // Assert
      expect(result.hasValue, isTrue);
      final state = container.read(authProvider);
      expect(state.isUnauthenticated, isTrue);
      expect(state.user, isNull);
      expect(state.error, isNull);

      verify(() => mockApiClient.post(
            ApiConstants.register,
            body: any(named: 'body'),
          )).called(1);
    });

    test('register sets error on failure', () async {
      // Arrange
      when(() => mockApiClient.post(
            ApiConstants.register,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.register),
        response: Response(
          statusCode: 422,
          requestOptions: RequestOptions(path: ApiConstants.register),
          data: {'error': {'message': 'Email already taken'}},
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await container
          .read(authProvider.notifier)
          .register('Existing', 'exists@test.com', 'password123');

      // Assert
      expect(result.hasError, isTrue);
      final state = container.read(authProvider);
      expect(state.isUnauthenticated, isTrue);
      expect(state.hasError, isTrue);
      expect(state.error, contains('Email already taken'));
    });
  });

  group('AuthNotifier — signOut', () {
    test('signOut calls API and clears tokens', () async {
      // Arrange — first log in so we have an authenticated state
      when(() => mockSecureStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      when(() => mockSecureStorage.clearTokens()).thenAnswer((_) async {});

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenAnswer((_) async => _loginResponseBody());
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _meResponseBody());

      await container
          .read(authProvider.notifier)
          .login('test@test.com', 'password123');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      // Arrange — mock signout endpoint
      when(() => mockApiClient.post<Map<String, dynamic>>(ApiConstants.signout, body: any(named: 'body')))
          .thenAnswer((_) async => <String, dynamic>{});

      // Act
      await container.read(authProvider.notifier).signOut();

      // Assert
      final state = container.read(authProvider);
      expect(state.isUnauthenticated, isTrue);
      expect(state.user, isNull);
      expect(state.error, isNull);

      verify(() => mockApiClient.post(ApiConstants.signout)).called(1);
      verify(() => mockSecureStorage.clearTokens()).called(1);
    });

    test('signOut still clears tokens even when API call fails', () async {
      // Arrange — log in first
      when(() => mockSecureStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      when(() => mockSecureStorage.clearTokens()).thenAnswer((_) async {});

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenAnswer((_) async => _loginResponseBody());
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _meResponseBody());

      await container
          .read(authProvider.notifier)
          .login('test@test.com', 'password123');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      // Arrange — signout API fails
      when(() => mockApiClient.post<Map<String, dynamic>>(ApiConstants.signout, body: any(named: 'body')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.signout),
        type: DioExceptionType.connectionError,
      ));

      // Act — should not throw (the catch in signOut handles it)
      await container.read(authProvider.notifier).signOut();

      // Assert — still signed out locally
      final state = container.read(authProvider);
      expect(state.isUnauthenticated, isTrue);
      verify(() => mockSecureStorage.clearTokens()).called(1);
    });
  });
}
