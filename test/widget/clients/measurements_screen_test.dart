import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/body_measurement.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/clients/data/measurement_remote_source.dart';
import 'package:zirofit_fl/features/clients/providers/measurement_provider.dart';
import 'package:zirofit_fl/features/clients/screens/measurements_screen.dart';
import '../../helpers/test_setup.dart';

// =============================================================================
// Fake notifiers
// =============================================================================

class FakeClientMeasurementNotifier extends ClientMeasurementNotifier {
  final ClientMeasurementState _s;
  FakeClientMeasurementNotifier(this._s)
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
  }) async =>
      null;
}

class FakeBodyMeasurementNotifier extends BodyMeasurementNotifier {
  final BodyMeasurementState _s;
  FakeBodyMeasurementNotifier(this._s)
      : super(
          remoteSource:
              MeasurementRemoteSource(apiClient: ApiClient.instance),
        ) {
    super.state = _s;
  }
  @override
  BodyMeasurementState get state => _s;
  @override
  Future<void> fetchMeasurements({required String clientId}) async {}
  @override
  Future<String?> addMeasurement({
    required String clientId,
    required String type,
    required String typeName,
    required double valueCm,
    String unit = 'cm',
  }) async =>
      null;
}

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _s;
  FakeAuthNotifier(this._s)
      : super(
          apiClient: ApiClient.instance,
          secureStorage: FakeSecureStorage(),
        ) {
    super.state = _s;
  }
  @override
  AuthState get state => _s;
}

// =============================================================================
// Constants
// =============================================================================

const _authenticatedAuthState = AuthState(
  status: AuthStatus.authenticated,
  user: User(id: 'test-user', email: 'test@example.com'),
);

// =============================================================================
// Test widget builder
// =============================================================================

Widget buildTestWidget({
  ClientMeasurementState clientState = const ClientMeasurementState(),
  BodyMeasurementState bodyState = const BodyMeasurementState(),
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => FakeAuthNotifier(_authenticatedAuthState),
      ),
      clientMeasurementProvider.overrideWith(
        (ref) => FakeClientMeasurementNotifier(clientState),
      ),
      bodyMeasurementProvider.overrideWith(
        (ref) => FakeBodyMeasurementNotifier(bodyState),
      ),
    ],
    child: const MaterialApp(home: MeasurementsScreen()),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  setUpAll(() => configureTestApiClient());

  group('MeasurementsScreen', () {
    testWidgets('renders app bar with Measurements title', (t) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump();

      expect(find.text('Measurements'), findsOneWidget);
    });

    testWidgets('shows Core section with Weight and Body Fat rows', (t) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump();

      expect(find.text('CORE'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Body Fat'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);
    });

    testWidgets('shows Body Part section with measurement types', (t) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump();

      expect(find.text('BODY PART'), findsOneWidget);
      expect(find.text('Neck'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Waist'), findsOneWidget);
      expect(find.text('Left Bicep'), findsOneWidget);
      expect(find.text('Right Thigh'), findsOneWidget);
    });

    testWidgets('tapping a row opens add measurement sheet', (t) async {
      await t.pumpWidget(buildTestWidget());
      await t.pump();

      await t.tap(find.text('Weight'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      expect(find.text('Save Measurement'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets(
      'displays last recorded value for each measurement type',
      (t) async {
        final now = DateTime.now();
        final clientState = ClientMeasurementState(
          measurements: [
            ClientMeasurement(
              id: 'm1',
              clientId: 'test-user',
              measurementDate: now.subtract(const Duration(days: 1)),
              weightKg: 75.5,
              bodyFatPercentage: 15.0,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );
        final bodyState = BodyMeasurementState(
          measurements: [
            BodyMeasurement(
              id: 'bm1',
              clientId: 'test-user',
              type: 'chest',
              typeName: 'Chest',
              valueCm: 100.0,
              measuredAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        ).withRebuiltHistory();

        await t.pumpWidget(buildTestWidget(
          clientState: clientState,
          bodyState: bodyState,
        ));
        await t.pump();

        expect(find.text('75.5 kg'), findsOneWidget);
        expect(find.text('15.0%'), findsOneWidget);
        expect(find.text('100.0 cm'), findsOneWidget);
      },
    );
  });
}
