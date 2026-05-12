import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';
import 'package:zirofit_fl/features/settings/screens/experimental_features_screen.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakePreferencesNotifier extends PreferencesNotifier {
  PreferencesState _s;

  int dailyTargetsCallCount = 0;
  int voiceFeedbackCallCount = 0;
  int routinesCallCount = 0;

  FakePreferencesNotifier(this._s) {
    super.state = _s;
  }

  @override
  PreferencesState get state => _s;

  void emit(PreferencesState s) {
    _s = s;
    super.state = s;
  }

  @override
  Future<void> loadPreferences() async {}

  @override
  Future<void> setDailyTargetsEnabled(bool enabled) async {
    dailyTargetsCallCount++;
    emit(_s.copyWith(isDailyTargetsEnabled: enabled));
  }

  @override
  Future<void> setVoiceFeedbackEnabled(bool enabled) async {
    voiceFeedbackCallCount++;
    emit(_s.copyWith(isVoiceFeedbackEnabled: enabled));
  }

  @override
  Future<void> setRoutinesEnabled(bool enabled) async {
    routinesCallCount++;
    emit(_s.copyWith(isRoutinesEnabled: enabled));
  }
}

Widget buildApp(PreferencesState state) => ProviderScope(
      overrides: [
        preferencesProvider.overrideWith(
          (ref) => FakePreferencesNotifier(state),
        ),
      ],
      child: const MaterialApp(home: ExperimentalFeaturesScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExperimentalFeaturesScreen', () {
    testWidgets('shows loading spinner when isLoading', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders AppBar title', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Experimental Features'), findsOneWidget);
    });

    testWidgets('renders section header', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Experimental Features'), findsOneWidget);
    });

    testWidgets('renders info card', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
            'These features are still in development'),
        findsOneWidget,
      );
    });

    testWidgets('renders all three feature toggles', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Exercise Targets'), findsOneWidget);
      expect(
        find.text('Set and track daily exercise goals'),
        findsOneWidget,
      );
      expect(find.text('Voice Feedback (Beta)'), findsOneWidget);
      expect(
        find.text('Hear audio cues and feedback during workouts'),
        findsOneWidget,
      );
      expect(find.text('Personal Routines'), findsOneWidget);
      expect(
        find.text(
            'Create and follow customized workout routines'),
        findsOneWidget,
      );
    });

    testWidgets('toggles have correct initial values', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(
          isDailyTargetsEnabled: true,
          isVoiceFeedbackEnabled: false,
          isRoutinesEnabled: true,
        )),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));

      expect(tester.widget<Switch>(switches.at(0)).value, isTrue);
      expect(tester.widget<Switch>(switches.at(1)).value, isFalse);
      expect(tester.widget<Switch>(switches.at(2)).value, isTrue);
    });

    testWidgets('tapping Daily Exercise Targets calls setter',
        (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(isDailyTargetsEnabled: false),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
              home: ExperimentalFeaturesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(notifier.dailyTargetsCallCount, equals(1));
    });

    testWidgets('tapping Voice Feedback calls setter', (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(isVoiceFeedbackEnabled: false),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
              home: ExperimentalFeaturesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();

      expect(notifier.voiceFeedbackCallCount, equals(1));
    });

    testWidgets('tapping Personal Routines calls setter',
        (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(isRoutinesEnabled: false),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
              home: ExperimentalFeaturesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).at(2));
      await tester.pumpAndSettle();

      expect(notifier.routinesCallCount, equals(1));
    });

    testWidgets('shows error banner when error is set', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(
          error: 'Failed to load preferences',
        )),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to load preferences'),
        findsOneWidget,
      );
    });
  });
}
