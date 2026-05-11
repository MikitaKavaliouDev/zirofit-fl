import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/features/dashboard/widgets/dashboard_prompt_card.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DashboardPromptCard', () {
    testWidgets('renders with title text', (tester) async {
      const prompt = DashboardPrompt(
        id: 'prompt-1',
        type: DashboardPromptType.newClient,
        title: 'New client assigned',
        actionLabel: 'View',
      );

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DashboardPromptCard(prompt: prompt),
        ),
      ));
      await tester.pump();

      expect(find.text('New client assigned'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
    });

    testWidgets('action button fires callback', (tester) async {
      bool called = false;

      final prompt = DashboardPrompt(
        id: 'prompt-2',
        type: DashboardPromptType.overdueCheckin,
        title: 'Overdue check-in',
        actionLabel: 'Take Action',
        onAction: () => called = true,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DashboardPromptCard(prompt: prompt),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Take Action'));
      await tester.pump();
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('dismiss button hides the card', (tester) async {
      const prompt = DashboardPrompt(
        id: 'prompt-3',
        type: DashboardPromptType.upcomingSession,
        title: 'Upcoming session reminder',
        actionLabel: 'Review',
      );

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DashboardPromptCard(prompt: prompt),
        ),
      ));
      await tester.pump();

      // Card should initially be visible
      expect(find.text('Upcoming session reminder'), findsOneWidget);

      // Tap the dismiss (X) button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump();

      // Card should now be dismissed
      expect(find.text('Upcoming session reminder'), findsNothing);
    });
  });
}
