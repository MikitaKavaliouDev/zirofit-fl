import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/onboarding/providers/onboarding_provider.dart';
import 'package:zirofit_fl/features/onboarding/screens/onboarding_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake OnboardingNotifier for rendering / interaction tests
// ---------------------------------------------------------------------------

class FakeOnboardingNotifier extends OnboardingNotifier {
  FakeOnboardingNotifier()
      : super(
          apiClient: ApiClient.instance,
          onComplete: () async {},
        );

  /// Capture whether submit was called.
  bool submitCalled = false;

  @override
  Future<void> submit() async {
    submitCalled = true;
    // Do not hit the real API.
  }
}

/// A variant that throws when submit is called.
class _ThrowingOnboardingNotifier extends OnboardingNotifier {
  _ThrowingOnboardingNotifier()
      : super(
          apiClient: ApiClient.instance,
          onComplete: () async {},
        );

  @override
  Future<void> submit() async {
    state = state.copyWith(
      isLoading: false,
      error: 'Submission failed',
    );
    throw Exception('Submission failed');
  }
}

// ---------------------------------------------------------------------------
// Test GoRouter for navigation test
// ---------------------------------------------------------------------------

GoRouter _testGoRouter(Widget Function(BuildContext, GoRouterState) builder) {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: builder,
      ),
      GoRoute(
        path: '/trainer/dashboard',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Trainer Dashboard')),
        ),
      ),
      GoRoute(
        path: '/client/dashboard',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Client Dashboard')),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  // ===========================================================================
  // Step 1 – Role Selection
  // ===========================================================================

  testWidgets('Step 1 renders role selection cards', (tester) async {
    await tester.pumpApp(
      const OnboardingScreen(),
      overrides: [
        onboardingProvider.overrideWith((ref) => FakeOnboardingNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Title
    expect(find.text('Welcome to Ziro Fit'), findsOneWidget);
    expect(find.text('Tell us about yourself to get started'), findsOneWidget);

    // Two role cards
    expect(find.text("I'm a Trainer"), findsOneWidget);
    expect(find.text("I'm a Client"), findsOneWidget);

    // Continue button visible
    expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
  });

  testWidgets('Step 1 selecting a role shows it as active', (tester) async {
    await tester.pumpApp(
      const OnboardingScreen(),
      overrides: [
        onboardingProvider.overrideWith((ref) => FakeOnboardingNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Tap the Trainer card
    await tester.tap(find.text("I'm a Trainer"));
    await tester.pumpAndSettle();

    // A check icon should appear indicating selection
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // Now tap the Client card
    await tester.tap(find.text("I'm a Client"));
    await tester.pumpAndSettle();

    // Still exactly one check icon (the active one)
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets("Can't proceed without selecting a role", (tester) async {
    await tester.pumpApp(
      const OnboardingScreen(),
      overrides: [
        onboardingProvider.overrideWith((ref) => FakeOnboardingNotifier()),
      ],
    );
    await tester.pumpAndSettle();

    // Tap Continue without selecting a role
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // SnackBar with error message should appear
    expect(find.text('Please select a role to continue'), findsOneWidget);

    // We should still be on step 1
    expect(find.text('Welcome to Ziro Fit'), findsOneWidget);
  });

  // ===========================================================================
  // Step 2 – Profile Setup
  // ===========================================================================

  testWidgets('Step 2 renders avatar, name, bio', (tester) async {
    final notifier = FakeOnboardingNotifier();
    // Set role so we can proceed to step 2
    notifier.setRole('client');
    notifier.nextStep();

    await tester.pumpApp(
      const OnboardingScreen(),
      overrides: [
        onboardingProvider.overrideWith((ref) => notifier),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Set Up Your Profile'), findsOneWidget);
    expect(find.text('Add a photo and your name'), findsOneWidget);

    // Avatar circle with camera icon
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

    // Name field
    expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);

    // Bio field
    expect(find.widgetWithText(TextFormField, 'Bio (optional)'), findsOneWidget);
  });

  testWidgets('Step 2 validates name is required', (tester) async {
    final notifier = FakeOnboardingNotifier();
    notifier.setRole('client');
    notifier.nextStep();

    await tester.pumpApp(
      const OnboardingScreen(),
      overrides: [
        onboardingProvider.overrideWith((ref) => notifier),
      ],
    );
    await tester.pumpAndSettle();

    // Leave name empty and tap Continue
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // Validation error
    expect(find.text('Please enter your name'), findsOneWidget);
  });

  // ===========================================================================
  // Step 3 – Physical Stats
  // ===========================================================================

  testWidgets('Step 3 renders height, weight, experience', (tester) async {
    final notifier = FakeOnboardingNotifier();
    notifier.setRole('client');
    notifier.nextStep();
    notifier.nextStep();

    await tester.pumpApp(
      const OnboardingScreen(),
      overrides: [
        onboardingProvider.overrideWith((ref) => notifier),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Your Physical Stats'), findsOneWidget);
    expect(
      find.text('Help us personalize your experience'),
      findsOneWidget,
    );

    // Height field
    expect(find.widgetWithText(TextFormField, 'Height (cm)'), findsOneWidget);
    // Weight field
    expect(find.widgetWithText(TextFormField, 'Weight (kg)'), findsOneWidget);
    // Experience dropdown
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Experience Level'), findsOneWidget);

    // Button label changes to "Get Started"
    expect(find.widgetWithText(ElevatedButton, 'Get Started'), findsOneWidget);
  });

  testWidgets('Step 3 validates height and weight', (tester) async {
    final notifier = FakeOnboardingNotifier();
    notifier.setRole('client');
    notifier.nextStep();
    notifier.nextStep();

    await tester.pumpApp(
      const OnboardingScreen(),
      overrides: [
        onboardingProvider.overrideWith((ref) => notifier),
      ],
    );
    await tester.pumpAndSettle();

    // Leave fields empty and tap Get Started
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your height'), findsOneWidget);
    expect(find.text('Please enter your weight'), findsOneWidget);
  });

  // ===========================================================================
  // Full flow
  // ===========================================================================

  testWidgets('Full flow: select role → fill profile → fill stats → submit',
      (tester) async {
    final notifier = FakeOnboardingNotifier();

    await tester.pumpApp(
      const OnboardingScreen(),
      overrides: [
        onboardingProvider.overrideWith((ref) => notifier),
      ],
    );
    await tester.pumpAndSettle();

    // --- Step 1: Select role ---
    await tester.tap(find.text("I'm a Trainer"));
    await tester.pumpAndSettle();

    expect(notifier.state.role, 'trainer');
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // Continue
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // --- Step 2: Fill profile ---
    expect(find.text('Set Up Your Profile'), findsOneWidget);

    // Enter name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full Name'),
      'John Doe',
    );
    // Enter bio
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bio (optional)'),
      'Fitness enthusiast',
    );

    // Continue
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // --- Step 3: Fill stats ---
    expect(find.text('Your Physical Stats'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Height (cm)'),
      '180',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Weight (kg)'),
      '75',
    );

    // Change experience level dropdown
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced').last);
    await tester.pumpAndSettle();

    // Get Started
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pumpAndSettle();

    // Submit should have been called and no error
    expect(notifier.submitCalled, isTrue);
    expect(notifier.state.error, isNull);
  });

  // ===========================================================================
  // Back button
  // ===========================================================================

  testWidgets('Back button returns to previous step', (tester) async {
    final notifier = FakeOnboardingNotifier();
    notifier.setRole('client');
    notifier.nextStep();

    await tester.pumpApp(
      const OnboardingScreen(),
      overrides: [
        onboardingProvider.overrideWith((ref) => notifier),
      ],
    );
    await tester.pumpAndSettle();

    // We should be on step 2
    expect(find.text('Set Up Your Profile'), findsOneWidget);

    // Tap back arrow
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Back on step 1
    expect(find.text('Welcome to Ziro Fit'), findsOneWidget);
    expect(find.text("I'm a Trainer"), findsOneWidget);

    // No back arrow on step 1
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  // ===========================================================================
  // Submit and navigate
  // ===========================================================================

  testWidgets('Submits via provider and navigates on success',
      (tester) async {
    final notifier = FakeOnboardingNotifier();

    // Build with GoRouter so that context.go() works.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp.router(
          title: 'Ziro Fit Test',
          routerConfig: _testGoRouter(
            (_, __) => const OnboardingScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // --- Step 1: Select role (trainer) ---
    await tester.tap(find.text("I'm a Trainer"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // --- Step 2: Fill profile ---
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full Name'),
      'Jane Doe',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // --- Step 3: Fill stats and submit ---
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Height (cm)'),
      '165',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Weight (kg)'),
      '60',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pumpAndSettle();

    // Submit should have been called
    expect(notifier.submitCalled, isTrue);

    // Should have navigated to trainer dashboard (since we selected trainer)
    expect(find.text('Trainer Dashboard'), findsOneWidget);
  });

  testWidgets('Shows error on submit failure', (tester) async {
    final notifier = _ThrowingOnboardingNotifier();
    notifier.state = notifier.state.copyWith(role: 'client');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp.router(
          title: 'Ziro Fit Test',
          routerConfig: _testGoRouter(
            (_, __) => const OnboardingScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: select role and continue
    await tester.tap(find.text("I'm a Client"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // Step 2: fill name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full Name'),
      'Jane Doe',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    // Step 3: fill stats and submit
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Height (cm)'),
      '165',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Weight (kg)'),
      '60',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pumpAndSettle();

    // Should show error message in the error banner
    expect(find.text('Submission failed'), findsOneWidget);
  });
}
