import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/settings/screens/getting_started_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake AuthNotifier for getting_started_screen
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

Widget buildApp(AuthState authState) => ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(authState),
        ),
      ],
      child: const MaterialApp(home: GettingStartedScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('GettingStartedScreen', () {
    testWidgets('renders AppBar title', (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'trainer')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Getting Started Guide'), findsOneWidget);
    });

    testWidgets('renders welcome header', (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'trainer')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Ziro Fit'), findsOneWidget);
    });

    testWidgets('shows Trainer Guide badge for trainer role',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'trainer')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trainer Guide'), findsOneWidget);
    });

    testWidgets('shows trainer steps for trainer role', (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'trainer')),
      );
      await tester.pumpAndSettle();

      // Trainer-specific steps
      expect(
        find.text('Set Up Your Trainer Profile'),
        findsOneWidget,
      );
      expect(
        find.text('Configure Your Services & Pricing'),
        findsOneWidget,
      );
      expect(find.text('Invite & Manage Clients'), findsOneWidget);
      expect(
        find.text('Create Workout Programs'),
        findsOneWidget,
      );
      expect(
        find.text('Track Client Progress'),
        findsOneWidget,
      );
    });

    testWidgets('shows client steps for client role', (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'client')),
      );
      await tester.pumpAndSettle();

      // Client-specific steps
      expect(
        find.text('Complete Your Profile'),
        findsOneWidget,
      );
      expect(
        find.text('Connect With Your Trainer'),
        findsOneWidget,
      );
      expect(find.text('Log Your Workouts'), findsOneWidget);
      expect(find.text('Track Daily Habits'), findsOneWidget);
      expect(
        find.text('Monitor Your Progress'),
        findsOneWidget,
      );
    });

    testWidgets('shows client guide badge for client role',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'client')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Client Guide'), findsOneWidget);
    });

    testWidgets('shows step progress indicator', (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'trainer')),
      );
      await tester.pumpAndSettle();

      // Progress text: "1 of 5 expanded" (first step auto-expands)
      expect(find.text('1 of 5 expanded'), findsOneWidget);
    });

    testWidgets('client can toggle to see trainer guide',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'client')),
      );
      await tester.pumpAndSettle();

      // For client role, the role toggle card is shown
      expect(find.text('Viewing as'), findsOneWidget);

      // Client Guide should be selected by default
      expect(find.text('Client Guide'), findsOneWidget);

      // Tap "Trainer Guide" toggle option
      await tester.tap(find.text('Trainer Guide'));
      await tester.pumpAndSettle();

      // Now trainer steps should be visible
      expect(
        find.text('Set Up Your Trainer Profile'),
        findsOneWidget,
      );
    });

    testWidgets('tapping a step card expands it', (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'trainer')),
      );
      await tester.pumpAndSettle();

      // First step is auto-expanded. Tap second step to expand it too
      await tester.tap(
        find.text('Configure Your Services & Pricing'),
      );
      await tester.pumpAndSettle();

      // Now 2 of 5 should be expanded
      expect(find.text('2 of 5 expanded'), findsOneWidget);
    });

    testWidgets('expanded step shows details', (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'trainer')),
      );
      await tester.pumpAndSettle();

      // First step is auto-expanded → details should be visible
      expect(
        find.textContaining('Upload a professional profile photo'),
        findsOneWidget,
      );
    });

    testWidgets('collapsing a step removes details', (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'trainer')),
      );
      await tester.pumpAndSettle();

      // First step is auto-expanded
      expect(find.text('1 of 5 expanded'), findsOneWidget);

      // Tap the first step header to collapse it
      await tester.tap(
        find.text('Set Up Your Trainer Profile'),
      );
      await tester.pumpAndSettle();

      // Now 0 of 5 expanded
      expect(find.text('0 of 5 expanded'), findsOneWidget);
    });

    testWidgets('shows tip in expanded step', (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'trainer')),
      );
      await tester.pumpAndSettle();

      // The tip for step 1 should be visible
      expect(
        find.textContaining(
            'Profiles with a photo and detailed bio receive 3x'),
        findsOneWidget,
      );
    });

    testWidgets('does not show role toggle for trainer role',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const AuthState(role: 'trainer')),
      );
      await tester.pumpAndSettle();

      // Trainers should NOT see the "Viewing as" toggle
      expect(find.text('Viewing as'), findsNothing);
    });
  });
}
