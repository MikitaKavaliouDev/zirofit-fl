import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/auth/screens/update_password_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake AuthNotifier for rendering tests
// ---------------------------------------------------------------------------

class FakeAuthNotifier extends AuthNotifier {
  bool updatePasswordCalled = false;
  String? updatePasswordArg;

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
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> updatePassword(String password) async {
    updatePasswordCalled = true;
    updatePasswordArg = password;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('Renders all form fields', (tester) async {
    await tester.pumpApp(
      const UpdatePasswordScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Check for 3 TextFormField widgets
    expect(find.byType(TextFormField), findsNWidgets(3));
    // Check for specific labels
    expect(find.widgetWithText(TextFormField, 'Current Password'),
        findsOneWidget);
    expect(
        find.widgetWithText(TextFormField, 'New Password'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Confirm New Password'),
        findsOneWidget);
    // Check for update button
    expect(find.widgetWithText(ElevatedButton, 'Update Password'),
        findsOneWidget);
  });

  testWidgets('Validates empty fields', (tester) async {
    await tester.pumpApp(
      const UpdatePasswordScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Tap submit with empty form
    final updateButton =
        find.widgetWithText(ElevatedButton, 'Update Password');
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    // Expect validation error messages
    expect(find.text('Please enter your current password'), findsOneWidget);
    expect(find.text('Please enter a new password'), findsOneWidget);
    expect(find.text('Please confirm your new password'), findsOneWidget);
  });

  testWidgets('Validates password mismatch', (tester) async {
    await tester.pumpApp(
      const UpdatePasswordScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Enter different passwords in new and confirm fields
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'currentPass123');
    await tester.enterText(fields.at(1), 'newPass1234');
    await tester.enterText(fields.at(2), 'differentPass456');
    await tester.pumpAndSettle();

    // Tap submit
    final updateButton =
        find.widgetWithText(ElevatedButton, 'Update Password');
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    // Expect password mismatch error
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('Validates minimum length', (tester) async {
    await tester.pumpApp(
      const UpdatePasswordScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Enter short passwords
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'currentPass123');
    await tester.enterText(fields.at(1), 'abc');
    await tester.enterText(fields.at(2), 'abc');
    await tester.pumpAndSettle();

    // Tap submit
    final updateButton =
        find.widgetWithText(ElevatedButton, 'Update Password');
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    // Expect min length error
    expect(find.text('At least 8 characters'), findsOneWidget);
  });

  testWidgets('Successful submission', (tester) async {
    final fakeNotifier = FakeAuthNotifier();

    await tester.pumpApp(
      const UpdatePasswordScreen(),
      overrides: [
        authProvider.overrideWith((ref) => fakeNotifier),
      ],
    );
    await tester.pumpAndSettle();

    // Enter valid passwords
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'currentPass123');
    await tester.enterText(fields.at(1), 'newPass1234');
    await tester.enterText(fields.at(2), 'newPass1234');
    await tester.pumpAndSettle();

    // Tap submit
    final updateButton =
        find.widgetWithText(ElevatedButton, 'Update Password');
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    // Verify authProvider.notifier.updatePassword was called
    expect(fakeNotifier.updatePasswordCalled, isTrue);
    expect(fakeNotifier.updatePasswordArg, 'newPass1234');

    // Verify success snackbar
    expect(find.text('Password updated successfully'), findsOneWidget);
  });
}
