import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/secure_storage.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/dashboard/widgets/trainer_shell.dart';
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

/// A minimal child widget rendered inside the shell.
class _ShellChild extends StatelessWidget {
  final String label;
  const _ShellChild({required this.label});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text('Content: $label')),
    );
  }
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
    initialLocation: '/trainer/dashboard',
    routes: [
      ShellRoute(
        builder: (_, __, child) => TrainerShell(child: child),
        routes: [
          GoRoute(
            path: '/trainer/dashboard',
            builder: (_, __) => const _TestRoute(route: 'trainer/dashboard'),
          ),
          GoRoute(
            path: '/trainer/clients',
            builder: (_, __) => const _TestRoute(route: 'trainer/clients'),
          ),
          GoRoute(
            path: '/trainer/check-ins',
            builder: (_, __) => const _TestRoute(route: 'trainer/check-ins'),
          ),
          GoRoute(
            path: '/trainer/calendar',
            builder: (_, __) => const _TestRoute(route: 'trainer/calendar'),
          ),
          GoRoute(
            path: '/trainer/profile',
            builder: (_, __) => const _TestRoute(route: 'trainer/profile'),
          ),
          GoRoute(
            path: '/trainer/settings',
            builder: (_, __) => const _TestRoute(route: 'trainer/settings'),
          ),
        ],
      ),
      GoRoute(
        path: '/client/dashboard',
        builder: (_, __) => const _TestRoute(route: 'client/dashboard'),
      ),
    ],
  );
}

Widget buildTestWidget({
  required MockSecureStorage mockSecureStorage,
  ProviderContainer? container,
}) {
  final router = _createTestRouter();

  return ProviderScope(
    parent: container,
    overrides: [
      secureStorageProvider.overrideWithValue(mockSecureStorage),
      authProvider.overrideWith((ref) => FakeAuth(
        const AuthState(
          status: AuthStatus.authenticated,
          user: User(id: '1', email: 'trainer@ziro.fit', name: 'Coach'),
          role: 'trainer',
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

  group('TrainerShell', () {
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

      expect(
        find.widgetWithText(NavigationDestination, 'Personal'),
        findsOneWidget,
      );
    });

    testWidgets('tapping mode switch button does not throw', (t) async {
      await t.pumpWidget(
          buildTestWidget(mockSecureStorage: mockSecureStorage));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      await t.tap(
        find.widgetWithText(NavigationDestination, 'Personal'),
      );
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await t.pump();
      await t.pump(const Duration(seconds: 1));

      // No crash means the button is wired up; mode switch logic is verified
      // in the provider unit tests
      expect(
        find.widgetWithText(NavigationDestination, 'Personal'),
        findsOneWidget,
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

      await t.tap(find.widgetWithText(NavigationDestination, 'Clients'));
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await t.pump();
      await t.pump(const Duration(seconds: 1));

      expect(
        find.textContaining('trainer/clients'),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
