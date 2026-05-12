import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';
import 'package:zirofit_fl/features/settings/screens/appearance_settings_screen.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakePreferencesNotifier extends PreferencesNotifier {
  PreferencesState _s;

  int setThemeModeCallCount = 0;
  String? lastThemeMode;

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
  Future<void> setThemeMode(String mode) async {
    setThemeModeCallCount++;
    lastThemeMode = mode;
    emit(_s.copyWith(themeMode: mode));
  }

  @override
  Future<void> loadPreferences() async {}
}

Widget buildApp(PreferencesState state) => ProviderScope(
      overrides: [
        preferencesProvider.overrideWith(
          (ref) => FakePreferencesNotifier(state),
        ),
      ],
      child: const MaterialApp(home: AppearanceSettingsScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AppearanceSettingsScreen', () {
    testWidgets('renders AppBar and section header', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('renders all three theme options', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // Descriptions
      expect(find.text('Light background with dark text'), findsOneWidget);
      expect(find.text('Dark background with light text'), findsOneWidget);
      expect(
        find.text('Follow your device theme settings'),
        findsOneWidget,
      );
    });

    testWidgets('renders info card', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Choose between Light, Dark, or System theme'),
        findsOneWidget,
      );
    });

    testWidgets('highlights Light option when themeMode is light',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(themeMode: 'light')),
      );
      await tester.pumpAndSettle();

      // Light should show a check icon (radio indicator)
      // We verify by checking the presence of Icons.check inside the card
      // The _ThemeOption widget shows a check icon when isSelected is true
      // Since we don't have direct access to private widgets, check for the
      // radio indicator via the check icon
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tapping Light calls setThemeMode with light',
        (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(themeMode: 'system'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: AppearanceSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(notifier.setThemeModeCallCount, equals(1));
      expect(notifier.lastThemeMode, equals('light'));
    });

    testWidgets('tapping Dark calls setThemeMode with dark',
        (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(themeMode: 'light'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: AppearanceSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(notifier.setThemeModeCallCount, equals(1));
      expect(notifier.lastThemeMode, equals('dark'));
    });

    testWidgets('tapping System calls setThemeMode with system',
        (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(themeMode: 'light'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: AppearanceSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();

      expect(notifier.setThemeModeCallCount, equals(1));
      expect(notifier.lastThemeMode, equals('system'));
    });

    testWidgets('shows check icon only for selected option', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(themeMode: 'dark')),
      );
      await tester.pumpAndSettle();

      // Only Dark should have the check icon
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
