import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_controls_bar.dart';

void main() {
  group('FloatingControlsBar', () {
    testWidgets('renders mic, pause, and finish buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FloatingControlsBar(
                onVoiceStart: () {},
                onVoiceEnd: () {},
                onFinish: () {},
              ),
            ),
          ),
        ),
      );

      // Mic button present — uses widgetPredicate because icon is inside AnimatedContainer
      expect(
        find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.mic),
        findsOneWidget,
      );
      // Pause button present (initial state is running)
      expect(
        find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.pause),
        findsOneWidget,
      );
      // Finish button present
      expect(
        find.widgetWithText(FilledButton, 'Finish'),
        findsOneWidget,
      );
    });

    testWidgets('calls onVoiceStart on long press start', (tester) async {
      bool voiceStarted = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FloatingControlsBar(
                onVoiceStart: () => voiceStarted = true,
                onVoiceEnd: () {},
                onFinish: () {},
              ),
            ),
          ),
        ),
      );

      final micIcon = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.mic,
      );
      await tester.longPress(micIcon);
      await tester.pumpAndSettle();

      expect(voiceStarted, isTrue);
    });

    testWidgets('calls onFinish when finish button tapped', (tester) async {
      bool finishPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FloatingControlsBar(
                onVoiceStart: () {},
                onVoiceEnd: () {},
                onFinish: () => finishPressed = true,
              ),
            ),
          ),
        ),
      );

      final finishButton = find.widgetWithText(FilledButton, 'Finish');
      await tester.tap(finishButton);
      await tester.pumpAndSettle();

      expect(finishPressed, isTrue);
    });
  });
}
