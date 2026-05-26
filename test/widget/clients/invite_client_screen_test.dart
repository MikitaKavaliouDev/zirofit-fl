import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/clients/providers/client_invite_provider.dart';
import 'package:zirofit_fl/features/clients/screens/invite_client_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeClientInviteNotifier extends ClientInviteNotifier {
  final ClientInviteState _overriddenState;
  bool checkEmailResult = false;

  FakeClientInviteNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  ClientInviteState get state => _overriddenState;

  void emit(ClientInviteState newState) {
    state = newState;
  }

  @override
  Future<bool> checkEmail(String email) async => checkEmailResult;

  @override
  Future<void> invite({
    String? email,
    required String name,
    String? phone,
    String? message,
  }) async {
    // No-op in tests; state is controlled manually
  }

  @override
  Future<void> linkExisting(String email) async {
    // No-op in tests
  }

  @override
  void reset() {
    emit(const ClientInviteState());
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget buildTestApp(ClientInviteState state) {
  return ProviderScope(
    overrides: [
      clientInviteProvider.overrideWith(
        (ref) => FakeClientInviteNotifier(state),
      ),
    ],
    child: const MaterialApp(
      home: InviteClientScreen(),
    ),
  );
}

Widget buildTestAppWithNotifier(FakeClientInviteNotifier notifier) {
  return ProviderScope(
    overrides: [
      clientInviteProvider.overrideWith((ref) => notifier),
    ],
    child: const MaterialApp(
      home: InviteClientScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('InviteClientScreen', () {
    // -----------------------------------------------------------------------
    // Test 1: Shows email + name + message fields
    // -----------------------------------------------------------------------
    testWidgets('shows name, email, phone, and message fields', (tester) async {
      await tester.pumpWidget(buildTestApp(const ClientInviteState()));
      await tester.pump();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Personal message (optional)'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('Send Invitation'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 2: Validates email format
    // -----------------------------------------------------------------------
    testWidgets('validates email format - button enabled only for valid email', (tester) async {
      await tester.pumpWidget(buildTestApp(const ClientInviteState()));
      await tester.pump();

      // Enter a name
      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');

      // Name entered but no email → button disabled
      var button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Send Invitation'),
      );
      expect(button.onPressed, isNull);

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).at(1), 'not-an-email');
      await tester.pump();

      // Still disabled
      button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Send Invitation'),
      );
      expect(button.onPressed, isNull);

      // Enter valid email
      await tester.enterText(find.byType(TextFormField).at(1), 'john@test.com');
      await tester.pump();

      // Now enabled
      button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Send Invitation'),
      );
      expect(button.onPressed, isNotNull);
    });

    // -----------------------------------------------------------------------
    // Test 3: Send button disabled for invalid form
    // -----------------------------------------------------------------------
    testWidgets('send button disabled when name is empty', (tester) async {
      await tester.pumpWidget(buildTestApp(const ClientInviteState()));
      await tester.pump();

      // Only enter email, leave name empty
      await tester.enterText(find.byType(TextFormField).at(1), 'test@test.com');

      // Send button should be disabled (no onPressed)
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Send Invitation'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('send button disabled when email is empty', (tester) async {
      await tester.pumpWidget(buildTestApp(const ClientInviteState()));
      await tester.pump();

      // Only enter name, leave email empty
      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');

      // Send button should be disabled
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Send Invitation'),
      );
      expect(button.onPressed, isNull);
    });

    // -----------------------------------------------------------------------
    // Test 4: Phone field enables button when email is empty
    // -----------------------------------------------------------------------
    testWidgets('phone field enables button when email is empty', (tester) async {
      await tester.pumpWidget(buildTestApp(const ClientInviteState()));
      await tester.pump();

      // Enter name only
      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.pump();

      // Button still disabled (no email, no phone)
      var button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Send Invitation'),
      );
      expect(button.onPressed, isNull);

      // Enter phone
      await tester.enterText(find.byType(TextFormField).at(2), '+1 555-1234');
      await tester.pump();

      // Now enabled (name + phone, no email needed)
      button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Send Invitation'),
      );
      expect(button.onPressed, isNotNull);
    });

    // -----------------------------------------------------------------------
    // Test 5: User-exists shows link option alert
    // -----------------------------------------------------------------------
    testWidgets('user exists shows link option alert', (tester) async {
      final notifier = FakeClientInviteNotifier(
        const ClientInviteState(emailExists: true),
      );
      notifier.checkEmailResult = true;

      await tester.pumpWidget(buildTestAppWithNotifier(notifier));
      await tester.pump();

      // Fill valid form
      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), 'john@test.com');
      await tester.pump();

      // Tap send
      await tester.tap(find.text('Send Invitation'));
      // Let async chain complete and dialog render
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should show the user-exists alert dialog
      expect(find.text('User Already Exists'), findsOneWidget);
      expect(
        find.text(
          'This email is already registered on Ziro Fit. '
          'Would you like to send a connection request instead?',
        ),
        findsOneWidget,
      );
      expect(find.text('Send Link Request'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 6: Error shows error state
    // -----------------------------------------------------------------------
    testWidgets('error shows error message', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const ClientInviteState(error: 'Something went wrong'),
      ));
      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}
