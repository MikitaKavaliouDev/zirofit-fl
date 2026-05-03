import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/ai_coach/providers/ai_coach_provider.dart';
import 'package:zirofit_fl/features/ai_coach/screens/ai_coach_screen.dart';
import '../../helpers/test_setup.dart';

class Fake extends AICoachNotifier {
  Fake(AICoachState initialState) : super(apiClient: ApiClient.instance) {
    super.state = initialState;
  }

  @override
  Future<void> generateProgram(String goal) async {}

  @override
  Future<void> refineProgram(String userInput) async {}

  @override
  void clearError() {}

  @override
  void reset() {
    state = const AICoachState();
  }
}

/// Creates a [ProviderScope] that overrides [aiCoachProvider] with a [Fake]
/// initialized to [state].
Widget buildTestWidget(AICoachState state) {
  return ProviderScope(
    overrides: [
      aiCoachProvider.overrideWith((ref) => Fake(state)),
    ],
    child: const MaterialApp(
      home: AiCoachScreen(),
    ),
  );
}



void main() {
  setUpAll(() => configureTestApiClient());

  group('AiCoachScreen', () {
    // ---------------------------------------------------------------------------
    // Initial state – goal input form
    // ---------------------------------------------------------------------------
    testWidgets('renders goal input form when no program generated', (t) async {
      await t.pumpWidget(buildTestWidget(const AICoachState()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      expect(find.text("What's your fitness goal?"), findsOneWidget);
      expect(find.text('Generate Program'), findsOneWidget);
      expect(find.text('Start Over'), findsNothing);
    });

    // ---------------------------------------------------------------------------
    // Loading state on generate
    // ---------------------------------------------------------------------------
    testWidgets('shows loading indicator when generating', (t) async {
      await t.pumpWidget(buildTestWidget(
        const AICoachState(isLoading: true),
      ));
      await t.pump();

      // In the goal-input phase, the button shows a small circular indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // Generated program displayed
    // ---------------------------------------------------------------------------
    testWidgets('shows generated program and refine input when program exists',
        (t) async {
      await t.pumpWidget(buildTestWidget(
        const AICoachState(
          generatedProgram: 'Here is your custom program!',
          goal: 'Build muscle',
          conversation: ['Here is your custom program!'],
        ),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      expect(find.text('Here is your custom program!'), findsOneWidget);
      expect(find.text('Refine your program'), findsOneWidget);
      expect(find.text('Refine Program'), findsOneWidget);
      expect(find.text('Start Over'), findsOneWidget);
      expect(find.text("What's your fitness goal?"), findsNothing);
    });

    // ---------------------------------------------------------------------------
    // Loading indicator during refine
    // ---------------------------------------------------------------------------
    testWidgets('shows loading spinner during refine', (t) async {
      await t.pumpWidget(buildTestWidget(
        const AICoachState(
          isLoading: true,
          generatedProgram: 'Some program',
          goal: 'Build muscle',
          conversation: ['Some program'],
        ),
      ));
      await t.pump();

      // Two CircularProgressIndicators: one in the body, none in the button
      // The refine section shows a centered CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // Error display
    // ---------------------------------------------------------------------------
    testWidgets('shows error text when error is set', (t) async {
      const errorMsg = 'Something went wrong';
      await t.pumpWidget(buildTestWidget(
        const AICoachState(error: errorMsg),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      expect(find.text(errorMsg), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // Start Over button is visible in results view
    // ---------------------------------------------------------------------------
    testWidgets('start over button appears when program is generated', (t) async {
      await t.pumpWidget(buildTestWidget(
        const AICoachState(
          generatedProgram: 'Some program',
          goal: 'Build muscle',
          conversation: ['Some program'],
        ),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      expect(find.text('Start Over'), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // Goal input hidden when program is generated
    // ---------------------------------------------------------------------------
    testWidgets('goal form is hidden when program is displayed', (t) async {
      await t.pumpWidget(buildTestWidget(
        const AICoachState(
          generatedProgram: 'Some program',
          goal: 'Build muscle',
          conversation: ['Some program'],
        ),
      ));
      await t.pump(const Duration(milliseconds: 200));

      expect(find.text("What's your fitness goal?"), findsNothing);
      expect(find.text('Start Over'), findsOneWidget);
    });
  });
}
