import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';
import 'package:zirofit_fl/features/admin/screens/admin_feature_toggles_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeAdminNotifier extends AdminNotifier {
  final AdminState _overriddenState;

  FakeAdminNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  AdminState get state => _overriddenState;

  @override
  Future<void> fetchFeatureToggles() async {}

  @override
  Future<void> updateFeatureToggle(String key, String value) async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading', (tester) async {
    await tester.pumpApp(
      const AdminFeatureTogglesScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(isLoading: true),
            )),
      ],
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no toggles', (tester) async {
    await tester.pumpApp(
      const AdminFeatureTogglesScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('No feature toggles'), findsOneWidget);
  });

  testWidgets('shows feature toggles when data loaded', (tester) async {
    await tester.pumpApp(
      const AdminFeatureTogglesScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(
                featureToggles: {
                  'freeAccessMode': false,
                  'customDomains': true,
                },
                isLoading: false,
              ),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('Free Access Mode'), findsOneWidget);
    expect(find.text('Custom Domains'), findsOneWidget);
  });

  testWidgets('toggles are in correct state', (tester) async {
    await tester.pumpApp(
      const AdminFeatureTogglesScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(
                featureToggles: {
                  'freeAccessMode': false,
                  'customDomains': true,
                },
                isLoading: false,
              ),
            )),
      ],
    );
    await tester.pump();

    // Find the switches
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));

    // First switch (freeAccessMode) should be off
    final firstSwitch = tester.widget<Switch>(switches.at(0));
    expect(firstSwitch.value, false);

    // Second switch (customDomains) should be on
    final secondSwitch = tester.widget<Switch>(switches.at(1));
    expect(secondSwitch.value, true);
  });

  testWidgets('shows error state', (tester) async {
    await tester.pumpApp(
      const AdminFeatureTogglesScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(
                featureToggles: {'freeAccessMode': false, 'customDomains': false},
                error: 'Something went wrong',
                isLoading: false,
              ),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
  });
}
