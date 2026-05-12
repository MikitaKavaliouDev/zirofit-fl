import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';
import 'package:zirofit_fl/features/settings/screens/language_settings_screen.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakePreferencesNotifier extends PreferencesNotifier {
  PreferencesState _s;

  int setLanguageCallCount = 0;
  String? lastLanguage;

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
  Future<void> setLanguage(String language) async {
    setLanguageCallCount++;
    lastLanguage = language;
    emit(_s.copyWith(language: language));
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
      child: const MaterialApp(home: LanguageSettingsScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LanguageSettingsScreen', () {
    testWidgets('renders AppBar title', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('renders all available languages', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.text('French'), findsOneWidget);
      expect(find.text('German'), findsOneWidget);
      expect(find.text('Portuguese'), findsOneWidget);
      expect(find.text('Italian'), findsOneWidget);
      expect(find.text('Japanese'), findsOneWidget);
      expect(find.text('Chinese'), findsOneWidget);
    });

    testWidgets('shows checkmark on currently selected language',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(language: 'es')),
      );
      await tester.pumpAndSettle();

      // Spanish should show the checkmark icon
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Find Spanish tile text
      final spanishTile = find.text('Spanish');
      expect(spanishTile, findsOneWidget);
    });

    testWidgets('shows only one checkmark when English is selected',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(language: 'en')),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('tapping a language calls setLanguage', (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(language: 'en'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: LanguageSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Spanish
      await tester.tap(find.text('Spanish'));
      await tester.pumpAndSettle();

      expect(notifier.setLanguageCallCount, equals(1));
      expect(notifier.lastLanguage, equals('es'));
    });

    testWidgets('tapping French calls setLanguage with fr',
        (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(language: 'en'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: LanguageSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('French'));
      await tester.pumpAndSettle();

      expect(notifier.lastLanguage, equals('fr'));
    });

    testWidgets('shows hint text at bottom', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Changing the language will update the app interface text.'),
        findsOneWidget,
      );
    });

    testWidgets('checkmark moves when selection changes', (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(language: 'en'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: LanguageSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Initially English is selected
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Tap German
      await tester.tap(find.text('German'));
      await tester.pumpAndSettle();

      // Still one checkmark, but now on German
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(notifier.lastLanguage, equals('de'));
    });
  });
}
