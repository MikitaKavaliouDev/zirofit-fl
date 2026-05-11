import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/settings/providers/domain_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/domain_settings_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake DomainNotifier
// ---------------------------------------------------------------------------

class FakeDomainNotifier extends DomainNotifier {
  FakeDomainNotifier() : super(apiClient: ApiClient.instance);

  /// Replaces the current state entirely (used to set up test scenarios).
  void update(DomainState newState) => state = newState;

  @override
  Future<bool> addDomain(String domain) async {
    state = state.copyWith(domain: domain, isAdding: false);
    return true;
  }

  @override
  Future<bool> verifyDomain() async {
    state = state.copyWith(isVerified: true, isLoading: false);
    return true;
  }

  @override
  void reset() => state = const DomainState();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget buildScreen() => const DomainSettingsScreen();

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeDomainNotifier fakeNotifier;

  setUpAll(() => configureTestApiClient());

  setUp(() {
    fakeNotifier = FakeDomainNotifier();
  });

  Future<void> pumpScreen(WidgetTester tester) => tester.pumpApp(
        buildScreen(),
        overrides: [
          domainProvider.overrideWith((ref) => fakeNotifier),
        ],
      );

  group('DomainSettingsScreen', () {
    // -------------------------------------------------------------------------
    // 1. Initial state
    // -------------------------------------------------------------------------

    testWidgets('renders initial state correctly', (tester) async {
      await pumpScreen(tester);
      await tester.pump();

      // AppBar + info card both show "Custom Domain"
      expect(find.text('Custom Domain'), findsAtLeastNWidgets(1));

      // Form field is present
      expect(find.byType(TextFormField), findsOneWidget);

      // "Add Domain" button is visible (no domain yet)
      expect(find.widgetWithText(FilledButton, 'Add Domain'), findsOneWidget);

      // No current domain card when domain is null
      expect(find.text('Current Domain'), findsNothing);

      // No "Verify Domain" button when domain is null
      expect(find.text('Verify Domain'), findsNothing);

      // No error banner
      expect(find.byIcon(Icons.close), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 2. Domain input validation
    // -------------------------------------------------------------------------

    testWidgets('shows empty field validation error', (tester) async {
      await pumpScreen(tester);
      await tester.pump();

      // Tap Add Domain without typing anything
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please enter a domain'), findsOneWidget);
    });

    testWidgets('shows invalid domain validation error', (tester) async {
      await pumpScreen(tester);
      await tester.pump();

      // Enter a string that doesn't match the domain regex
      await tester.enterText(find.byType(TextFormField), 'not-a-domain');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please enter a valid domain'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 3. Adding a domain
    // -------------------------------------------------------------------------

    testWidgets('adds a valid domain and shows it', (tester) async {
      await pumpScreen(tester);
      await tester.pump();

      // Enter a valid domain
      await tester.enterText(find.byType(TextFormField), 'profile.example.com');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // Domain card appears
      expect(find.text('Current Domain'), findsOneWidget);
      // Text appears in both the form field and the card
      expect(find.text('profile.example.com'), findsAtLeastNWidgets(1));

      // Button now shows "Update Domain" (since domain is present)
      expect(find.widgetWithText(FilledButton, 'Update Domain'), findsOneWidget);

      // Verify Domain button appears
      expect(find.text('Verify Domain'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 4. Domain display
    // -------------------------------------------------------------------------

    testWidgets('shows domain card with domain name', (tester) async {
      fakeNotifier.update(const DomainState(
        domain: 'trainer.example.com',
        isVerified: false,
      ));
      await pumpScreen(tester);
      await tester.pump();

      expect(find.text('Current Domain'), findsOneWidget);
      expect(find.text('trainer.example.com'), findsOneWidget);
    });

    testWidgets('shows Update Domain button when domain exists', (tester) async {
      fakeNotifier.update(const DomainState(
        domain: 'example.com',
        isVerified: false,
      ));
      await pumpScreen(tester);
      await tester.pump();

      expect(
        find.widgetWithText(FilledButton, 'Update Domain'),
        findsOneWidget,
      );
      expect(find.text('Add Domain'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 5. Verification badge
    // -------------------------------------------------------------------------

    testWidgets('shows Pending badge when domain is not verified',
        (tester) async {
      fakeNotifier.update(const DomainState(
        domain: 'example.com',
        isVerified: false,
      ));
      await pumpScreen(tester);
      await tester.pump();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Verified'), findsNothing);
    });

    testWidgets('shows Verified badge when domain is verified', (tester) async {
      fakeNotifier.update(const DomainState(
        domain: 'example.com',
        isVerified: true,
      ));
      await pumpScreen(tester);
      await tester.pump();

      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Pending'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 6. Verify Domain button
    // -------------------------------------------------------------------------

    testWidgets('shows Verify Domain button when domain exists',
        (tester) async {
      fakeNotifier.update(const DomainState(domain: 'example.com'));
      await pumpScreen(tester);
      await tester.pump();

      expect(
        find.widgetWithText(OutlinedButton, 'Verify Domain'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Verify Domain updates verification status',
        (tester) async {
      fakeNotifier.update(const DomainState(
        domain: 'example.com',
        isVerified: false,
      ));
      await pumpScreen(tester);
      await tester.pump();

      // Tap "Verify Domain" button
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      // Should now show "Verified" badge instead of "Pending"
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Pending'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 7. Error display
    // -------------------------------------------------------------------------

    testWidgets('shows error banner with dismiss button', (tester) async {
      const errorMsg = 'Failed to add domain. Please try again.';
      fakeNotifier.update(const DomainState(error: errorMsg));
      await pumpScreen(tester);
      await tester.pump();

      // Error message is visible
      expect(find.text(errorMsg), findsOneWidget);

      // Error icon is shown
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Dismiss button is visible
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('dismisses error banner when close button is tapped',
        (tester) async {
      const errorMsg = 'Some error occurred';
      fakeNotifier.update(const DomainState(error: errorMsg));
      await pumpScreen(tester);
      await tester.pump();

      // Verify error is shown
      expect(find.text(errorMsg), findsOneWidget);

      // Tap dismiss (close) button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Error banner should be gone (notifier was reset)
      expect(find.text(errorMsg), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 8. Loading state
    // -------------------------------------------------------------------------

    testWidgets('shows spinner and disables Add Domain button when isAdding',
        (tester) async {
      fakeNotifier.update(const DomainState(isAdding: true));
      await pumpScreen(tester);
      await tester.pump();

      // Spinner is shown inside the filled button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Filled button is disabled
      final filledButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(filledButton.onPressed, isNull);
    });

    testWidgets(
        'shows spinner and disables Verify button when isLoading',
        (tester) async {
      fakeNotifier.update(const DomainState(
        domain: 'example.com',
        isLoading: true,
      ));
      await pumpScreen(tester);
      await tester.pump();

      // Spinner is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify button shows "Verifying..." text
      expect(find.text('Verifying...'), findsOneWidget);

      // Outlined button (Verify) is disabled
      final outlinedButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(outlinedButton.onPressed, isNull);
    });
  });
}
