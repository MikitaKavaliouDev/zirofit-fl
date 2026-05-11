import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/features/clients/providers/measurement_provider.dart';
import 'package:zirofit_fl/features/dashboard/widgets/quick_weight_log.dart';

import '../../helpers/test_setup.dart';

// =============================================================================
// Fake notifier for controlled testing
// =============================================================================

class FakeMeasurementNotifier extends ClientMeasurementNotifier {
  ClientMeasurementState _s;
  bool addMeasurementCalled = false;
  double? savedWeightKg;
  String? savedNotes;

  FakeMeasurementNotifier(this._s)
      : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  ClientMeasurementState get state => _s;

  @override
  Future<void> fetchMeasurements() async {}

  @override
  Future<String?> addMeasurement({
    double? weightKg,
    double? bodyFatPercentage,
    DateTime? measurementDate,
    String? notes,
  }) async {
    addMeasurementCalled = true;
    savedWeightKg = weightKg;
    savedNotes = notes;

    // Simulate state update so the UI reflects the new weight
    final now = DateTime.now();
    final newMeas = ClientMeasurement(
      id: 'new_${now.millisecondsSinceEpoch}',
      clientId: 'c1',
      measurementDate: measurementDate ?? now,
      weightKg: weightKg,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    _s = _s.copyWith(measurements: [newMeas, ..._s.measurements]);
    super.state = _s;
    return null;
  }
}

// =============================================================================
// Helpers
// =============================================================================

Widget buildWidget(ClientMeasurementState state) {
  return ProviderScope(
    overrides: [
      clientMeasurementProvider
          .overrideWith((ref) => FakeMeasurementNotifier(state)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: QuickWeightLogWidget(),
      ),
    ),
  );
}

ClientMeasurement _meas({double? weightKg, String id = '1'}) {
  final now = DateTime.now();
  return ClientMeasurement(
    id: id,
    clientId: 'c1',
    measurementDate: now,
    weightKg: weightKg,
    createdAt: now,
    updatedAt: now,
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  setUpAll(() => configureTestApiClient());

  // ---------------------------------------------------------------------------
  // Test 1: Shows current weight
  // ---------------------------------------------------------------------------

  testWidgets('Test 1: Shows current weight in display mode', (t) async {
    final state = ClientMeasurementState(
      measurements: [_meas(weightKg: 75.5)],
      isLoading: false,
    );

    await t.pumpWidget(buildWidget(state));
    await t.pump();

    expect(find.text('WEIGHT'), findsOneWidget);
    expect(find.text('75.5 kg'), findsOneWidget);
    expect(find.text('-- kg'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Tap enters edit mode
  // ---------------------------------------------------------------------------

  testWidgets('Test 2: Tap on weight text enters edit mode', (t) async {
    final state = ClientMeasurementState(
      measurements: [_meas(weightKg: 75.5)],
      isLoading: false,
    );

    await t.pumpWidget(buildWidget(state));
    await t.pump();

    // Tap the card to enter edit mode
    await t.tap(find.text('75.5 kg'));
    await t.pump();

    // Edit mode UI should appear
    expect(find.text('Log Weight'), findsOneWidget);
    expect(find.text('Save Weight'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Display mode label should be gone
    expect(find.text('WEIGHT'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Test 3: Save calls API
  // ---------------------------------------------------------------------------

  testWidgets('Test 3: Save calls addMeasurement on notifier', (t) async {
    final state = ClientMeasurementState(
      measurements: [_meas(weightKg: 75.5)],
      isLoading: false,
    );

    // Create the notifier separately so we can spy on it
    final fake = FakeMeasurementNotifier(state);

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          clientMeasurementProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: QuickWeightLogWidget(),
          ),
        ),
      ),
    );
    await t.pump();

    // Enter edit mode
    await t.tap(find.text('75.5 kg'));
    await t.pump();

    // Clear and enter new weight
    final textField = find.byType(TextField).first;
    await t.enterText(textField, '76.0');
    await t.pump();

    // Tap save
    await t.tap(find.text('Save Weight'));
    await t.pump();

    // Verify the notifier was called correctly
    expect(fake.addMeasurementCalled, isTrue);
    expect(fake.savedWeightKg, 76.0);

    // Should return to display mode
    expect(find.text('WEIGHT'), findsOneWidget);
    expect(find.text('76.0 kg'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 4: Cancel reverts
  // ---------------------------------------------------------------------------

  testWidgets('Test 4: Cancel reverts to display mode without saving',
      (t) async {
    final state = ClientMeasurementState(
      measurements: [_meas(weightKg: 75.5)],
      isLoading: false,
    );

    final fake = FakeMeasurementNotifier(state);

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          clientMeasurementProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: QuickWeightLogWidget(),
          ),
        ),
      ),
    );
    await t.pump();

    // Enter edit mode
    await t.tap(find.text('75.5 kg'));
    await t.pump();

    // Change weight in the text field
    await t.enterText(find.byType(TextField).first, '99.9');
    await t.pump();

    // Tap close / cancel
    await t.tap(find.byIcon(Icons.close));
    await t.pump();

    // Should revert to display mode showing original weight
    expect(find.text('WEIGHT'), findsOneWidget);
    expect(find.text('75.5 kg'), findsOneWidget);
    expect(find.text('99.9 kg'), findsNothing);

    // addMeasurement should NOT have been called
    expect(fake.addMeasurementCalled, isFalse);
  });

  // ---------------------------------------------------------------------------
  // Test 5: Loading state
  // ---------------------------------------------------------------------------

  testWidgets('Test 5: Shows loading placeholder when fetching', (t) async {
    const state = ClientMeasurementState(
      measurements: [],
      isLoading: true,
    );

    await t.pumpWidget(buildWidget(state));
    await t.pump();

    // The label should still show
    expect(find.text('WEIGHT'), findsOneWidget);

    // No weight value shown yet
    expect(find.text('-- kg'), findsNothing);

    // A loading placeholder (shimmer-like container) should be present
    // The loading state renders a Container with surfaceContainerHighest color
    // as a placeholder bar
    expect(find.byType(Card), findsOneWidget);
  });

  testWidgets('Test 5b: Shows "-- kg" when no measurements and not loading',
      (t) async {
    const state = ClientMeasurementState(
      measurements: [],
      isLoading: false,
    );

    await t.pumpWidget(buildWidget(state));
    await t.pump();

    expect(find.text('WEIGHT'), findsOneWidget);
    expect(find.text('-- kg'), findsOneWidget);
  });
}
