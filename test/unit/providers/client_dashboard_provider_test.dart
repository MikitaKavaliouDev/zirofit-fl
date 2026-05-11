import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/dashboard/providers/client_dashboard_provider.dart';

import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Helpers — backend-shaped JSON builders
// ---------------------------------------------------------------------------

const _trainerJson = {
  'id': 'trainer-1',
  'name': 'Coach Sarah',
  'username': 'coachsarah',
  'email': 'sarah@example.com',
};

Map<String, dynamic> _sessionJson({
  String id = 'ws-1',
  String status = 'COMPLETED',
  int logCount = 0,
  String? endTime,
}) {
  // Use UTC for consistency (matching what JSON serialization produces)
  const startUtc = '2026-05-05T10:00:00.000Z'; // was 12:00 in UTC+2
  return {
    'id': id,
    'clientId': 'c-1',
    'name': 'Upper Body',
    'startTime': startUtc,
    'endTime': endTime ?? '2026-05-05T11:00:00.000Z',
    'status': status,
    'isTrainerLed': false,
    'exerciseLogs': List.generate(logCount, (i) => {'id': 'log-$i'}),
  };
}

Map<String, dynamic> _measurementJson({
  String id = 'm-1',
  double weightKg = 80.0,
  double? bodyFat,
  String date = '2026-05-01T00:00:00Z',
}) {
  return {
    'id': id,
    'clientId': 'c-1',
    'measurementDate': date,
    'weightKg': weightKg,
    'bodyFatPercentage': ?bodyFat,
  };
}

Map<String, dynamic> _upcomingSessionJson({
  String id = 'us-1',
  String title = 'Upper Body',
  String date = '2026-05-06T10:00:00Z',
  int duration = 60,
}) {
  return {'id': id, 'title': title, 'date': date, 'duration': duration};
}

/// Returns a full backend-shaped dashboard response (what /client/dashboard returns).
Map<String, dynamic> _backendDashboardResponse({
  bool hasTrainer = true,
  int sessionCount = 5,
  int measurementCount = 2,
  int upcomingCount = 3,
  String? lastCheckIn,
}) {
  final now = DateTime(2026, 5, 5);
  final sessions = List.generate(
    sessionCount,
    (i) => _sessionJson(
      id: 'ws-$i',
      logCount: i == 0 ? 10 : 5,
      endTime: now.subtract(Duration(days: i)).toIso8601String(),
    ),
  );
  final measurements = List.generate(
    measurementCount,
    (i) => _measurementJson(
      id: 'm-$i',
      weightKg: 82.0 - i * 1.5,
      date: now.subtract(Duration(days: measurementCount - i - 1)).toIso8601String(),
    ),
  );

  return {
    'data': {
      'clientData': {
        'id': 'client-1',
        'userId': 'user-1',
        'name': 'John Doe',
        'email': 'john@example.com',
        if (hasTrainer) 'trainer': _trainerJson,
        'workoutSessions': sessions,
        'measurements': measurements,
      },
      'weightUnit': 'KG',
      'upcomingClientSessions':
          List.generate(upcomingCount, (i) => _upcomingSessionJson(id: 'us-$i', title: 'Session $i')),
      'lastCheckIn': ?lastCheckIn,
    },
  };
}

/// An interceptor that resolves every request with a canned JSON response.
class _MockInterceptor extends Interceptor {
  final Map<String, dynamic> Function() _responseFactory;

  _MockInterceptor(this._responseFactory);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        statusMessage: 'OK',
        data: _responseFactory(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    ApiClient.reset();
    configureTestApiClient();
  });

  tearDown(() {
    ApiClient.reset();
  });

  // ===========================================================================
  // Model parsing tests (pure functions, no provider needed)
  // ===========================================================================

  group('LastWorkoutSummary.fromSession', () {
    test('parses session with exercise logs', () {
      // startTime=10:00Z, endTime=11:30Z → duration=1h30m
      final session = _sessionJson(logCount: 8, endTime: '2026-05-05T11:30:00.000Z');
      final summary = LastWorkoutSummary.fromSession(session);

      expect(summary.date.isAtSameMomentAs(DateTime.utc(2026, 5, 5, 11, 30)), true);
      expect(summary.exercisesCompleted, 8);
      expect(summary.totalExercises, 8);
      expect(summary.duration, const Duration(hours: 1, minutes: 30));
    });

    test('handles empty session', () {
      final summary = LastWorkoutSummary.fromSession({});
      expect(summary.exercisesCompleted, 0);
      expect(summary.totalExercises, 0);
      expect(summary.duration, Duration.zero);
    });

    test('handles session without endTime', () {
      // Only set startTime, no endTime key in JSON
      final session = <String, dynamic>{
        'id': 'ws-test',
        'startTime': '2026-05-05T12:00:00.000Z',
      };
      final summary = LastWorkoutSummary.fromSession(session);
      // duration is zero when endTime is missing
      expect(summary.duration, Duration.zero);
    });
  });

  group('ProgressSummary.compute', () {
    test('computes weight change from measurements', () {
      final sessions = List.generate(3, (i) => _sessionJson(id: 'ws-$i'));
      final measurements = [
        _measurementJson(weightKg: 80.0, date: '2026-05-01T00:00:00Z'),
        _measurementJson(weightKg: 78.5, date: '2026-05-05T00:00:00Z'),
      ];

      final progress = ProgressSummary.compute(
        workoutSessions: sessions,
        measurements: measurements,
      );

      expect(progress.currentWeight, 78.5);
      expect(progress.startingWeight, 80.0);
      expect(progress.weightChange, closeTo(-1.5, 0.01));
    });

    test('handles empty measurements', () {
      final progress = ProgressSummary.compute(
        workoutSessions: [],
        measurements: [],
      );

      expect(progress.currentWeight, isNull);
      expect(progress.startingWeight, isNull);
      expect(progress.weightChange, 0.0);
      expect(progress.totalWorkoutsThisMonth, 0);
    });

    test('counts only this months workouts', () {
      final sessions = [
        _sessionJson(
          id: 'ws-1',
          endTime: DateTime(2026, 5, 5).toIso8601String(),
        ),
        _sessionJson(
          id: 'ws-2',
          endTime: DateTime(2026, 4, 28).toIso8601String(), // last month
        ),
      ];

      final progress = ProgressSummary.compute(
        workoutSessions: sessions,
        measurements: [],
      );

      expect(progress.totalWorkoutsThisMonth, 1);
    });
  });

  group('CheckInStatus.fromLastCheckIn', () {
    test('is completed when lastCheckIn is provided', () {
      final status = CheckInStatus.fromLastCheckIn('2026-05-01T00:00:00.000Z');
      expect(status.isCompleted, true);
      expect(status.isDueToday, false);
      expect(status.lastCheckInDate!.isAtSameMomentAs(DateTime.utc(2026, 5, 1)), true);
    });

    test('is due today when lastCheckIn is null', () {
      final status = CheckInStatus.fromLastCheckIn(null);
      expect(status.isCompleted, false);
      expect(status.isDueToday, true);
      expect(status.lastCheckInDate, isNull);
    });
  });

  group('ClientDashboardData.fromJson', () {
    test('parses full backend response', () {
      final response = _backendDashboardResponse(lastCheckIn: '2026-05-01T00:00:00Z');
      final dataMap = response['data'] as Map<String, dynamic>;
      final dashboard = ClientDashboardData.fromJson(dataMap);

      // Last workout (most recent session should be ws-0)
      expect(dashboard.lastWorkout.exercisesCompleted, 10);
      expect(dashboard.lastWorkout.totalExercises, 10);

      // Upcoming sessions
      expect(dashboard.upcomingSessions, hasLength(3));
      expect(dashboard.upcomingSessions[0].name, 'Session 0');

      // Check-in
      expect(dashboard.checkInStatus.isCompleted, true);
      expect(dashboard.checkInStatus.lastCheckInDate!.isAtSameMomentAs(DateTime.utc(2026, 5, 1)), true);

      // Progress: 2 measurements 82.0 (May 4) → 80.5 (May 5)
      expect(dashboard.progress.currentWeight, 80.5);
      expect(dashboard.progress.startingWeight, 82.0);
      expect(dashboard.progress.weightChange, closeTo(-1.5, 0.01));

      // Trainer
      expect(dashboard.trainerName, 'Coach Sarah');
    });

    test('handles null trainer and null lastCheckIn', () {
      final response = _backendDashboardResponse(hasTrainer: false, lastCheckIn: null);
      final dataMap = response['data'] as Map<String, dynamic>;
      final dashboard = ClientDashboardData.fromJson(dataMap);

      expect(dashboard.trainerName, isNull);
      expect(dashboard.checkInStatus.isCompleted, false);
      expect(dashboard.checkInStatus.isDueToday, true);
    });

    test('handles empty data gracefully', () {
      final dashboard = ClientDashboardData.fromJson({});
      expect(dashboard.lastWorkout.exercisesCompleted, 0);
      expect(dashboard.upcomingSessions, isEmpty);
      expect(dashboard.checkInStatus.isCompleted, false);
      expect(dashboard.trainerName, isNull);
    });
  });

  // ===========================================================================
  // Provider integration test (through ProviderContainer)
  // ===========================================================================

  group('ClientDashboardNotifier (via ProviderContainer)', () {
    test('build returns AsyncData on success', () async {
      // Wire a mock interceptor that returns the expected backend shape
      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(() => _backendDashboardResponse()),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Reading the provider triggers build() -> _fetchDashboard()
      final watcher = container.listen(clientDashboardProvider, (_, _) {});
      addTearDown(watcher.close);

      // Wait for the async operation to complete
      await container.read(clientDashboardProvider.future);

      final state = container.read(clientDashboardProvider);
      expect(state.hasValue, true);
      expect(state.requireValue.trainerName, 'Coach Sarah');
      expect(state.requireValue.upcomingSessions, hasLength(3));
    });

    test('build returns AsyncError on API failure', () async {
      // Wire a mock interceptor that returns an unexpected shape
      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(() => {'data': null}),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read the provider to trigger build() -> _fetchDashboard()
      // The future should complete with an error because dataMap is null
      try {
        await container.read(clientDashboardProvider.future);
        fail('Expected exception to be thrown');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('returned no data'));
      }
    });
  });
}
