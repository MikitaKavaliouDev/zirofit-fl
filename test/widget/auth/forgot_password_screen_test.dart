import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/auth/screens/forgot_password_screen.dart';
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
    return const AsyncValue.data(null);
  }

  @override
  Future<void> signInWithOAuth(String provider) async {}

  @override
  Future<void> forgotPassword(String email) async {
    // Do nothing, simulate success.
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('Forgot password screen renders form fields correctly',
      (tester) async {
    await tester.pumpApp(
      const ForgotPasswordScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Check for email field
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    // Check for send reset link button
    expect(
        find.widgetWithText(ElevatedButton, 'Send Reset Link'), findsOneWidget);
    // Check for back to login link
    expect(find.text('Back to Login'), findsOneWidget);
    // Check for icon
    expect(find.byIcon(Icons.lock_reset_rounded), findsOneWidget);
    // Check for title text
    expect(find.text('Reset your password'), findsOneWidget);
  });

  testWidgets('Forgot password screen shows validation error for empty email',
      (tester) async {
    await tester.pumpApp(
      const ForgotPasswordScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Tap send reset link button without entering email
    final sendButton = find.widgetWithText(ElevatedButton, 'Send Reset Link');
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    // Expect validation error message
    expect(find.text('Please enter your email'), findsOneWidget);
  });

  testWidgets('Forgot password screen shows validation error for invalid email',
      (tester) async {
    await tester.pumpApp(
      const ForgotPasswordScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Enter invalid email
    final emailField = find.widgetWithText(TextFormField, 'Email');
    await tester.enterText(emailField, 'invalid');
    await tester.pumpAndSettle();

    // Tap send reset link button
    final sendButton = find.widgetWithText(ElevatedButton, 'Send Reset Link');
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    // Expect validation error message for invalid email
    expect(find.text('Please enter a valid email'), findsOneWidget);
  });
}