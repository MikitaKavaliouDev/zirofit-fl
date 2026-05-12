import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';
import 'package:zirofit_fl/features/settings/screens/custom_app_mode_screen.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakePreferencesNotifier extends PreferencesNotifier {
  PreferencesState _s;

  int customModeCallCount = 0;

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
  Future<void> setCustomModeEnabled(bool enabled) async {
    customModeCallCount++;
    emit(_s.copyWith(isCustomModeEnabled: enabled));
  }
}

Widget buildApp(PreferencesState state) => ProviderScope(
      overrides: [
        preferencesProvider.overrideWith(
          (ref) => FakePreferencesNotifier(state),
        ),
      ],
      child: const MaterialApp(home: CustomAppModeScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CustomAppModeScreen', () {
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

      expect(find.text('Custom App Mode'), findsOneWidget);
    });

    testWidgets('renders section header and info card', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(find.text('App Mode'), findsOneWidget);
      expect(
        find.textContaining(
            'you can manually switch between Personal'),
        findsOneWidget,
      );
    });

    testWidgets('renders mode toggle', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Enable manual Personal/Professional switching'),
        findsOneWidget,
      );
      // Switch should exist
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('toggle shows correct initial state', (tester) async {
      await tester.pumpWidget(
        buildApp(
            const PreferencesState(isCustomModeEnabled: true)),
      );
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('tapping toggle calls setCustomModeEnabled',
        (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(isCustomModeEnabled: false),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: CustomAppModeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(notifier.customModeCallCount, equals(1));
    });

    testWidgets('shows error banner when error is set', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(
          error: 'Failed to save preference',
        )),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to save preference'),
        findsOneWidget,
      );
    });

    testWidgets('error banner dismiss icon is present', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(
          error: 'Some error',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsWidgets);
    });
  });
}
