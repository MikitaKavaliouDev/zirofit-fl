import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/checkin/providers/trainer_check_ins_provider.dart';
import 'package:zirofit_fl/features/clients/providers/client_detail_provider.dart';
import 'package:zirofit_fl/features/clients/screens/client_history_screen.dart';
import '../../helpers/test_setup.dart';

// =============================================================================
// Fake notifiers
// =============================================================================

class FakeClientDetailNotifier extends ClientDetailNotifier {
  final ClientDetailState _s;
  FakeClientDetailNotifier(this._s, {required String clientId})
      : super(apiClient: ApiClient.instance, clientId: clientId) {
    super.state = _s;
  }

  @override
  ClientDetailState get state => _s;

  @override
  Future<void> fetchAll() async {}

  @override
  Future<void> fetchClient() async {}

  @override
  Future<void> fetchMeasurements() async {}

  @override
  Future<void> fetchPhotos() async {}

  @override
  Future<void> fetchSessions() async {}
}

class FakeTrainerCheckInsNotifier extends TrainerCheckInsNotifier {
  final TrainerCheckInsState _s;
  FakeTrainerCheckInsNotifier(this._s) : super() {
    super.state = _s;
  }

  @override
  TrainerCheckInsState get state => _s;

  @override
  Future<void> fetchCheckIns({String? status}) async {}
}

// =============================================================================
// Helpers
// =============================================================================

const _testClientId = 'test-client';

Widget createTestApp({
  required ClientDetailState clientDetailState,
  required TrainerCheckInsState checkInState,
}) {
  return ProviderScope(
    overrides: [
      clientDetailProvider(_testClientId).overrideWith(
        (ref) => FakeClientDetailNotifier(
          clientDetailState,
          clientId: _testClientId,
        ),
      ),
      trainerCheckInsProvider.overrideWith(
        (ref) => FakeTrainerCheckInsNotifier(checkInState),
      ),
    ],
    child: const MaterialApp(
      home: ClientHistoryScreen(clientId: _testClientId),
    ),
  );
}

Client _createClient() {
  final now = DateTime.now();
  return Client(
    id: _testClientId,
    name: 'Test Client',
    email: 'test@test.com',
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  setUpAll(() => configureTestApiClient());

  group('ClientHistoryScreen', () {
    testWidgets('renders with History title', (tester) async {
      await tester.pumpWidget(createTestApp(
        clientDetailState: const ClientDetailState(),
        checkInState: const TrainerCheckInsState(),
      ));
      await tester.pump();

      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('shows filter chips (All, Workouts, Check-ins, Measurements)',
        (tester) async {
      final now = DateTime.now();
      final session = WorkoutSession(
        id: 'ws-1',
        clientId: _testClientId,
        name: 'Morning Workout',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(createTestApp(
        clientDetailState: ClientDetailState(
          client: _createClient(),
          sessions: [session],
          isLoadingClient: false,
          isLoadingMeasurements: false,
          isLoadingPhotos: false,
          isLoadingSessions: false,
        ),
        checkInState: const TrainerCheckInsState(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('Check-ins'), findsOneWidget);
      expect(find.text('Measurements'), findsOneWidget);
    });

    testWidgets('displays timeline items when data exists', (tester) async {
      final now = DateTime.now();

      final session = WorkoutSession(
        id: 'ws-1',
        clientId: _testClientId,
        name: 'Morning Workout',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        createdAt: now,
        updatedAt: now,
      );

      final checkIn = CheckIn(
        id: 'ci-1',
        clientId: _testClientId,
        date: now.subtract(const Duration(hours: 3)),
        weight: 75.5,
        waistCm: 80.0,
        status: 'REVIEWED',
        createdAt: now,
        updatedAt: now,
      );

      final measurement = ClientMeasurement(
        id: 'm-1',
        clientId: _testClientId,
        measurementDate: now.subtract(const Duration(hours: 4)),
        weightKg: 75.0,
        bodyFatPercentage: 15.0,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(createTestApp(
        clientDetailState: ClientDetailState(
          client: _createClient(),
          sessions: [session],
          measurements: [measurement],
          isLoadingClient: false,
          isLoadingMeasurements: false,
          isLoadingPhotos: false,
          isLoadingSessions: false,
        ),
        checkInState: TrainerCheckInsState(
          checkIns: [checkIn],
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // All three item types should appear
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('Weekly Check-in'), findsOneWidget);
      // Measurement title includes weight info
      expect(find.textContaining('Weight: 75.0'), findsOneWidget);
    });

    testWidgets('filtering by type shows only matching items',
        (tester) async {
      final now = DateTime.now();

      final session = WorkoutSession(
        id: 'ws-1',
        clientId: _testClientId,
        name: 'Morning Workout',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        createdAt: now,
        updatedAt: now,
      );

      final checkIn = CheckIn(
        id: 'ci-1',
        clientId: _testClientId,
        date: now.subtract(const Duration(hours: 3)),
        weight: 75.5,
        status: 'REVIEWED',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(createTestApp(
        clientDetailState: ClientDetailState(
          client: _createClient(),
          sessions: [session],
          isLoadingClient: false,
          isLoadingMeasurements: false,
          isLoadingPhotos: false,
          isLoadingSessions: false,
        ),
        checkInState: TrainerCheckInsState(
          checkIns: [checkIn],
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Both items appear with All filter
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('Weekly Check-in'), findsOneWidget);

      // Tap Workouts filter chip
      await tester.tap(find.text('Workouts'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Only workout should remain
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('Weekly Check-in'), findsNothing);
    });

    testWidgets('empty state when no history', (tester) async {
      await tester.pumpWidget(createTestApp(
        clientDetailState: const ClientDetailState(),
        checkInState: const TrainerCheckInsState(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No history available yet'), findsOneWidget);
    });

    testWidgets('tapping an item expands details', (tester) async {
      final now = DateTime.now();

      final session = WorkoutSession(
        id: 'ws-1',
        clientId: _testClientId,
        name: 'Morning Workout',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: WorkoutSessionStatus.completed,
        notes: 'Great session!',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(createTestApp(
        clientDetailState: ClientDetailState(
          client: _createClient(),
          sessions: [session],
          isLoadingClient: false,
          isLoadingMeasurements: false,
          isLoadingPhotos: false,
          isLoadingSessions: false,
        ),
        checkInState: const TrainerCheckInsState(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the workout card
      await tester.tap(find.text('Morning Workout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // AnimatedSize

      // Expanded detail shows status and notes
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Great session!'), findsOneWidget);
    });

    testWidgets('loading state shows shimmer', (tester) async {
      await tester.pumpWidget(createTestApp(
        clientDetailState: const ClientDetailState(
          isLoadingClient: true,
        ),
        checkInState: const TrainerCheckInsState(),
      ));
      await tester.pump();

      // Shimmer loading placeholder is shown
      expect(find.byType(Shimmer), findsOneWidget);
      // AppBar title still visible
      expect(find.text('History'), findsOneWidget);
    });
  });
}
