import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/data/models/fitness_goal.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_provider.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';
import 'package:zirofit_fl/features/progress/data/analytics_remote_source.dart';
import 'package:zirofit_fl/features/progress/providers/analytics_provider.dart';
import 'package:zirofit_fl/features/progress/providers/goal_provider.dart' as goal_mod;
import 'package:zirofit_fl/features/progress/providers/goal_provider.dart'
    show goalsProvider;
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

class MockAnalyticsRemoteSource extends Mock implements AnalyticsRemoteSource {}

// ===================================================================
// Fixtures — Flow 1: Analytics
// ===================================================================

ClientAnalytics _createAnalytics() {
  final now = DateTime(2024, 1, 15);
  return ClientAnalytics(
    heatmapDates: [
      '2024-01-08',
      '2024-01-09',
      '2024-01-10',
      '2024-01-11',
      '2024-01-12',
    ],
    volumeHistory: const [
      VolumePoint(date: '2024-01-08', volume: 1000),
      VolumePoint(date: '2024-01-09', volume: 1200),
      VolumePoint(date: '2024-01-10', volume: 900),
      VolumePoint(date: '2024-01-11', volume: 1100),
      VolumePoint(date: '2024-01-12', volume: 950),
    ],
    muscleDistribution: const [
      MusclePoint(muscle: 'Chest', count: 5),
      MusclePoint(muscle: 'Back', count: 3),
      MusclePoint(muscle: 'Legs', count: 4),
      MusclePoint(muscle: 'Shoulders', count: 2),
    ],
    recentPRs: [
      AnalyticsPersonalRecord(
        exercise: 'Bench Press',
        value: 100,
        type: 'weight',
        date: now,
      ),
      AnalyticsPersonalRecord(
        exercise: 'Squat',
        value: 140,
        type: 'weight',
        date: now.subtract(const Duration(days: 3)),
      ),
    ],
    consistency: 80,
  );
}

ClientAnalytics _createEmptyAnalytics() {
  return const ClientAnalytics(
    heatmapDates: [],
    volumeHistory: [],
    muscleDistribution: [],
    recentPRs: [],
    consistency: 0,
  );
}

ClientProgress _createProgress() {
  final now = DateTime(2024, 1, 15);
  return ClientProgress(
    weight: [
      MetricPoint(date: now.subtract(const Duration(days: 30)), value: 82),
      MetricPoint(date: now, value: 80),
    ],
    bodyFat: [
      MetricPoint(date: now.subtract(const Duration(days: 30)), value: 16),
      MetricPoint(date: now, value: 15),
    ],
    volume: const [
      VolumePoint(date: '2024-01-08', volume: 1000),
      VolumePoint(date: '2024-01-09', volume: 1200),
    ],
    exercisePerformance: const [
      ExercisePerformance(exercise: 'Bench Press', averageWeight: 80, maxWeight: 100),
      ExercisePerformance(exercise: 'Squat', averageWeight: 100, maxWeight: 120),
    ],
    favoriteExercises: const [
      FavoriteExercise(exercise: 'Bench Press', count: 10),
    ],
    worstPerformingExercises: const [
      WorstExercise(exercise: 'Deadlift', averageWeight: 60),
    ],
  );
}

// ===================================================================
// Fixtures — Flow 2: Check-in
// ===================================================================

Map<String, dynamic> _checkInJson({
  String id = 'checkin-1',
  double weight = 80.0,
  String status = 'SUBMITTED',
}) {
  return {
    'id': id,
    'client_id': 'client-1',
    'date': 1700000000000,
    'status': status,
    'weight': weight,
    'waist_cm': 85.0,
    'sleep_hours': 7.5,
    'energy_level': 4,
    'stress_level': 3,
    'hunger_level': 3,
    'digestion_level': 4,
    'nutrition_compliance': '80',
    'client_notes': 'Feeling great this week!',
    'created_at': 1700000000000,
    'updated_at': 1700000000000,
  };
}

// ===================================================================
// Fixtures — Flow 3: Programs / Routines
// ===================================================================

Map<String, dynamic> _programJson({
  String id = 'prog-1',
  String name = 'Beginner Full Body',
}) {
  return {
    'id': id,
    'name': name,
    'description': 'A great starting program',
    'created_at': 1700000000000,
    'updated_at': 1700000000000,
  };
}

Map<String, dynamic> _templateJson({
  String id = 'tmpl-1',
  String name = 'Full Body Workout',
  String programId = 'prog-1',
  int order = 1,
}) {
  return {
    'id': id,
    'name': name,
    'description': 'A complete full body session',
    'program_id': programId,
    'order': order,
    'created_at': 1700000000000,
    'updated_at': 1700000000000,
  };
}

// ===================================================================
// Flow 1: Analytics → Display
// ===================================================================

void main() {
  // ===================================================================
  // FLOW 1 — Analytics → Display
  // ===================================================================

  group('Flow 1: Analytics → Display', () {
    late MockAnalyticsRemoteSource mockRemoteSource;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockRemoteSource = MockAnalyticsRemoteSource();
      container = createTestContainer(overrides: [
        analyticsRemoteSourceProvider.overrideWithValue(mockRemoteSource),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    // -----------------------------------------------------------------
    // Initial state
    // -----------------------------------------------------------------

    test('initial state is idle with no analytics data', () {
      final state = container.read(analyticsProvider);
      expect(state.isLoading, false);
      expect(state.analytics, isNull);
      expect(state.progress, isNull);
      expect(state.error, isNull);
      expect(state.isIdle, true);
      expect(state.hasData, false);
    });

    // -----------------------------------------------------------------
    // loadAnalytics — full lifecycle
    // -----------------------------------------------------------------

    test('loadAnalytics transitions: idle → loading → data', () async {
      final analytics = _createAnalytics();
      when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
          .thenAnswer((_) async => analytics);

      // Act: start loading
      final future =
          container.read(analyticsProvider.notifier).loadAnalytics();

      // Assert: intermediate loading state
      expect(container.read(analyticsProvider).isLoading, isTrue);

      await future;

      // Assert: data state
      final state = container.read(analyticsProvider);
      expect(state.isLoading, false);
      expect(state.hasData, true);
      expect(state.analytics, isNotNull);
      expect(state.error, isNull);
    });

    // -----------------------------------------------------------------
    // ClientAnalytics model — field verification
    // -----------------------------------------------------------------

    test('ClientAnalytics model parses correctly', () async {
      final analytics = _createAnalytics();
      when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
          .thenAnswer((_) async => analytics);

      await container.read(analyticsProvider.notifier).loadAnalytics();
      final state = container.read(analyticsProvider);

      final result = state.analytics!;
      expect(result.heatmapDates, hasLength(5));
      expect(result.volumeHistory, hasLength(5));
      expect(result.volumeHistory[0].volume, 1000);
      expect(result.muscleDistribution, hasLength(4));
      expect(result.muscleDistribution[0].muscle, 'Chest');
      expect(result.muscleDistribution[0].count, 5);
      expect(result.recentPRs, hasLength(2));
      expect(result.recentPRs[0].exercise, 'Bench Press');
      expect(result.recentPRs[0].value, 100);
      expect(result.consistency, 80);
    });

    // -----------------------------------------------------------------
    // loadProgress
    // -----------------------------------------------------------------

    test('loadProgress transitions: idle → loading → data', () async {
      final progress = _createProgress();
      when(() => mockRemoteSource.fetchProgress())
          .thenAnswer((_) async => progress);

      final future = container.read(analyticsProvider.notifier).loadProgress();

      expect(container.read(analyticsProvider).isLoading, isTrue);

      await future;

      final state = container.read(analyticsProvider);
      expect(state.isLoading, false);
      expect(state.progress, isNotNull);
      expect(state.progress!.weight, hasLength(2));
      expect(state.progress!.weight[0].value, 82);
      expect(state.progress!.weight[1].value, 80);
      expect(state.error, isNull);
    });

    // -----------------------------------------------------------------
    // goalsProvider — reads from analytics
    // -----------------------------------------------------------------

    test('goalsProvider can read from analytics via updateProgress', () async {
      // Arrange: add a sessions goal
      // Use recent dates so updateProgress (which checks last 7 days) matches
      final today = DateTime.now();
      final recentDates = [
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
        today.subtract(const Duration(days: 3)),
      ];
      final dateStrs = recentDates
          .map((d) =>
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
          .toList();

      final goal = FitnessGoal(
        id: 'goal-1',
        type: GoalType.sessions,
        targetValue: 5,
        currentValue: 0,
        startDate: today.subtract(const Duration(days: 30)),
      );
      await container.read(goalsProvider.notifier).setGoal(goal);

      // Verify goal exists
      var goalsState = container.read(goalsProvider);
      expect(goalsState.goals, hasLength(1));
      expect(goalsState.goals[0].currentValue, 0.0);

      // Act: update goal progress with recent heatmap dates
      await container.read(goalsProvider.notifier).updateProgress(
            heatmapDates: dateStrs,
          );

      // Assert: goal progress updated
      goalsState = container.read(goalsProvider);
      expect(goalsState.goals[0].currentValue, greaterThan(0));
      expect(goalsState.goals[0].currentValue, 3.0);
    });

    // -----------------------------------------------------------------
    // Volume goal progress from analytics
    // -----------------------------------------------------------------

    test('goalsProvider volume goal increases from volumeHistory', () async {
      // Use recent dates so updateProgress matches
      final today = DateTime.now();
      final recentDates = [
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      ];

      final goal = FitnessGoal(
        id: 'goal-2',
        type: GoalType.volume,
        targetValue: 10000,
        currentValue: 0,
        startDate: today.subtract(const Duration(days: 30)),
      );
      await container.read(goalsProvider.notifier).setGoal(goal);

      await container.read(goalsProvider.notifier).updateProgress(
            volumeHistory: recentDates
                .map((d) => goal_mod.VolumePoint(date: d, volume: 500))
                .toList(),
          );

      final goalsState = container.read(goalsProvider);
      expect(goalsState.goals[0].currentValue, greaterThan(0));
      expect(goalsState.goals[0].currentValue, 1000.0);
    });

    // -----------------------------------------------------------------
    // Error handling
    // -----------------------------------------------------------------

    test('loadAnalytics sets error state on failure', () async {
      when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
          .thenThrow(Exception('Failed to load analytics'));

      await container.read(analyticsProvider.notifier).loadAnalytics();

      final state = container.read(analyticsProvider);
      expect(state.isLoading, false);
      expect(state.analytics, isNull);
      expect(state.error, contains('Failed to load analytics'));
    });

    test('loadProgress sets error state on failure', () async {
      when(() => mockRemoteSource.fetchProgress())
          .thenThrow(Exception('Progress fetch failed'));

      await container.read(analyticsProvider.notifier).loadProgress();

      final state = container.read(analyticsProvider);
      expect(state.isLoading, false);
      expect(state.progress, isNull);
      expect(state.error, contains('Progress fetch failed'));
    });

    // -----------------------------------------------------------------
    // Empty data
    // -----------------------------------------------------------------

    test('loadAnalytics handles empty analytics data gracefully', () async {
      final emptyAnalytics = _createEmptyAnalytics();
      when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
          .thenAnswer((_) async => emptyAnalytics);

      await container.read(analyticsProvider.notifier).loadAnalytics();

      final state = container.read(analyticsProvider);
      expect(state.hasData, isTrue);
      expect(state.analytics!.heatmapDates, isEmpty);
      expect(state.analytics!.volumeHistory, isEmpty);
      expect(state.analytics!.muscleDistribution, isEmpty);
      expect(state.analytics!.recentPRs, isEmpty);
      expect(state.analytics!.consistency, 0);
      expect(state.error, isNull);
    });

    // -----------------------------------------------------------------
    // clearError / reset
    // -----------------------------------------------------------------

    test('clearError resets error message', () async {
      when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
          .thenThrow(Exception('Some error'));
      await container.read(analyticsProvider.notifier).loadAnalytics();
      expect(container.read(analyticsProvider).error, contains('Some error'));

      container.read(analyticsProvider.notifier).clearError();

      expect(container.read(analyticsProvider).error, isNull);
    });
  });

  // ===================================================================
  // FLOW 2 — Check-in → Submit
  // ===================================================================

  group('Flow 2: Check-in → Submit', () {
    late MockApiClient mockApiClient;
    late CheckInNotifier notifier;

    setUp(() {
      mockApiClient = MockApiClient();
      notifier = CheckInNotifier(apiClient: mockApiClient);
    });

    // -----------------------------------------------------------------
    // Initial state
    // -----------------------------------------------------------------

    test('initial state has isSubmitting=false and no success', () {
      final state = notifier.state;
      expect(state.isSubmitting, false);
      expect(state.isSuccess, false);
      expect(state.error, isNull);
      expect(state.lastCheckIn, isNull);
    });

    // -----------------------------------------------------------------
    // Full submit flow — all fields
    // -----------------------------------------------------------------

    test('submitCheckIn transitions: idle → submitting → success', () async {
      // Arrange
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _checkInJson(),
          });

      // Act
      final future = notifier.submitCheckIn(
        date: DateTime(2024, 1, 15),
        weight: 80.0,
        waistCm: 85.0,
        sleepHours: 7.5,
        energyLevel: 4,
        stressLevel: 3,
        hungerLevel: 3,
        digestionLevel: 4,
        nutritionCompliance: '80',
        clientNotes: 'Feeling great this week!',
      );

      // Intermediate: submitting
      expect(notifier.state.isSubmitting, isTrue);

      await future;

      // Assert: success
      final state = notifier.state;
      expect(state.isSubmitting, false);
      expect(state.isSuccess, isTrue);
      expect(state.lastCheckIn, isNotNull);
      expect(state.lastCheckIn!.id, 'checkin-1');
      expect(state.lastCheckIn!.weight, 80.0);
      expect(state.lastCheckIn!.waistCm, 85.0);
      expect(state.lastCheckIn!.energyLevel, 4);
      expect(state.lastCheckIn!.clientNotes, 'Feeling great this week!');
      expect(state.error, isNull);
    });

    // -----------------------------------------------------------------
    // Verify API was called with correct data
    // -----------------------------------------------------------------

    test('submitCheckIn calls API with correct body', () async {
      // Arrange
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _checkInJson(),
          });

      // Act
      await notifier.submitCheckIn(
        date: DateTime(2024, 1, 15),
        weight: 80.0,
        waistCm: 85.0,
        sleepHours: 7.5,
        energyLevel: 4,
        stressLevel: 3,
        clientNotes: 'Good week',
      );

      // Assert: API called with correct body
      verify(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: {
              'weight': 80.0,
              'waistCm': 85.0,
              'sleepHours': 7.5,
              'energyLevel': 4,
              'stressLevel': 3,
              'clientNotes': 'Good week',
            },
          )).called(1);
    });

    // -----------------------------------------------------------------
    // Submit with minimal fields
    // -----------------------------------------------------------------

    test('submitCheckIn succeeds with only required fields', () async {
      // Arrange
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _checkInJson(weight: 75.0),
          });

      // Act — only weight (required) + date
      await notifier.submitCheckIn(
        date: DateTime(2024, 1, 15),
        weight: 75.0,
      );

      // Assert
      final state = notifier.state;
      expect(state.isSuccess, isTrue);
      expect(state.lastCheckIn!.weight, 75.0);

      verify(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: {'weight': 75.0},
          )).called(1);
    });

    // -----------------------------------------------------------------
    // Error handling
    // -----------------------------------------------------------------

    test('submitCheckIn sets error on API failure', () async {
      // Arrange
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clientCheckIn),
        response: Response(
          statusCode: 422,
          requestOptions: RequestOptions(path: ApiConstants.clientCheckIn),
          data: {'error': {'message': 'Weight is required'}},
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act
      await notifier.submitCheckIn(
        date: DateTime(2024, 1, 15),
        weight: 80.0,
      );

      // Assert
      final state = notifier.state;
      expect(state.isSubmitting, false);
      expect(state.isSuccess, false);
      expect(state.error, contains('Weight is required'));
    });

    test('submitCheckIn handles network error', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clientCheckIn),
        type: DioExceptionType.connectionError,
      ));

      await notifier.submitCheckIn(
        date: DateTime(2024, 1, 15),
        weight: 80.0,
      );

      expect(notifier.state.error, contains('No internet connection'));
    });

    // -----------------------------------------------------------------
    // fetchLastCheckIn
    // -----------------------------------------------------------------

    test('fetchLastCheckIn retrieves the most recent check-in', () async {
      // Arrange
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _checkInJson(id: 'checkin-prev', weight: 78.0),
          });

      // Act
      await notifier.fetchLastCheckIn();

      // Assert
      final state = notifier.state;
      expect(state.lastCheckIn, isNotNull);
      expect(state.lastCheckIn!.id, 'checkin-prev');
      expect(state.lastCheckIn!.weight, 78.0);
    });

    // -----------------------------------------------------------------
    // reset
    // -----------------------------------------------------------------

    test('reset clears state to initial values', () async {
      // First submit a check-in
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientCheckIn,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _checkInJson(),
          });
      await notifier.submitCheckIn(date: DateTime(2024, 1, 15), weight: 80.0);
      expect(notifier.state.isSuccess, isTrue);

      // Act
      notifier.reset();

      // Assert
      final state = notifier.state;
      expect(state.isSubmitting, false);
      expect(state.isSuccess, false);
      expect(state.error, isNull);
      expect(state.lastCheckIn, isNull);
    });
  });

  // ===================================================================
  // FLOW 3 — Save Routine
  // ===================================================================

  group('Flow 3: Save Routine', () {
    late MockApiClient mockApiClient;
    late ClientProgramsNotifier notifier;

    setUp(() {
      mockApiClient = MockApiClient();
      notifier = ClientProgramsNotifier(apiClient: mockApiClient);
    });

    // -----------------------------------------------------------------
    // Initial state
    // -----------------------------------------------------------------

    test('initial state has empty programs, templates, no active program', () {
      final state = notifier.state;
      expect(state.programs, isEmpty);
      expect(state.library?.personalTemplates ?? [], isEmpty);
      expect(state.activeProgramResponse?.program, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // -----------------------------------------------------------------
    // fetchPrograms
    // -----------------------------------------------------------------

    test('fetchPrograms transitions loading → populated programs', () async {
      // Arrange
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              _programJson(id: 'prog-1', name: 'Beginner Full Body'),
              _programJson(id: 'prog-2', name: 'Intermediate Split'),
            ],
          });

      // Act
      final future = notifier.fetchPrograms();

      // Intermediate: loading
      expect(notifier.state.isLoading, isTrue);

      await future;

      // Assert
      final state = notifier.state;
      expect(state.programs, hasLength(2));
      expect(state.programs[0].id, 'prog-1');
      expect(state.programs[0].name, 'Beginner Full Body');
      expect(state.programs[1].name, 'Intermediate Split');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchPrograms handles empty programs list', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.fetchPrograms();

      expect(notifier.state.programs, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    // -----------------------------------------------------------------
    // setActiveProgram — save routine
    // -----------------------------------------------------------------

    test('setActiveProgram saves routine and returns active program', () async {
      // Arrange
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _programJson(id: 'prog-1', name: 'Beginner Full Body'),
          });

      // Act
      final future = notifier.setActiveProgram('prog-1');

      // Intermediate: loading
      expect(notifier.state.isLoading, isTrue);

      await future;

      // Assert
      final state = notifier.state;
      expect(state.activeProgramResponse?.program, isNotNull);
      expect(state.activeProgramResponse!.program.id, 'prog-1');
      expect(state.activeProgramResponse!.program.name, 'Beginner Full Body');
      expect(state.isLoading, false);
      expect(state.error, isNull);

      // Verify correct API call
      verify(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: {'programId': 'prog-1'},
          )).called(1);
    });

    // -----------------------------------------------------------------
    // Full flow: fetch programs → activate → verify
    // -----------------------------------------------------------------

    test('full flow: fetchPrograms → setActiveProgram → '
        'routine appears in list', () async {
      // Step 1: Fetch programs (initially empty)
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.fetchPrograms();
      expect(notifier.state.programs, isEmpty);

      // Step 2: Activate a program (save routine)
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _programJson(id: 'prog-1', name: 'Beginner Full Body'),
          });

      await notifier.setActiveProgram('prog-1');
      expect(notifier.state.activeProgramResponse?.program, isNotNull);
      expect(notifier.state.activeProgramResponse!.program.id, 'prog-1');

      // Step 3: Fetch programs again — should include the saved one
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              _programJson(id: 'prog-1', name: 'Beginner Full Body'),
            ],
          });

      await notifier.fetchPrograms();
      expect(notifier.state.programs, hasLength(1));
      expect(notifier.state.programs[0].id, 'prog-1');
      expect(notifier.state.programs[0].name, 'Beginner Full Body');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    // -----------------------------------------------------------------
    // Error handling
    // -----------------------------------------------------------------

    test('fetchPrograms sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientPrograms,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clientPrograms),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.clientPrograms),
          statusCode: 500,
          data: {'error': {'message': 'Server error'}},
        ),
        type: DioExceptionType.badResponse,
      ));

      await notifier.fetchPrograms();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Server error');
      expect(state.programs, isEmpty);
    });

    test('setActiveProgram sets error on failure', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.clientActiveProgram),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.clientActiveProgram),
          statusCode: 500,
          data: {'error': {'message': 'Activation failed'}},
        ),
        type: DioExceptionType.badResponse,
      ));

      await notifier.setActiveProgram('prog-1');

      expect(notifier.state.error, 'Activation failed');
      expect(notifier.state.activeProgramResponse?.program, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('setActiveProgram handles null data in response', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{'data': null});

      await notifier.setActiveProgram('prog-1');

      expect(notifier.state.activeProgramResponse?.program, isNull);
      expect(notifier.state.isLoading, false);
    });

    // -----------------------------------------------------------------
    // clearActiveProgram
    // -----------------------------------------------------------------

    test('clearActiveProgram removes active program', () async {
      // First activate
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _programJson(),
          });
      await notifier.setActiveProgram('prog-1');
      expect(notifier.state.activeProgramResponse?.program, isNotNull);

      // Then clear
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.clientActiveProgram,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.clearActiveProgram();

      expect(notifier.state.activeProgramResponse?.program, isNull);
      expect(notifier.state.isLoading, false);
    });
  });
}
