import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Stand-alone redirect logic mirroring app_router.dart
// ---------------------------------------------------------------------------

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

/// Mirrors the redirect logic of [routerProvider] so we can test it without
/// requiring a widget tree.
String? _redirect(AuthState authState, String location) {
  final isLoggedIn = authState.status == AuthStatus.authenticated;
  final isAuthRoute = location.startsWith('/auth');
  final isOnboarding = location == '/onboarding';

  // Not logged in → auth routes only
  if (!isLoggedIn && !isAuthRoute) return '/auth/login';

  // Logged in but on an auth route → dashboard
  if (isLoggedIn && isAuthRoute) return _defaultRoute(authState.role);

  // Pending role → onboarding (unless already there)
  if (isLoggedIn && authState.isPending && !isOnboarding) {
    return '/onboarding';
  }

  // Role-based guard: ensure user stays in their role's route prefix
  if (isLoggedIn && !isOnboarding) {
    final expectedPrefix = _rolePrefix(authState.role);

    if (!location.startsWith(expectedPrefix) &&
        !location.startsWith('/auth') &&
        location != '/onboarding' &&
        location != '/exercises' &&
        location != '/ai-coach') {
      return _defaultRoute(authState.role);
    }
  }

  return null; // no redirect
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Navigation redirect logic', () {
    test('unauthenticated user redirected to /login', () {
      const auth = AuthState(status: AuthStatus.unauthenticated);

      // Accessing a protected route → redirect to login
      expect(_redirect(auth, '/trainer/dashboard'), '/auth/login');
      expect(_redirect(auth, '/client/dashboard'), '/auth/login');

      // Staying on auth route → no redirect
      expect(_redirect(auth, '/auth/login'), isNull);
      expect(_redirect(auth, '/auth/register'), isNull);
    });

    test('authenticated trainer sees trainer dashboard as default', () {
      const auth = AuthState(
        status: AuthStatus.authenticated,
        role: 'trainer',
        user: User(id: 'u-1', email: 'trainer@test.com'),
      );

      // On auth route → redirect to trainer dashboard
      expect(_redirect(auth, '/auth/login'), '/trainer/dashboard');

      // On trainer route → no redirect
      expect(_redirect(auth, '/trainer/dashboard'), isNull);
      expect(_redirect(auth, '/trainer/clients'), isNull);
      expect(_redirect(auth, '/trainer/calendar'), isNull);
    });

    test('authenticated client sees client dashboard as default', () {
      const auth = AuthState(
        status: AuthStatus.authenticated,
        role: 'client',
        user: User(id: 'u-2', email: 'client@test.com'),
      );

      expect(_redirect(auth, '/auth/login'), '/client/dashboard');
      expect(_redirect(auth, '/client/dashboard'), isNull);
      expect(_redirect(auth, '/client/workout'), isNull);
    });

    test('authenticated trainer trying to access client route is redirected', () {
      const auth = AuthState(
        status: AuthStatus.authenticated,
        role: 'trainer',
        user: User(id: 'u-1', email: 'trainer@test.com'),
      );

      expect(_redirect(auth, '/client/dashboard'), '/trainer/dashboard');
      expect(_redirect(auth, '/client/workout'), '/trainer/dashboard');
    });

    test('authenticated client trying to access trainer route is redirected', () {
      const auth = AuthState(
        status: AuthStatus.authenticated,
        role: 'client',
        user: User(id: 'u-2', email: 'client@test.com'),
      );

      expect(_redirect(auth, '/trainer/dashboard'), '/client/dashboard');
      expect(_redirect(auth, '/trainer/clients'), '/client/dashboard');
    });

    test('authenticated trainer can access shared routes', () {
      const auth = AuthState(
        status: AuthStatus.authenticated,
        role: 'trainer',
        user: User(id: 'u-1', email: 'trainer@test.com'),
      );

      expect(_redirect(auth, '/exercises'), isNull);
      expect(_redirect(auth, '/ai-coach'), isNull);
    });

    test('authenticated client can access shared routes', () {
      const auth = AuthState(
        status: AuthStatus.authenticated,
        role: 'client',
        user: User(id: 'u-2', email: 'client@test.com'),
      );

      expect(_redirect(auth, '/exercises'), isNull);
      expect(_redirect(auth, '/ai-coach'), isNull);
    });

    test('pending role redirected to onboarding', () {
      const auth = AuthState(
        status: AuthStatus.authenticated,
        role: 'pending',
        user: User(id: 'u-3', email: 'pending@test.com'),
      );

      // On any non-onboarding route → redirect to onboarding
      expect(_redirect(auth, '/trainer/dashboard'), '/onboarding');
      expect(_redirect(auth, '/client/dashboard'), '/onboarding');

      // Already on onboarding → no redirect
      expect(_redirect(auth, '/onboarding'), isNull);

      // On auth route → redirect to default (which is /onboarding for pending)
      expect(_redirect(auth, '/auth/login'), '/onboarding');
    });

    test('admin role has admin dashboard as default', () {
      const auth = AuthState(
        status: AuthStatus.authenticated,
        role: 'admin',
        user: User(id: 'u-4', email: 'admin@test.com'),
      );

      expect(_redirect(auth, '/auth/login'), '/admin/dashboard');
      expect(_redirect(auth, '/admin/dashboard'), isNull);
    });
  });
}
