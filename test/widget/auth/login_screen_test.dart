import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/auth/screens/login_screen.dart';
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
    // Do nothing, return a dummy user.
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

  testWidgets('Login screen renders form fields correctly', (tester) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Check for email field
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    // Check for password field
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    // Check for sign in button
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    // Check for forgot password link
    expect(find.text('Forgot Password?'), findsOneWidget);
    // Check for Google sign in button
    expect(find.widgetWithText(OutlinedButton, 'Sign in with Google'),
        findsOneWidget);
    // Check for Apple sign in button
    expect(find.widgetWithText(OutlinedButton, 'Sign in with Apple'),
        findsOneWidget);
    // Check for register link
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('Login screen shows validation errors for empty fields',
      (tester) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Tap sign in button without entering anything
    final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    // Expect validation error messages
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Login screen password field toggles visibility',
      (tester) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Find the password field
    final passwordField = find.widgetWithText(TextFormField, 'Password');
    expect(passwordField, findsOneWidget);

    // Find the visibility toggle icon button (suffix icon)
    final visibilityToggle = find.byIcon(Icons.visibility_off_outlined);
    expect(visibilityToggle, findsOneWidget);

    // Tap the toggle
    await tester.tap(visibilityToggle);
    await tester.pumpAndSettle();

    // Icon should change to visibility_outlined
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });
}