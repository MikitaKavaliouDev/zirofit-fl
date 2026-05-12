import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';
import 'package:zirofit_fl/features/settings/screens/privacy_security_settings_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _state;

  FakeAuthNotifier(this._state)
      : super(
          apiClient: ApiClient.instance,
          secureStorage: FakeSecureStorage(),
        ) {
    super.state = _state;
  }

  @override
  AuthState get state => _state;
}

class FakePreferencesNotifier extends PreferencesNotifier {
  PreferencesState _s;

  int sharingDurationCallCount = 0;
  String? lastSharingDuration;

  FakePreferencesNotifier(this._s) {
    super.state = _s;
  }

  @override
  PreferencesState get state => _s;

  void emit(PreferencesState s) {
    _s = s;
    super.state = s;
  }

  @override
  Future<void> loadPreferences() async {}

  @override
  Future<void> setSharingDuration(String duration) async {
    sharingDurationCallCount++;
    lastSharingDuration = duration;
    emit(_s.copyWith(sharingDuration: duration));
  }
}

// ---------------------------------------------------------------------------
// Build helpers
// ---------------------------------------------------------------------------

Widget buildApp({
  required AuthState authState,
  required PreferencesState prefsState,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => FakeAuthNotifier(authState),
      ),
      preferencesProvider.overrideWith(
        (ref) => FakePreferencesNotifier(prefsState),
      ),
    ],
    child: const MaterialApp(home: PrivacySecuritySettingsScreen()),
  );
}

Widget buildAppWithRouter({
  required FakeAuthNotifier authNotifier,
  required FakePreferencesNotifier prefsNotifier,
}) {
  final router = GoRouter(
    initialLocation: '/settings/privacy-security',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const SizedBox(),
        routes: [
          GoRoute(
            path: 'settings/privacy-security',
            builder: (_, _) =>
                const PrivacySecuritySettingsScreen(),
          ),
          GoRoute(
            path: 'settings/data-sharing',
            builder: (_, _) =>
                const _DataSharingPlaceholder(),
          ),
          GoRoute(
            path: 'delete-account',
            builder: (_, _) => const _DeleteAccountPlaceholder(),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => authNotifier),
      preferencesProvider.overrideWith((ref) => prefsNotifier),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Placeholder screen to verify navigation to data sharing.
class _DataSharingPlaceholder extends StatelessWidget {
  const _DataSharingPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Data Sharing Screen')),
    );
  }
}

/// Placeholder screen to verify navigation to delete account.
class _DeleteAccountPlaceholder extends StatelessWidget {
  const _DeleteAccountPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Delete Account Screen')),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('PrivacySecuritySettingsScreen', () {
    testWidgets('renders AppBar title', (tester) async {
      await tester.pumpWidget(
        buildApp(
          authState: const AuthState(role: 'trainer'),
          prefsState: const PreferencesState(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Security'), findsOneWidget);
    });

    testWidgets('renders Data Access Control section', (tester) async {
      await tester.pumpWidget(
        buildApp(
          authState: const AuthState(role: 'trainer'),
          prefsState: const PreferencesState(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Access Control'), findsOneWidget);
      expect(
        find.text('Manage Sharing Categories'),
        findsOneWidget,
      );
      expect(
        find.text(
            'Workouts, measurements, photos, and check-ins'),
        findsOneWidget,
      );
    });

    testWidgets('renders Data Sharing Duration section',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          authState: const AuthState(role: 'trainer'),
          prefsState: const PreferencesState(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Sharing Duration'), findsOneWidget);
      expect(find.text('Sharing Period'), findsOneWidget);
    });

    testWidgets('shows sharing duration description', (tester) async {
      await tester.pumpWidget(
        buildApp(
          authState: const AuthState(role: 'trainer'),
          prefsState:
              const PreferencesState(sharingDuration: '30_days'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Your trainer can access your data for 30 days'),
        findsOneWidget,
      );
    });

    testWidgets('renders duration SegmentedButton options',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          authState: const AuthState(role: 'trainer'),
          prefsState: const PreferencesState(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('90 Days'), findsOneWidget);
      expect(find.text('Forever'), findsOneWidget);
    });

    testWidgets('tapping duration segment calls setSharingDuration',
        (tester) async {
      final prefsNotifier = FakePreferencesNotifier(
        const PreferencesState(sharingDuration: 'forever'),
      );

      await tester.pumpWidget(
        buildAppWithRouter(
          authNotifier: FakeAuthNotifier(
            const AuthState(role: 'trainer'),
          ),
          prefsNotifier: prefsNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Tap "30 Days" segment
      await tester.tap(find.text('30 Days'));
      await tester.pumpAndSettle();

      expect(prefsNotifier.sharingDurationCallCount, equals(1));
      expect(prefsNotifier.lastSharingDuration, equals('30_days'));
    });

    testWidgets('shows Trainer Connection section for client',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          authState: const AuthState(role: 'client'),
          prefsState: const PreferencesState(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trainer Connection'), findsOneWidget);
      expect(
        find.text('Manage your connection with your trainer.'),
        findsOneWidget,
      );
    });

    testWidgets('does NOT show Trainer Connection for trainer',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          authState: const AuthState(role: 'trainer'),
          prefsState: const PreferencesState(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trainer Connection'), findsNothing);
    });

    testWidgets('shows Security section with Delete Account',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          authState: const AuthState(role: 'trainer'),
          prefsState: const PreferencesState(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
      expect(
        find.text(
            'Permanently remove your account and all data'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Manage Sharing Categories navigates',
        (tester) async {
      final prefsNotifier = FakePreferencesNotifier(
        const PreferencesState(),
      );

      await tester.pumpWidget(
        buildAppWithRouter(
          authNotifier: FakeAuthNotifier(
            const AuthState(role: 'trainer'),
          ),
          prefsNotifier: prefsNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Manage Sharing Categories list tile
      await tester.tap(find.text('Manage Sharing Categories'));
      await tester.pumpAndSettle();

      // Should navigate to data-sharing screen
      expect(find.text('Data Sharing Screen'), findsOneWidget);
    });

    testWidgets('tapping Delete Account shows confirmation dialog',
        (tester) async {
      final prefsNotifier = FakePreferencesNotifier(
        const PreferencesState(),
      );

      await tester.pumpWidget(
        buildAppWithRouter(
          authNotifier: FakeAuthNotifier(
            const AuthState(role: 'trainer'),
          ),
          prefsNotifier: prefsNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal Delete Account
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Account'), findsAtLeast(1));
      expect(
        find.text(
            'This action is permanent and cannot be undone.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancelling Delete Account dialog does not navigate',
        (tester) async {
      final prefsNotifier = FakePreferencesNotifier(
        const PreferencesState(),
      );

      await tester.pumpWidget(
        buildAppWithRouter(
          authNotifier: FakeAuthNotifier(
            const AuthState(role: 'trainer'),
          ),
          prefsNotifier: prefsNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Tap Cancel in dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Still on privacy screen
      expect(find.text('Privacy & Security'), findsOneWidget);
    });

    testWidgets('confirming Delete Account navigates away',
        (tester) async {
      final prefsNotifier = FakePreferencesNotifier(
        const PreferencesState(),
      );

      await tester.pumpWidget(
        buildAppWithRouter(
          authNotifier: FakeAuthNotifier(
            const AuthState(role: 'trainer'),
          ),
          prefsNotifier: prefsNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Tap Delete in dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should navigate to delete-account screen
      expect(
        find.text('Delete Account Screen'),
        findsOneWidget,
      );
    });

    testWidgets('shows error banner when preferences has error',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          authState: const AuthState(role: 'trainer'),
          prefsState: const PreferencesState(
            error: 'Failed to load preferences',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to load preferences'),
        findsOneWidget,
      );
    });

    testWidgets('shows privacy footer text', (tester) async {
      await tester.pumpWidget(
        buildApp(
          authState: const AuthState(role: 'trainer'),
          prefsState: const PreferencesState(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
            'All data is encrypted in transit and at rest'),
        findsOneWidget,
      );
    });
  });
}
