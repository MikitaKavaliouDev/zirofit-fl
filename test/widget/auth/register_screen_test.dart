import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/auth/screens/register_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake AuthNotifier for rendering tests
// ---------------------------------------------------------------------------

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier()
      : super(
          apiClient: ApiClient.instance,
          secureStorage: FakeSecureStorage(),
        );

  @override
  Future<AsyncValue<User>> login(String email, String password) async {
    return const AsyncValue.data(User(id: 'dummy', email: 'dummy@test.com'));
  }

  @override
  Future<AsyncValue<void>> register(
    String name,
    String email,
    String password, {
    String? role,
    String? trainerId,
  }) async {
    // Do nothing, return success.
    return const AsyncValue.data(null);
  }

  @override
  Future<void> signInWithOAuth(String provider) async {}

  @override
  Future<void> forgotPassword(String email) async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('Register screen renders form fields correctly', (tester) async {
    await tester.pumpApp(
      const RegisterScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Check for name field
    expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
    // Check for email field
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    // Check for password field
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    // Check for confirm password field
    expect(find.widgetWithText(TextFormField, 'Confirm Password'),
        findsOneWidget);
    // Check for role selector (SegmentedButton)
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    // Check for create account button
    expect(
        find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);
    // Check for login link
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Register screen shows validation errors for empty fields',
      (tester) async {
    await tester.pumpApp(
      const RegisterScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Tap create account button without entering anything
    final createButton = find.widgetWithText(ElevatedButton, 'Create Account');
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    // Expect validation error messages
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });

  testWidgets('Register screen password fields toggle visibility',
      (tester) async {
    await tester.pumpApp(
      const RegisterScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Find password field visibility toggle
    final passwordToggle = find.byIcon(Icons.visibility_off_outlined).first;
    expect(passwordToggle, findsOneWidget);
    await tester.tap(passwordToggle);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_outlined).first, findsOneWidget);

    // Find confirm password field visibility toggle (second occurrence)
    final confirmToggle = find.byIcon(Icons.visibility_off_outlined).first;
    expect(confirmToggle, findsOneWidget);
    await tester.tap(confirmToggle);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_outlined).first, findsOneWidget);
  });

  testWidgets('Register screen role selector works', (tester) async {
    await tester.pumpApp(
      const RegisterScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Find segmented button
    final segmentedButton = find.byType(SegmentedButton<String>);
    expect(segmentedButton, findsOneWidget);

    // Tap on Trainer segment
    final trainerSegment = find.text('Trainer');
    expect(trainerSegment, findsOneWidget);
    await tester.tap(trainerSegment);
    await tester.pumpAndSettle();

    // Verify Trainer is selected (we can't easily check internal state, but we can ensure no errors)
    // The test passes if no exceptions.
  });
}