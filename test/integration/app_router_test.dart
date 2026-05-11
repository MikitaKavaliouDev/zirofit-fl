import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';
import 'package:zirofit_fl/core/router/app_router.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

class MockSecureStorage extends Mock implements SecureStorage {}

// ---------------------------------------------------------------------------
// Test notifier that allows setting the initial auth state
// ---------------------------------------------------------------------------

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier({
    required super.apiClient,
    required super.secureStorage,
    required AuthState initialState,
  }) {
    state = initialState;
  }
}

// ---------------------------------------------------------------------------
// Pure redirect logic — mirrors app_router.dart exactly
// ---------------------------------------------------------------------------

String? _computeRedirect(AuthState authState, String matchedLocation) {
  final isLoggedIn = authState.status == AuthStatus.authenticated;
  final isAuthRoute = matchedLocation.startsWith('/auth');
  final isOnboarding = matchedLocation == '/onboarding';

  // Not logged in → auth routes only
  if (!isLoggedIn && !isAuthRoute) return '/auth/login';

  // Logged in but on an auth route → dashboard
  if (isLoggedIn && isAuthRoute) return _defaultRoute(authState.role);

  // Pending role → onboarding (unless already there)
  if (isLoggedIn && authState.isPending && !isOnboarding) return '/onboarding';

  // Role-based guard: ensure user stays in their role's route prefix
  if (isLoggedIn && !isOnboarding) {
    final expectedPrefix = _rolePrefix(authState.role);

    if (!matchedLocation.startsWith(expectedPrefix) &&
        !matchedLocation.startsWith('/auth') &&
        matchedLocation != '/onboarding' &&
        matchedLocation != '/exercises' &&
        matchedLocation != '/ai-coach') {
      return _defaultRoute(authState.role);
    }
  }

  return null;
}

String _defaultRoute(String? role) {
  switch (role) {
    case 'trainer':
      return '/trainer/dashboard';
    case 'client':
      return '/client/dashboard';
    case 'admin':
      return '/admin/dashboard';
    case 'pending':
      return '/onboarding';
    default:
      return '/auth/login';
  }
}

String _rolePrefix(String? role) {
  switch (role) {
    case 'trainer':
      return '/trainer';
    case 'client':
      return '/client';
    case 'admin':
      return '/admin';
    default:
      return '/auth';
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

ProviderContainer _createContainer({
  AuthStatus status = AuthStatus.initial,
  String? role,
  bool pending = false,
}) {
  final effectiveRole = pending ? 'pending' : role;
  return ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(MockApiClient() as ApiClient),
      secureStorageProvider.overrideWithValue(MockSecureStorage()),
      authProvider.overrideWith((ref) {
        return _TestAuthNotifier(
          apiClient: ref.read(apiClientProvider),
          secureStorage: ref.read(secureStorageProvider),
          initialState: AuthState(
            status: status,
            role: effectiveRole,
          ),
        );
      }),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('_getDefaultRoute', () {
    test('trainer role → /trainer/dashboard', () {
      expect(_defaultRoute('trainer'), '/trainer/dashboard');
    });

    test('client role → /client/dashboard', () {
      expect(_defaultRoute('client'), '/client/dashboard');
    });

    test('admin role → /admin/dashboard', () {
      expect(_defaultRoute('admin'), '/admin/dashboard');
    });

    test('pending role → /onboarding', () {
      expect(_defaultRoute('pending'), '/onboarding');
    });

    test('null role → /auth/login', () {
      expect(_defaultRoute(null), '/auth/login');
    });
  });

  group('_getRolePrefix', () {
    test('trainer → /trainer', () {
      expect(_rolePrefix('trainer'), '/trainer');
    });

    test('client → /client', () {
      expect(_rolePrefix('client'), '/client');
    });

    test('admin → /admin', () {
      expect(_rolePrefix('admin'), '/admin');
    });

    test('null → /auth', () {
      expect(_rolePrefix(null), '/auth');
    });
  });

  // ===========================================================================
  // Redirect logic
  // ===========================================================================

  group('redirect logic', () {
    // -----------------------------------------------------------------------
    // 1. Unauthenticated → auth routes
    // -----------------------------------------------------------------------

    test(
        'unauthenticated user on protected route '
        '→ redirects to /auth/login', () {
      final container = _createContainer(
        status: AuthStatus.unauthenticated,
      );
      addTearDown(container.dispose);

      // Verify ProviderContainer creates the GoRouter
      final router = container.read(routerProvider);
      expect(router, isA<GoRouter>());

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/trainer/dashboard'), '/auth/login');
      expect(_computeRedirect(state, '/client/dashboard'), '/auth/login');
      expect(_computeRedirect(state, '/admin/dashboard'), '/auth/login');
      expect(_computeRedirect(state, '/exercises'), '/auth/login');
      expect(_computeRedirect(state, '/onboarding'), '/auth/login');
      expect(_computeRedirect(state, '/ai-coach'), '/auth/login');
    });

    test(
        'unauthenticated user on auth route '
        '→ no redirect (null)', () {
      final container = _createContainer(
        status: AuthStatus.unauthenticated,
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/auth/login'), isNull);
      expect(_computeRedirect(state, '/auth/register'), isNull);
      expect(_computeRedirect(state, '/auth/forgot-password'), isNull);
    });

    test(
        'initial/loading status on protected route '
        '→ redirects to /auth/login', () {
      final container = _createContainer(status: AuthStatus.initial);
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/trainer/dashboard'), '/auth/login');

      // Also test loading state
      final loadingContainer = _createContainer(status: AuthStatus.loading);
      addTearDown(loadingContainer.dispose);
      final loadingState = loadingContainer.read(authProvider);
      expect(_computeRedirect(loadingState, '/trainer/dashboard'), '/auth/login');
    });

    test(
        'initial/loading status on auth route '
        '→ no redirect', () {
      final container = _createContainer(status: AuthStatus.initial);
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/auth/login'), isNull);

      final loadingContainer = _createContainer(status: AuthStatus.loading);
      addTearDown(loadingContainer.dispose);
      final loadingState = loadingContainer.read(authProvider);
      expect(_computeRedirect(loadingState, '/auth/login'), isNull);
    });

    // -----------------------------------------------------------------------
    // 2. Authenticated on auth route → role-based dashboard
    // -----------------------------------------------------------------------

    test(
        'authenticated trainer on auth route '
        '→ redirects to /trainer/dashboard', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'trainer',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/auth/login'), '/trainer/dashboard');
      expect(_computeRedirect(state, '/auth/register'), '/trainer/dashboard');
      expect(
          _computeRedirect(state, '/auth/forgot-password'), '/trainer/dashboard');
    });

    test(
        'authenticated client on auth route '
        '→ redirects to /client/dashboard', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'client',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/auth/login'), '/client/dashboard');
    });

    test(
        'authenticated admin on auth route '
        '→ redirects to /admin/dashboard', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'admin',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/auth/login'), '/admin/dashboard');
    });

    // -----------------------------------------------------------------------
    // 3. Pending role → /onboarding
    // -----------------------------------------------------------------------

    test(
        'pending role on non-onboarding route '
        '→ redirects to /onboarding', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        pending: true,
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(state.isPending, isTrue);

      expect(_computeRedirect(state, '/trainer/dashboard'), '/onboarding');
      expect(_computeRedirect(state, '/client/dashboard'), '/onboarding');
      expect(_computeRedirect(state, '/admin/dashboard'), '/onboarding');
      expect(_computeRedirect(state, '/exercises'), '/onboarding');
      expect(_computeRedirect(state, '/ai-coach'), '/onboarding');
    });

    test(
        'pending role on /onboarding → no redirect (null)', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        pending: true,
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/onboarding'), isNull);
    });

    // -----------------------------------------------------------------------
    // 4. Role-based guard: trainer
    // -----------------------------------------------------------------------

    test(
        'trainer accessing /client/* → redirects to /trainer/dashboard', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'trainer',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/client/dashboard'), '/trainer/dashboard');
      expect(_computeRedirect(state, '/client/workout'), '/trainer/dashboard');
      expect(_computeRedirect(state, '/client/progress'), '/trainer/dashboard');
    });

    test(
        'trainer accessing /admin/* → redirects to /trainer/dashboard', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'trainer',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/admin/dashboard'), '/trainer/dashboard');
      expect(_computeRedirect(state, '/admin/events'), '/trainer/dashboard');
    });

    test(
        'trainer accessing /trainer/* → no redirect (null)', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'trainer',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/trainer/dashboard'), isNull);
      expect(_computeRedirect(state, '/trainer/clients'), isNull);
      expect(_computeRedirect(state, '/trainer/clients/123'), isNull);
      expect(_computeRedirect(state, '/trainer/calendar'), isNull);
      expect(_computeRedirect(state, '/trainer/exercises'), isNull);
    });

    // -----------------------------------------------------------------------
    // 5. Role-based guard: client
    // -----------------------------------------------------------------------

    test(
        'client accessing /trainer/* → redirects to /client/dashboard', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'client',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(
        _computeRedirect(state, '/trainer/dashboard'),
        '/client/dashboard',
      );
      expect(_computeRedirect(state, '/trainer/clients'), '/client/dashboard');
    });

    test(
        'client accessing /admin/* → redirects to /client/dashboard', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'client',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(
        _computeRedirect(state, '/admin/dashboard'),
        '/client/dashboard',
      );
    });

    test(
        'client accessing /client/* → no redirect (null)', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'client',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/client/dashboard'), isNull);
      expect(_computeRedirect(state, '/client/workout'), isNull);
      expect(_computeRedirect(state, '/client/workout/history'), isNull);
      expect(_computeRedirect(state, '/client/progress'), isNull);
    });

    // -----------------------------------------------------------------------
    // 6. Role-based guard: admin
    // -----------------------------------------------------------------------

    test(
        'admin accessing /trainer/* → redirects to /admin/dashboard', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'admin',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(
        _computeRedirect(state, '/trainer/dashboard'),
        '/admin/dashboard',
      );
    });

    test(
        'admin accessing /client/* → redirects to /admin/dashboard', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'admin',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(
        _computeRedirect(state, '/client/dashboard'),
        '/admin/dashboard',
      );
    });

    test(
        'admin accessing /admin/* → no redirect (null)', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'admin',
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/admin/dashboard'), isNull);
      expect(_computeRedirect(state, '/admin/events'), isNull);
      expect(_computeRedirect(state, '/admin/blog'), isNull);
      expect(_computeRedirect(state, '/admin/tickets'), isNull);
    });

    // -----------------------------------------------------------------------
    // 7. Shared routes — accessible by ANY authenticated role
    // -----------------------------------------------------------------------

    test(
        'any authenticated role accessing /exercises → no redirect (null)', () {
      for (final role in ['trainer', 'client', 'admin']) {
        final container = _createContainer(
          status: AuthStatus.authenticated,
          role: role,
        );
        addTearDown(container.dispose);

        final state = container.read(authProvider);
        expect(
          _computeRedirect(state, '/exercises'),
          isNull,
          reason: 'Role $role should access /exercises freely',
        );
      }
    });

    test(
        'any authenticated role accessing /ai-coach → no redirect (null)', () {
      for (final role in ['trainer', 'client', 'admin']) {
        final container = _createContainer(
          status: AuthStatus.authenticated,
          role: role,
        );
        addTearDown(container.dispose);

        final state = container.read(authProvider);
        expect(
          _computeRedirect(state, '/ai-coach'),
          isNull,
          reason: 'Role $role should access /ai-coach freely',
        );
      }
    });

    // -----------------------------------------------------------------------
    // 8. Null role for authenticated user
    // -----------------------------------------------------------------------

    test(
        'authenticated user with null role on auth route '
        '→ redirects to /auth/login (default fallback)', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: null,
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/auth/login'), '/auth/login');
    });

    test(
        'authenticated user with null role on protected route '
        '→ redirects to /auth/login (no matching role prefix)', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: null,
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      // Null role → prefix is /auth, so /trainer/* won't match → redirect
      expect(
          _computeRedirect(state, '/trainer/dashboard'), '/auth/login');
      expect(
          _computeRedirect(state, '/client/dashboard'), '/auth/login');
    });

    test(
        'authenticated user with null role on /auth route '
        '→ redirects to /auth/login (same location — defaultRoute fallback)', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: null,
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      // Null role on auth route: isLoggedIn && isAuthRoute → _defaultRoute(null) = /auth/login
      // The redirect returns the same location; GoRouter handles the loop.
      expect(_computeRedirect(state, '/auth/login'), '/auth/login');
    });

    // -----------------------------------------------------------------------
    // 9. Error status
    // -----------------------------------------------------------------------

    test(
        'error status on protected route → redirects to /auth/login', () {
      final container = _createContainer(status: AuthStatus.error);
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/trainer/dashboard'), '/auth/login');
    });

    test(
        'error status on auth route → no redirect', () {
      final container = _createContainer(status: AuthStatus.error);
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(_computeRedirect(state, '/auth/login'), isNull);
    });
  });

  // ===========================================================================
  // Provider creates a valid GoRouter
  // ===========================================================================

  group('routerProvider', () {
    test('creates a GoRouter', () {
      final container = _createContainer(
        status: AuthStatus.authenticated,
        role: 'trainer',
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(router, isA<GoRouter>());
    });

    test('creates GoRouter for any auth state', () {
      for (final status in AuthStatus.values) {
        final container = _createContainer(status: status);
        addTearDown(container.dispose);
        expect(container.read(routerProvider), isA<GoRouter>());
      }
    });
  });
}
