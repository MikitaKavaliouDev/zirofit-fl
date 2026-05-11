import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/email_verification_provider.dart';
import 'package:zirofit_fl/features/auth/screens/email_verification_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for rendering tests
// ---------------------------------------------------------------------------

class FakeEmailVerificationNotifier extends EmailVerificationNotifier {
  FakeEmailVerificationNotifier() : super(apiClient: ApiClient.instance);

  @override
  void startPolling() {
    // Override to prevent actual API polling in widget tests.
    state = state.copyWith(isPolling: true);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('EmailVerificationScreen', () {
    testWidgets('shows the provided email address', (tester) async {
      await tester.pumpApp(
        const EmailVerificationScreen(email: 'user@ziro.fit'),
        overrides: [
          emailVerificationProvider.overrideWith(
            (ref) => FakeEmailVerificationNotifier(),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // The email should be displayed on screen
      expect(find.text('user@ziro.fit'), findsOneWidget);
    });

    testWidgets('shows "Check your email" heading', (tester) async {
      await tester.pumpApp(
        const EmailVerificationScreen(email: 'test@test.com'),
        overrides: [
          emailVerificationProvider.overrideWith(
            (ref) => FakeEmailVerificationNotifier(),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Check your email'), findsOneWidget);
    });

    testWidgets('shows loading indicator while polling', (tester) async {
      final notifier = FakeEmailVerificationNotifier();
      // Simulate polling state
      notifier.state = const EmailVerificationState(isPolling: true);

      await tester.pumpApp(
        const EmailVerificationScreen(email: 'a@b.com'),
        overrides: [
          emailVerificationProvider.overrideWith((ref) => notifier),
        ],
      );
      await tester.pumpAndSettle();

      // The "Waiting for verification" label should be visible
      expect(find.text('Waiting for verification'), findsOneWidget);

      // The resend button should be enabled
      expect(
        find.widgetWithText(OutlinedButton, 'Resend email'),
        findsOneWidget,
      );
    });

    testWidgets('shows "still waiting" message after timeout', (tester) async {
      final notifier = FakeEmailVerificationNotifier();
      notifier.state = const EmailVerificationState(
        isPolling: false,
        hasTimedOut: true,
      );

      await tester.pumpApp(
        const EmailVerificationScreen(email: 'a@b.com'),
        overrides: [
          emailVerificationProvider.overrideWith((ref) => notifier),
        ],
      );
      await tester.pumpAndSettle();

      // Timeout message
      expect(
        find.textContaining('Still waiting?'),
        findsOneWidget,
      );

      // Resend button should still be available
      expect(
        find.widgetWithText(OutlinedButton, 'Resend email'),
        findsOneWidget,
      );
    });

    testWidgets('shows success message and auto-navigates on confirmation',
        (tester) async {
      // Use GoRouter so context.go() does not throw.
      final notifier = FakeEmailVerificationNotifier();
      notifier.state = const EmailVerificationState(
        isPolling: false,
        isConfirmed: true,
      );

      final router = GoRouter(
        initialLocation: '/email-verification',
        routes: [
          GoRoute(
            path: '/email-verification',
            builder: (_, _) =>
                const EmailVerificationScreen(email: 'a@b.com'),
          ),
          GoRoute(
            path: '/auth/login',
            builder: (_, _) => const Scaffold(
              body: Center(child: Text('Login Page')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emailVerificationProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // After building, the confirmed state triggers navigation to /auth/login
      await tester.pumpAndSettle();

      // Should now be on the login page
      expect(find.text('Login Page'), findsOneWidget);
    });
  });
}
