import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/auth/screens/delete_account_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake AuthNotifier for rendering tests
// ---------------------------------------------------------------------------

class FakeAuthNotifier extends AuthNotifier {
  bool deleteAccountCalled = false;
  String? deleteAccountReason;
  bool shouldThrow = false;

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
  Future<void> deleteAccount({String? reason}) async {
    deleteAccountCalled = true;
    deleteAccountReason = reason;
    if (shouldThrow) {
      throw Exception('Failed to delete account');
    }
    // Simulate successful deletion: clear state
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('Renders confirmation screen with all key elements',
      (tester) async {
    await tester.pumpApp(
      const DeleteAccountScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Warning icon
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    // Title
    expect(find.text('Are you sure?'), findsOneWidget);
    // Warning message
    expect(
      find.textContaining('This action is permanent and cannot be undone.'),
      findsOneWidget,
    );
    // Reason dropdown
    expect(find.widgetWithText(DropdownButtonFormField<String>, 'Reason (optional)'),
        findsOneWidget);
    // Confirmation text field
    expect(find.widgetWithText(TextFormField, 'Type "DELETE" to confirm'),
        findsOneWidget);
    // Delete button
    expect(
        find.widgetWithText(ElevatedButton, 'Permanently Delete Account'),
        findsOneWidget);
    // Cancel button
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Can select reason from dropdown', (tester) async {
    await tester.pumpApp(
      const DeleteAccountScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Open the dropdown
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Reason (optional)'));
    await tester.pumpAndSettle();

    // Verify dropdown items are shown
    expect(find.text('Too expensive'), findsWidgets);
    expect(find.text('Not using enough'), findsWidgets);
    expect(find.text('Privacy concerns'), findsWidgets);
    expect(find.text('Other'), findsWidgets);

    // Select "Privacy concerns"
    await tester.tap(find.text('Privacy concerns').last);
    await tester.pumpAndSettle();

    // Verify selection
    expect(find.text('Privacy concerns'), findsWidgets);
  });

  testWidgets('Confirm button is disabled until DELETE is typed', (tester) async {
    await tester.pumpApp(
      const DeleteAccountScreen(),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    final deleteButton = find.widgetWithText(ElevatedButton, 'Permanently Delete Account');

    // Initially disabled
    expect(tester.widget<ElevatedButton>(deleteButton).onPressed, isNull);

    // Type something other than DELETE
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Type "DELETE" to confirm'),
      'something',
    );
    await tester.pumpAndSettle();

    // Still disabled
    expect(tester.widget<ElevatedButton>(deleteButton).onPressed, isNull);

    // Clear and type DELETE
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Type "DELETE" to confirm'),
      'DELETE',
    );
    await tester.pumpAndSettle();

    // Now enabled
    expect(tester.widget<ElevatedButton>(deleteButton).onPressed, isNotNull);
  });

  testWidgets('Calls API with reason on confirm', (tester) async {
    final fakeNotifier = FakeAuthNotifier();

    await tester.pumpApp(
      const DeleteAccountScreen(),
      overrides: [
        authProvider.overrideWith((ref) => fakeNotifier),
      ],
    );
    await tester.pumpAndSettle();

    // Select reason
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Reason (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy concerns').last);
    await tester.pumpAndSettle();

    // Type DELETE
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Type "DELETE" to confirm'),
      'DELETE',
    );
    await tester.pumpAndSettle();

    // Tap delete button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Permanently Delete Account'));
    await tester.pumpAndSettle();

    // Verify API was called with correct reason
    expect(fakeNotifier.deleteAccountCalled, isTrue);
    expect(fakeNotifier.deleteAccountReason, 'Privacy concerns');
  });

  testWidgets('Clears tokens and signs out on success', (tester) async {
    final fakeNotifier = FakeAuthNotifier();

    await tester.pumpApp(
      const DeleteAccountScreen(),
      overrides: [
        authProvider.overrideWith((ref) => fakeNotifier),
      ],
    );
    await tester.pumpAndSettle();

    // Type DELETE
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Type "DELETE" to confirm'),
      'DELETE',
    );
    await tester.pumpAndSettle();

    // Tap delete button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Permanently Delete Account'));
    await tester.pumpAndSettle();

    // Verify state is unauthenticated after success
    final authState = fakeNotifier.state;
    expect(authState.status, AuthStatus.unauthenticated);
    expect(authState.user, isNull);
  });

  testWidgets('Shows error snackbar on API failure', (tester) async {
    final fakeNotifier = FakeAuthNotifier();
    fakeNotifier.shouldThrow = true;

    await tester.pumpApp(
      const DeleteAccountScreen(),
      overrides: [
        authProvider.overrideWith((ref) => fakeNotifier),
      ],
    );
    await tester.pumpAndSettle();

    // Type DELETE
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Type "DELETE" to confirm'),
      'DELETE',
    );
    await tester.pumpAndSettle();

    // Tap delete button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Permanently Delete Account'));
    await tester.pumpAndSettle();

    // Verify error snackbar is shown
    expect(find.text('Exception: Failed to delete account'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
