import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/dashboard/widgets/client_shell.dart';
import '../../helpers/test_setup.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

class FakeAuth extends AuthNotifier {
  final AuthState _s;
  FakeAuth(this._s)
      : super(
          apiClient: ApiClient.instance,
          secureStorage: FakeSecureStorage(),
        ) {
    super.state = _s;
  }
  @override
  AuthState get state => _s;
}

/// A test route that records when it is visited.
class _TestRoute extends StatelessWidget {
  final String route;
  const _TestRoute({required this.route});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Route: $route')),
      body: Center(child: Text('Route: $route')),
    );
  }
}

GoRouter _createTestRouter() {
  return GoRouter(
    initialLocation: '/client/dashboard',
    routes: [
      ShellRoute(
        builder: (_, __, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: '/client/dashboard',
            builder: (_, __) => const _TestRoute(route: 'client/dashboard'),
          ),
          GoRoute(
            path: '/client/workout',
            builder: (_, __) => const _TestRoute(route: 'client/workout'),
          ),
          GoRoute(
            path: '/client/progress',
            builder: (_, __) => const _TestRoute(route: 'client/progress'),
          ),
          GoRoute(
            path: '/client/trainer',
            builder: (_, __) => const _TestRoute(route: 'client/trainer'),
          ),
          GoRoute(
            path: '/client/check-in',
            builder: (_, __) => const _TestRoute(route: 'client/check-in'),
          ),
          GoRoute(
            path: '/client/explore',
            builder: (_, __) => const _TestRoute(route: 'client/explore'),
          ),
        ],
      ),
      GoRoute(
        path: '/trainer/dashboard',
        builder: (_, __) => const _TestRoute(route: 'trainer/dashboard'),
      ),
    ],
  );
}

Widget buildTestWidget({required MockSecureStorage mockSecureStorage}) {
  final router = _createTestRouter();

  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(mockSecureStorage),
      authProvider.overrideWith((ref) => FakeAuth(
        const AuthState(
          status: AuthStatus.authenticated,
          user: User(id: '1', email: 'client@ziro.fit', name: 'Client'),
          role: 'client',
        ),
      )),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() {
    configureTestApiClient();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ClientShell', () {
    late MockSecureStorage mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockSecureStorage();
      when(() => mockSecureStorage.getAccessToken())
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.hasTokens())
          .thenAnswer((_) async => false);
      when(() => mockSecureStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      when(() => mockSecureStorage.clearTokens())
          .thenAnswer((_) async {});
    });

    testWidgets('mode switch button is visible', (t) async {
      await t.pumpWidget(
          buildTestWidget(mockSecureStorage: mockSecureStorage));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // The mode switch "Trainer" destination and the regular "Trainer" nav
      // item both have the same label; verify at least one NavigationDestination
      // with that label exists.
      expect(
        find.widgetWithText(NavigationDestination, 'Trainer'),
        findsWidgets,
      );
    });

    testWidgets('tapping mode switch button does not throw', (t) async {
      await t.pumpWidget(
          buildTestWidget(mockSecureStorage: mockSecureStorage));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // Tap the mode switch "Trainer" — it's the last NavigationDestination
      final trainers = find.widgetWithText(NavigationDestination, 'Trainer');
      await t.tap(trainers.last);
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await t.pump();
      await t.pump(const Duration(seconds: 1));

      // No crash means the button is wired up; mode switch logic is verified
      // in the provider unit tests
      expect(
        find.widgetWithText(NavigationDestination, 'Trainer'),
        findsWidgets,
      );
    });

    testWidgets('mode switch icon displays swap_horiz', (t) async {
      await t.pumpWidget(
          buildTestWidget(mockSecureStorage: mockSecureStorage));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    });

    testWidgets('normal nav destinations still work', (t) async {
      await t.pumpWidget(
          buildTestWidget(mockSecureStorage: mockSecureStorage));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      await t.tap(find.widgetWithText(NavigationDestination, 'Workout'));
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await t.pump();
      await t.pump(const Duration(seconds: 1));

      expect(
        find.textContaining('client/workout'),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
