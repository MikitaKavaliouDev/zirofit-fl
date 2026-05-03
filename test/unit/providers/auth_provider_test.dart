import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import '../../fixtures/auth/auth_fixture.dart';
import '../../helpers/provider_utils.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApiClient;
  late MockSecureStorage mockSecureStorage;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    mockSecureStorage = MockSecureStorage();
    container = createTestContainer(overrides: [
      apiClientProvider.overrideWithValue(mockApiClient as ApiClient),
      secureStorageProvider.overrideWithValue(mockSecureStorage),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  // ---------------------------------------------------------------------------
  // Stub helpers
  // ---------------------------------------------------------------------------

  Response<Map<String, dynamic>> loginResponse({
    String role = 'trainer',
    String userId = 'test-user-id',
    String email = 'trainer@ziro.fit',
    String name = 'Test Trainer',
  }) {
    return Response(
      requestOptions: RequestOptions(path: ApiConstants.login),
      statusCode: 200,
      data: {
        'data': {
          'message': 'Login successful.',
          'accessToken': 'test-access-token',
          'refreshToken': 'test-refresh-token',
          'role': role,
          'user': {
            'id': userId,
            'email': email,
            'name': name,
          },
        },
      },
    );
  }

  Response<Map<String, dynamic>> meResponse({
    String id = 'test-user-id',
    String email = 'trainer@ziro.fit',
    String name = 'Test Trainer',
    String role = 'trainer',
    Object? tier = 'PRO',
    bool hasCompletedOnboarding = true,
    bool isFreeAccessModeEnabled = false,
  }) {
    return Response(
      requestOptions: RequestOptions(path: ApiConstants.me),
      statusCode: 200,
      data: {
        'data': {
          'id': id,
          'email': email,
          'name': name,
          'role': role,
          'tier': tier,
          'hasCompletedOnboarding': hasCompletedOnboarding,
          'isFreeAccessModeEnabled': isFreeAccessModeEnabled,
        },
      },
    );
  }

  Response<Map<String, dynamic>> refreshResponse() {
    return Response(
      requestOptions: RequestOptions(path: ApiConstants.refresh),
      statusCode: 200,
      data: {
        'data': {
          'accessToken': 'new-access-token',
          'refreshToken': 'new-refresh-token',
        },
      },
    );
  }

  /// Stubs a successful login flow (post + saveTokens + fetchMe).
  void stubLoginSuccess({
    String role = 'trainer',
    Object? tier = 'PRO',
    bool hasCompletedOnboarding = true,
  }) {
    when(() => mockApiClient.post(
          ApiConstants.login,
          body: any(named: 'body'),
        )).thenAnswer((_) async => loginResponse(role: role));

    when(() => mockSecureStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});

    when(() => mockApiClient.get(
          ApiConstants.me,
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => meResponse(
          role: role,
          tier: tier,
          hasCompletedOnboarding: hasCompletedOnboarding,
        ));
  }

  /// Stubs a successful refresh flow (getRefreshToken + post + saveTokens + me).
  void stubRefreshSuccess({
    String role = 'trainer',
    Object? tier = 'PRO',
    bool hasCompletedOnboarding = true,
  }) {
    when(() => mockSecureStorage.getRefreshToken())
        .thenAnswer((_) async => 'stored-refresh-token');

    when(() => mockApiClient.post(
          ApiConstants.refresh,
          body: any(named: 'body'),
        )).thenAnswer((_) async => refreshResponse());

    when(() => mockSecureStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});

    when(() => mockApiClient.get(
          ApiConstants.me,
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => meResponse(
          role: role,
          tier: tier,
          hasCompletedOnboarding: hasCompletedOnboarding,
        ));
  }

  /// Stubs sign-out flow.
  void stubSignOutSuccess() {
    when(() => mockApiClient.post(
          ApiConstants.signout,
          body: any(named: 'body'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.signout),
          statusCode: 200,
          data: {'data': {'message': 'Signed out.'}},
        ));
    when(() => mockSecureStorage.clearTokens()).thenAnswer((_) async {});
  }

  // ===========================================================================
  // AuthState
  // ===========================================================================

  group('AuthState', () {
    test('default constructor uses initial status and null fields', () {
      const state = AuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.role, isNull);
      expect(state.tier, isNull);
      expect(state.error, isNull);
      expect(state.hasCompletedOnboarding, false);
      expect(state.isFreeAccessMode, false);
    });

    test('copyWith preserves existing fields when no arguments', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        role: 'trainer',
        tier: 'PRO',
        hasCompletedOnboarding: true,
        error: 'some error',
      );
      final copied = state.copyWith();
      expect(copied.status, AuthStatus.authenticated);
      expect(copied.role, 'trainer');
      expect(copied.tier, 'PRO');
      expect(copied.hasCompletedOnboarding, true);
      expect(copied.error, 'some error');
    });

    test('copyWith overrides specified fields', () {
      const state = AuthState(status: AuthStatus.initial);
      final copied = state.copyWith(
        status: AuthStatus.authenticated,
        role: 'client',
        tier: 'FREE',
      );
      expect(copied.status, AuthStatus.authenticated);
      expect(copied.role, 'client');
      expect(copied.tier, 'FREE');
    });

    test('copyWith with clearError=true removes error', () {
      const state = AuthState(status: AuthStatus.error, error: 'boom');
      final copied = state.copyWith(clearError: true);
      expect(copied.hasError, false);
      expect(copied.error, isNull);
    });

    test(
        'copyWith with clearError=true ignores error parameter '
        'and still clears', () {
      const state = AuthState(status: AuthStatus.error, error: 'boom');
      final copied = state.copyWith(clearError: true, error: 'should-not-appear');
      expect(copied.error, isNull);
    });

    test('copyWith preserves user and free-access fields', () {
      const user = User(id: '1', email: 'a@b.com');
      const state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isFreeAccessMode: true,
      );
      final copied = state.copyWith(hasCompletedOnboarding: true);
      expect(copied.user, same(user));
      expect(copied.isFreeAccessMode, true);
      expect(copied.hasCompletedOnboarding, true);
    });

    // -- Getters --

    group('getters', () {
      test('isTrainer returns true when role is trainer', () {
        const state = AuthState(role: 'trainer');
        expect(state.isTrainer, true);
        expect(state.isClient, false);
        expect(state.isAdmin, false);
        expect(state.isPending, false);
      });

      test('isClient returns true when role is client', () {
        const state = AuthState(role: 'client');
        expect(state.isClient, true);
        expect(state.isTrainer, false);
      });

      test('isAdmin returns true when role is admin', () {
        const state = AuthState(role: 'admin');
        expect(state.isAdmin, true);
        expect(state.isClient, false);
      });

      test('isPending returns true when role is pending', () {
        const state = AuthState(role: 'pending');
        expect(state.isPending, true);
        expect(state.isClient, false);
      });

      test('isAuthenticated returns true for authenticated status', () {
        const state = AuthState(status: AuthStatus.authenticated);
        expect(state.isAuthenticated, true);
        expect(state.isUnauthenticated, false);
        expect(state.isLoading, false);
      });

      test('isLoading returns true for loading status', () {
        const state = AuthState(status: AuthStatus.loading);
        expect(state.isLoading, true);
        expect(state.isAuthenticated, false);
      });

      test('isUnauthenticated returns true for unauthenticated status', () {
        const state = AuthState(status: AuthStatus.unauthenticated);
        expect(state.isUnauthenticated, true);
        expect(state.isAuthenticated, false);
      });

      test('hasError returns true when error is set', () {
        const state = AuthState(error: 'something went wrong');
        expect(state.hasError, true);
      });

      test('hasError returns false when error is null', () {
        const state = AuthState();
        expect(state.hasError, false);
      });

      test('initial state is unauthenticated, not loading, no error', () {
        const state = AuthState();
        expect(state.isAuthenticated, false);
        expect(state.isLoading, false);
        expect(state.isUnauthenticated, false);
        expect(state.hasError, false);
      });
    });

    group('role and tier propagation', () {
      test('role is propagated through copyWith', () {
        const state = AuthState(role: 'trainer');
        final copied = state.copyWith(status: AuthStatus.authenticated);
        expect(copied.role, 'trainer');
      });

      test('tier is propagated through copyWith', () {
        const state = AuthState(tier: 'PRO');
        final copied = state.copyWith(hasCompletedOnboarding: true);
        expect(copied.tier, 'PRO');
      });

      test('role and tier can be updated in copyWith', () {
        const state = AuthState(role: 'trainer', tier: 'PRO');
        final copied = state.copyWith(role: 'client', tier: 'FREE');
        expect(copied.role, 'client');
        expect(copied.tier, 'FREE');
      });

      test('all getters are false when role is null', () {
        const state = AuthState();
        expect(state.isTrainer, false);
        expect(state.isClient, false);
        expect(state.isAdmin, false);
        expect(state.isPending, false);
      });
    });
  });

  // ===========================================================================
  // initialize
  // ===========================================================================

  group('initialize', () {
    test('transitions to loading at start', () async {
      final completer = Completer<bool>();
      when(() => mockSecureStorage.hasTokens())
          .thenAnswer((_) => completer.future);

      // Start the initialization but don't await yet
      final initFuture =
          container.read(authProvider.notifier).initialize();

      // Loading state should be set synchronously
      expect(container.read(authProvider).status, AuthStatus.loading);

      completer.complete(false);
      await initFuture;
    });

    test('transitions to unauthenticated when no tokens stored', () async {
      when(() => mockSecureStorage.hasTokens())
          .thenAnswer((_) async => false);

      await container.read(authProvider.notifier).initialize();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.error, isNull);
    });

    test('transitions to authenticated when tokens exist and refresh succeeds',
        () async {
      when(() => mockSecureStorage.hasTokens())
          .thenAnswer((_) async => true);
      stubRefreshSuccess(
        role: 'trainer',
        tier: 'PRO',
        hasCompletedOnboarding: true,
      );

      await container.read(authProvider.notifier).initialize();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.role, 'trainer');
      expect(state.tier, 'PRO');
      expect(state.hasCompletedOnboarding, true);
      expect(state.user, isNotNull);
      expect(state.user!.id, 'test-user-id');
    });

    test('transitions to unauthenticated when refresh fails '
        'and tokens are cleared', () async {
      when(() => mockSecureStorage.hasTokens())
          .thenAnswer((_) async => true);
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => 'stored-refresh-token');
      when(() => mockApiClient.post(
            ApiConstants.refresh,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.refresh),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.refresh),
          statusCode: 401,
        ),
      ));
      when(() => mockSecureStorage.clearTokens())
          .thenAnswer((_) async {});

      await container.read(authProvider.notifier).initialize();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
      verify(() => mockSecureStorage.clearTokens()).called(1);
    });

    test('handles storage exception and clears tokens', () async {
      when(() => mockSecureStorage.hasTokens())
          .thenThrow(Exception('storage error'));
      when(() => mockSecureStorage.clearTokens())
          .thenAnswer((_) async {});

      await container.read(authProvider.notifier).initialize();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.hasError, true);
      verify(() => mockSecureStorage.clearTokens()).called(1);
    });

    test('handles refresh fetchMe failure and clears tokens', () async {
      when(() => mockSecureStorage.hasTokens())
          .thenAnswer((_) async => true);
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => 'stored-refresh-token');
      when(() => mockApiClient.post(
            ApiConstants.refresh,
            body: any(named: 'body'),
          )).thenAnswer((_) async => refreshResponse());
      when(() => mockSecureStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      // fetchMe not stubbed → mocktail throws
      when(() => mockSecureStorage.clearTokens())
          .thenAnswer((_) async {});

      await container.read(authProvider.notifier).initialize();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.hasError, true);
      verify(() => mockSecureStorage.clearTokens()).called(1);
    });
  });

  // ===========================================================================
  // login
  // ===========================================================================

  group('login', () {
    test('state is loading at start of login call', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenAnswer((_) => completer.future);

      final loginFuture =
          container.read(authProvider.notifier).login('a@b.com', 'pass');

      expect(container.read(authProvider).status, AuthStatus.loading);

      completer.completeError(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.connectionTimeout,
      ));
      await loginFuture;
    });

    test('success with trainer role', () async {
      stubLoginSuccess(
        role: 'trainer',
        tier: 'PRO',
        hasCompletedOnboarding: true,
      );

      final result = await container
          .read(authProvider.notifier)
          .login('trainer@ziro.fit', 'password123');

      expect(result, isA<AsyncData<User>>());
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.role, 'trainer');
      expect(state.tier, 'PRO');
      expect(state.hasCompletedOnboarding, true);
      expect(state.user, isNotNull);
    });

    test('success with client role', () async {
      stubLoginSuccess(
        role: 'client',
        tier: 'FREE',
        hasCompletedOnboarding: false,
      );

      final result = await container
          .read(authProvider.notifier)
          .login('client@ziro.fit', 'password123');

      expect(result, isA<AsyncData<User>>());
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.role, 'client');
      expect(state.tier, 'FREE');
      expect(state.hasCompletedOnboarding, false);
    });

    test('success with pending role', () async {
      stubLoginSuccess(
        role: 'pending',
        tier: null,
        hasCompletedOnboarding: false,
      );

      final result = await container
          .read(authProvider.notifier)
          .login('pending@ziro.fit', 'password123');

      expect(result, isA<AsyncData<User>>());
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.role, 'pending');
    });

    test('success when fetchMe returns flat data (no data key)', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenAnswer((_) async => loginResponse(role: 'trainer'));

      when(() => mockSecureStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      // Flat response: no 'data' wrapper
      when(() => mockApiClient.get(
            ApiConstants.me,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.me),
            statusCode: 200,
            data: {
              'id': 'user-1',
              'email': 'flat@ziro.fit',
              'name': 'Flat User',
              'role': 'client',
              'tier': 'BASIC',
              'hasCompletedOnboarding': false,
              'isFreeAccessModeEnabled': true,
            },
          ));

      final result = await container
          .read(authProvider.notifier)
          .login('flat@ziro.fit', 'pass');

      expect(result, isA<AsyncData<User>>());
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.role, 'trainer'); // from login response, not me
      expect(state.tier, 'BASIC'); // from flat me response
      expect(state.isFreeAccessMode, true);
    });

    // -- Error: connectionTimeout --

    test('error: connectionTimeout returns connection timeout message',
        () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.connectionTimeout,
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(
        state.error,
        contains('Connection timeout'),
      );
    });

    // -- Error: connectionError --

    test('error: connectionError returns no internet message', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.connectionError,
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(
        state.error,
        contains('No internet connection'),
      );
    });

    // -- Error: badResponse 401 structured --

    test('error: badResponse 401 with structured error.message', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 401,
          data: {
            'error': {'message': 'Invalid email or password'},
          },
        ),
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('bad@email.com', 'wrong');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, 'Invalid email or password');
    });

    // -- Error: badResponse 401 plain message --

    test('error: badResponse 401 with plain message field', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 401,
          data: {'message': 'Custom 401 message'},
        ),
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('bad@email.com', 'wrong');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, 'Custom 401 message');
    });

    // -- Error: badResponse 401 no data --

    test('error: badResponse 401 with no response data returns default 401 message',
        () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 401,
        ),
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('bad@email.com', 'wrong');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, 'Invalid email or password');
    });

    // -- Error: badResponse 429 --

    test('error: badResponse 429 returns too many attempts', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 429,
        ),
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, contains('Too many attempts'));
    });

    // -- Error: badResponse 500 --

    test('error: badResponse 500 returns network error', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 500,
        ),
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, contains('Network error'));
    });

    // -- Error: badResponse 422 --

    test('error: badResponse 422 returns network error', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 422,
        ),
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, contains('Network error'));
    });

    // -- Error: badResponse unknown status code --

    test('error: badResponse with unknown status code returns network error',
        () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 503,
        ),
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, contains('Network error'));
    });

    // -- Error: unknown DioException type --

    test('error: unknown DioException type returns network error', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.unknown,
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, contains('Network error'));
    });

    // -- Error: cancel type --

    test('error: cancel type returns network error', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.cancel,
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, contains('Network error'));
    });

    // -- Error: sendTimeout --

    test('error: sendTimeout returns connection timeout', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.sendTimeout,
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, contains('Connection timeout'));
    });

    // -- Error: receiveTimeout --

    test('error: receiveTimeout returns connection timeout', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.receiveTimeout,
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, contains('Connection timeout'));
    });

    // -- Error: generic Exception --

    test('error: generic Exception returns error.toString()', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(Exception('Something terrible happened'));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, 'Exception: Something terrible happened');
    });

    // -- Error: badResponse 429 with structured data --

    test(
        'error: badResponse 429 with structured error.message returns '
        'the structured message', () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 429,
          data: {
            'error': {'message': 'Rate limited buddy'},
          },
        ),
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, 'Rate limited buddy');
    });

    // -- Error: structured error with no message --

    test('error: structured error without message returns An error occurred',
        () async {
      when(() => mockApiClient.post(
            ApiConstants.login,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 400,
          data: {'error': {'code': 'UNKNOWN'}},
        ),
      ));

      final result = await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      expect(result, isA<AsyncError<User>>());
      final state = container.read(authProvider);
      expect(state.error, 'An error occurred');
    });
  });

  // ===========================================================================
  // register
  // ===========================================================================

  group('register', () {
    test('state is loading at start of register call', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(() => mockApiClient.post(
            ApiConstants.register,
            body: any(named: 'body'),
          )).thenAnswer((_) => completer.future);

      final registerFuture = container
          .read(authProvider.notifier)
          .register('Name', 'a@b.com', 'pass');

      expect(container.read(authProvider).status, AuthStatus.loading);

      completer.completeError(Exception('cleanup'));
      await registerFuture;
    });

    test('success with role and trainerId includes correct body params',
        () async {
      when(() => mockApiClient.post(
            ApiConstants.register,
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.register),
            statusCode: 201,
            data: {'data': {'message': 'Registration successful.'}},
          ));

      await container.read(authProvider.notifier).register(
            'Test User',
            'email@test.com',
            'Password123!',
            role: 'trainer',
            trainerId: 'trainer-123',
          );

      // Verify body contains all expected params
      verify(() => mockApiClient.post(
            ApiConstants.register,
            body: {
              'name': 'Test User',
              'email': 'email@test.com',
              'password': 'Password123!',
              'role': 'trainer',
              'trainerId': 'trainer-123',
            },
          )).called(1);

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('success without optional params', () async {
      when(() => mockApiClient.post(
            ApiConstants.register,
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.register),
            statusCode: 201,
            data: {'data': {'message': 'Registration successful.'}},
          ));

      await container.read(authProvider.notifier).register(
            'Simple User',
            'simple@test.com',
            'Password123!',
          );

      // Verify body has only required params
      verify(() => mockApiClient.post(
            ApiConstants.register,
            body: {
              'name': 'Simple User',
              'email': 'simple@test.com',
              'password': 'Password123!',
            },
          )).called(1);

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('transitions to unauthenticated on success', () async {
      when(() => mockApiClient.post(
            ApiConstants.register,
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.register),
            statusCode: 201,
            data: {'data': {'message': 'Registration successful.'}},
          ));

      await container.read(authProvider.notifier).register(
            'Test', 'test@test.com', 'Password123!',
            role: 'client',
          );

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.error, isNull);
    });

    test('error: DioException with structured error.message', () async {
      when(() => mockApiClient.post(
            ApiConstants.register,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.register),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.register),
          statusCode: 422,
          data: {
            'error': {'message': 'Email already taken'},
          },
        ),
      ));

      final result = await container.read(authProvider.notifier).register(
            'Test', 'taken@test.com', 'Password123!',
          );

      expect(result, isA<AsyncError<void>>());
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.error, 'Email already taken');
    });

    test('error: generic Exception returns error.toString()', () async {
      when(() => mockApiClient.post(
            ApiConstants.register,
            body: any(named: 'body'),
          )).thenThrow(Exception('Registration failed'));

      final result = await container.read(authProvider.notifier).register(
            'Test', 'a@b.com', 'pass',
          );

      expect(result, isA<AsyncError<void>>());
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.error, 'Exception: Registration failed');
    });
  });

  // ===========================================================================
  // signInWithOAuth
  // ===========================================================================

  group('signInWithOAuth', () {
    test('attempts to launch URL (throws in test environment)', () async {
      // In the test environment, url_launcher.launchUrl will throw
      // a MissingPluginException because the platform channel is not
      // implemented. We verify the method is called and an exception
      // from the launcher propagates.
      await expectLater(
        () =>
            container.read(authProvider.notifier).signInWithOAuth('google'),
        throwsA(isA<Exception>()),
      );
    });

    test('does not modify auth state when it throws', () async {
      // State should remain initial since the method never touches state
      final stateBefore = container.read(authProvider);
      expect(stateBefore.status, AuthStatus.initial);

      try {
        await container
            .read(authProvider.notifier)
            .signInWithOAuth('google');
      } catch (_) {
        // Expected — url_launcher has no platform implementation in tests.
      }

      final stateAfter = container.read(authProvider);
      expect(stateAfter.status, AuthStatus.initial);
      expect(stateAfter.user, isNull);
      expect(stateAfter.error, isNull);
    });
  });

  // ===========================================================================
  // signOut
  // ===========================================================================

  group('signOut', () {
    test('API succeeds, tokens cleared, state unauthenticated', () async {
      stubSignOutSuccess();

      await container.read(authProvider.notifier).signOut();

      verify(() => mockSecureStorage.clearTokens()).called(1);
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
      expect(state.role, isNull);
    });

    test('API fails (throws), tokens still cleared, state unauthenticated',
        () async {
      when(() => mockApiClient.post(
            ApiConstants.signout,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.signout),
        type: DioExceptionType.connectionError,
      ));
      when(() => mockSecureStorage.clearTokens())
          .thenAnswer((_) async {});

      await container.read(authProvider.notifier).signOut();

      verify(() => mockSecureStorage.clearTokens()).called(1);
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
    });

    test('propagates exception when clearTokens throws', () async {
      when(() => mockApiClient.post(
            ApiConstants.signout,
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.signout),
            statusCode: 200,
            data: {'data': {'message': 'Signed out.'}},
          ));
      when(() => mockSecureStorage.clearTokens())
          .thenThrow(Exception('storage error'));

      // signOut does not catch clearTokens exceptions, so it propagates
      await expectLater(
        () => container.read(authProvider.notifier).signOut(),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ===========================================================================
  // refreshSession
  // ===========================================================================

  group('refreshSession', () {
    test('preserves initial state while waiting for refresh token', () async {
      // refreshSession does NOT set loading state; the first operation
      // is awaiting getRefreshToken(). During that await the state is
      // whatever it was before the call.
      final completer = Completer<String?>();
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) => completer.future);

      final refreshFuture =
          container.read(authProvider.notifier).refreshSession();

      // State should still be initial (not touched by refreshSession)
      expect(container.read(authProvider).status, AuthStatus.initial);

      completer.complete(null);
      await refreshFuture;

      // After null token → unauthenticated
      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    });

    test('no refresh token transitions to unauthenticated', () async {
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => null);

      await container.read(authProvider.notifier).refreshSession();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
    });

    test('success transitions to authenticated with role/tier/onboarding',
        () async {
      stubRefreshSuccess(
        role: 'trainer',
        tier: 'PRO',
        hasCompletedOnboarding: true,
      );

      await container.read(authProvider.notifier).refreshSession();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.role, 'trainer');
      expect(state.tier, 'PRO');
      expect(state.hasCompletedOnboarding, true);
      expect(state.user, isNotNull);
      expect(state.user!.id, 'test-user-id');
      expect(state.user!.email, 'trainer@ziro.fit');
    });

    test('success with client role and BASIC tier', () async {
      stubRefreshSuccess(
        role: 'client',
        tier: 'BASIC',
        hasCompletedOnboarding: false,
      );

      await container.read(authProvider.notifier).refreshSession();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.role, 'client');
      expect(state.tier, 'BASIC');
      expect(state.hasCompletedOnboarding, false);
    });

    test('does not create User when meData id is null', () async {
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => 'stored-refresh-token');
      when(() => mockApiClient.post(
            ApiConstants.refresh,
            body: any(named: 'body'),
          )).thenAnswer((_) async => refreshResponse());
      when(() => mockSecureStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      when(() => mockApiClient.get(
            ApiConstants.me,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.me),
            statusCode: 200,
            data: {
              'data': {
                'role': 'trainer',
                'tier': 'PRO',
                'hasCompletedOnboarding': true,
                'isFreeAccessModeEnabled': false,
                // no 'id' field → user should be null
              },
            },
          ));

      await container.read(authProvider.notifier).refreshSession();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNull);
      expect(state.role, 'trainer');
      expect(state.tier, 'PRO');
    });

    test('failure clears tokens and sets error state', () async {
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => 'stored-refresh-token');
      when(() => mockApiClient.post(
            ApiConstants.refresh,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.refresh),
        type: DioExceptionType.connectionTimeout,
      ));
      when(() => mockSecureStorage.clearTokens())
          .thenAnswer((_) async {});

      await container.read(authProvider.notifier).refreshSession();

      verify(() => mockSecureStorage.clearTokens()).called(1);
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.hasError, true);
      expect(state.error, contains('Connection timeout'));
    });

    test('fetchMe throws within refresh clears tokens and sets error',
        () async {
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => 'stored-refresh-token');
      when(() => mockApiClient.post(
            ApiConstants.refresh,
            body: any(named: 'body'),
          )).thenAnswer((_) async => refreshResponse());
      when(() => mockSecureStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      // fetchMe not stubbed → mocktail throws
      when(() => mockSecureStorage.clearTokens())
          .thenAnswer((_) async {});

      await container.read(authProvider.notifier).refreshSession();

      verify(() => mockSecureStorage.clearTokens()).called(1);
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.hasError, true);
    });
  });

  // ===========================================================================
  // forgotPassword
  // ===========================================================================

  group('forgotPassword', () {
    test('state is loading during call', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(() => mockApiClient.post(
            ApiConstants.forgotPassword,
            body: any(named: 'body'),
          )).thenAnswer((_) => completer.future);

      final future =
          container.read(authProvider.notifier).forgotPassword('a@b.com');

      expect(container.read(authProvider).status, AuthStatus.loading);

      completer.completeError(Exception('cleanup'));
      await expectLater(future, throwsA(isA<Exception>()));
    });

    test('success transitions to unauthenticated', () async {
      when(() => mockApiClient.post(
            ApiConstants.forgotPassword,
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.forgotPassword),
            statusCode: 200,
            data: {'data': {'message': 'Email sent.'}},
          ));

      await container
          .read(authProvider.notifier)
          .forgotPassword('user@ziro.fit');

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.error, isNull);
    });

    test('error sets error state and rethrows', () async {
      when(() => mockApiClient.post(
            ApiConstants.forgotPassword,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.forgotPassword),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.forgotPassword),
          statusCode: 404,
        ),
      ));

      await expectLater(
        () =>
            container.read(authProvider.notifier).forgotPassword('a@b.com'),
        throwsA(isA<DioException>()),
      );

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.hasError, true);
      expect(state.error, contains('Network error'));
    });
  });

  // ===========================================================================
  // updatePassword
  // ===========================================================================

  group('updatePassword', () {
    test('state is loading during call', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(() => mockApiClient.post(
            ApiConstants.updatePassword,
            body: any(named: 'body'),
          )).thenAnswer((_) => completer.future);

      final future =
          container.read(authProvider.notifier).updatePassword('newPass1!');

      expect(container.read(authProvider).status, AuthStatus.loading);

      completer.completeError(Exception('cleanup'));
      await expectLater(future, throwsA(isA<Exception>()));
    });

    test('success transitions to authenticated', () async {
      // Set an initial authenticated state so the "stays authenticated" is visible
      container.read(authProvider.notifier).state = const AuthState(
        status: AuthStatus.authenticated,
        role: 'trainer',
      );

      when(() => mockApiClient.post(
            ApiConstants.updatePassword,
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.updatePassword),
            statusCode: 200,
            data: {'data': {'message': 'Password updated.'}},
          ));

      await container
          .read(authProvider.notifier)
          .updatePassword('newPass1!');

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.error, isNull);
    });

    test('error sets error state and rethrows (stays authenticated)', () async {
      container.read(authProvider.notifier).state = const AuthState(
        status: AuthStatus.authenticated,
        role: 'client',
      );

      when(() => mockApiClient.post(
            ApiConstants.updatePassword,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.updatePassword),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.updatePassword),
          statusCode: 500,
        ),
      ));

      await expectLater(
        () => container
            .read(authProvider.notifier)
            .updatePassword('newPass1!'),
        throwsA(isA<DioException>()),
      );

      final state = container.read(authProvider);
      // Stays authenticated even on error
      expect(state.status, AuthStatus.authenticated);
      expect(state.hasError, true);
    });
  });

  // ===========================================================================
  // completeOnboarding
  // ===========================================================================

  group('completeOnboarding', () {
    test('success sets hasCompletedOnboarding to true', () async {
      when(() => mockApiClient.post(
            '/auth/complete-onboarding',
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions:
                RequestOptions(path: '/auth/complete-onboarding'),
            statusCode: 200,
            data: {'data': {'message': 'Onboarding complete.'}},
          ));

      await container.read(authProvider.notifier).completeOnboarding();

      final state = container.read(authProvider);
      expect(state.hasCompletedOnboarding, true);
    });

    test('error sets error state and rethrows', () async {
      // Set initial state to have hasCompletedOnboarding=false
      container.read(authProvider.notifier).state = const AuthState(
        status: AuthStatus.authenticated,
        hasCompletedOnboarding: false,
      );

      when(() => mockApiClient.post(
            '/auth/complete-onboarding',
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: '/auth/complete-onboarding'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions:
              RequestOptions(path: '/auth/complete-onboarding'),
          statusCode: 500,
        ),
      ));

      await expectLater(
        () =>
            container.read(authProvider.notifier).completeOnboarding(),
        throwsA(isA<DioException>()),
      );

      final state = container.read(authProvider);
      expect(state.hasCompletedOnboarding, false); // unchanged
      expect(state.hasError, true);
    });

    test('error does not change hasCompletedOnboarding when it was true',
        () async {
      container.read(authProvider.notifier).state = const AuthState(
        status: AuthStatus.authenticated,
        hasCompletedOnboarding: true,
      );

      when(() => mockApiClient.post(
            '/auth/complete-onboarding',
            body: any(named: 'body'),
          )).thenThrow(Exception('Unexpected error'));

      await expectLater(
        () =>
            container.read(authProvider.notifier).completeOnboarding(),
        throwsA(isA<Exception>()),
      );

      final state = container.read(authProvider);
      // hasCompletedOnboarding should remain whatever it was before (true)
      expect(state.hasCompletedOnboarding, true);
      expect(state.hasError, true);
      expect(state.error, 'Exception: Unexpected error');
    });
  });

  // ===========================================================================
  // fetchMe
  // ===========================================================================

  group('fetchMe', () {
    test('returns data from nested response (data.data exists)', () async {
      when(() => mockApiClient.get(
            ApiConstants.me,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.me),
            statusCode: 200,
            data: {
              'data': {
                'id': 'user-1',
                'email': 'user@test.com',
                'role': 'trainer',
              },
            },
          ));

      final result =
          await container.read(authProvider.notifier).fetchMe();

      expect(result, isA<Map<String, dynamic>>());
      expect(result['id'], 'user-1');
      expect(result['email'], 'user@test.com');
      expect(result['role'], 'trainer');
    });

    test('returns data from flat response (data is the payload directly)',
        () async {
      when(() => mockApiClient.get(
            ApiConstants.me,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.me),
            statusCode: 200,
            data: {
              'id': 'user-flat',
              'email': 'flat@test.com',
              'role': 'client',
            },
          ));

      final result =
          await container.read(authProvider.notifier).fetchMe();

      expect(result, isA<Map<String, dynamic>>());
      expect(result['id'], 'user-flat');
      expect(result['email'], 'flat@test.com');
      expect(result['role'], 'client');
    });
  });

  // ===========================================================================
  // _extractErrorMessage – tested indirectly via public methods above
  //   All DioException types, structured errors, plain messages, unknown types,
  //   and generic Exception are covered in the login/register/refresh tests.
  // ===========================================================================
}
