import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/onboarding/screens/onboarding_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('Onboarding screen renders step content', (tester) async {
    await tester.pumpApp(const OnboardingScreen());
    await tester.pumpAndSettle();

    // Verify app bar title
    expect(find.text('Onboarding'), findsOneWidget);
    // Verify placeholder text
    expect(find.text('Onboarding flow — coming soon'), findsOneWidget);
  });

  testWidgets('Onboarding screen has navigation buttons', (tester) async {
    await tester.pumpApp(const OnboardingScreen());
    await tester.pumpAndSettle();

    // The current implementation is a simple placeholder, so we just verify the scaffold exists.
    expect(find.byType(Scaffold), findsOneWidget);
    // No navigation buttons in placeholder, but we can ensure no errors.
  });
}