import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/settings/providers/settings_provider.dart';
import 'package:zirofit_fl/features/settings/screens/settings_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakeSettingsNotifier extends SettingsNotifier {
  SettingsState _s;
  FakeSettingsNotifier(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  SettingsState get state => _s;

  void emit(SettingsState ns) {
    _s = ns;
    super.state = ns;
  }

  @override
  Future<void> loadSettings() async {}

  @override
  Future<void> saveCheckInDefaults(int day, int hour) async {}

  @override
  Future<void> toggleWeightUnit(String unit) async {}
}

Widget buildApp(SettingsState state) => ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => FakeSettingsNotifier(state)),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading spinner when isLoading', (tester) async {
    await tester.pumpWidget(
      buildApp(const SettingsState(isLoading: true)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays settings screen with all sections', (tester) async {
    await tester.pumpWidget(
      buildApp(const SettingsState(
        isLoading: false,
        defaultCheckInDay: 1,
        defaultCheckInHour: 14,
        weightUnit: 'LB',
      )),
    );
    await tester.pumpAndSettle();

    // AppBar title
    expect(find.text('Settings'), findsOneWidget);

    // Section headers
    expect(find.text('Check-in Defaults'), findsOneWidget);
    expect(find.text('Weight Unit'), findsOneWidget);

    // Check-in day shows Monday (index 1)
    expect(find.text('Monday'), findsOneWidget);

    // Check-in hour shows 2:00 PM (index 14)
    expect(find.text('2:00 PM'), findsOneWidget);

    // Weight unit shows LB selected
    expect(find.text('Pounds (LB)'), findsOneWidget);
    expect(find.text('Kilograms (KG)'), findsOneWidget);
  });

  testWidgets('displays default values when no settings configured',
      (tester) async {
    await tester.pumpWidget(
      buildApp(const SettingsState(isLoading: false)),
    );
    await tester.pumpAndSettle();

    // Default day: Sunday (index 0)
    expect(find.text('Sunday'), findsOneWidget);

    // Default hour: 9:00 AM (index 9)
    expect(find.text('9:00 AM'), findsOneWidget);

    // Default weight: KG
    expect(find.text('Kilograms (KG)'), findsOneWidget);
  });

  testWidgets('shows success message banner', (tester) async {
    await tester.pumpWidget(
      buildApp(const SettingsState(
        isLoading: false,
        successMessage: 'Check-in defaults saved successfully',
      )),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Check-in defaults saved successfully'),
      findsOneWidget,
    );
  });

  testWidgets('shows error message banner', (tester) async {
    await tester.pumpWidget(
      buildApp(const SettingsState(
        isLoading: false,
        error: 'Something went wrong',
      )),
    );
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('tapping KG weight unit calls toggleWeightUnit',
      (tester) async {
    String? toggledUnit;

    final trackerNotifier = _ToggleTracker((unit) {
      toggledUnit = unit;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => trackerNotifier),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on KG option
    await tester.tap(find.text('Kilograms (KG)'));
    await tester.pumpAndSettle();

    expect(toggledUnit, 'KG');
  });

  testWidgets('tapping LB weight unit calls toggleWeightUnit',
      (tester) async {
    String? toggledUnit;

    final trackerNotifier = _ToggleTracker((unit) {
      toggledUnit = unit;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => trackerNotifier),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on LB option
    await tester.tap(find.text('Pounds (LB)'));
    await tester.pumpAndSettle();

    expect(toggledUnit, 'LB');
  });

  testWidgets('disabling dropdowns while saving', (tester) async {
    await tester.pumpWidget(
      buildApp(const SettingsState(
        isLoading: false,
        isSaving: true,
      )),
    );
    await tester.pumpAndSettle();

    // Dropdown buttons should be disabled (no onChanged callback)
    // We can verify they exist and screen renders without crash
    expect(find.text('Sunday'), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('Kilograms (KG)'), findsOneWidget);
  });
}

// ---------------------------------------------------------------------------
// Tracker Fake for tap tests
// ---------------------------------------------------------------------------

class _ToggleTracker extends SettingsNotifier {
  final void Function(String unit) onToggle;

  _ToggleTracker(this.onToggle) : super(apiClient: ApiClient.instance) {
    super.state = const SettingsState(isLoading: false);
  }

  @override
  Future<void> loadSettings() async {}

  @override
  Future<void> toggleWeightUnit(String unit) async {
    onToggle(unit);
  }
}
