import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/features/progress/data/analytics_remote_source.dart';
import 'package:zirofit_fl/features/progress/providers/analytics_provider.dart';

class MockAnalyticsRemoteSource extends Mock implements AnalyticsRemoteSource {}

void main() {
  late MockAnalyticsRemoteSource mockRemoteSource;
  late AnalyticsNotifier notifier;

  setUp(() {
    mockRemoteSource = MockAnalyticsRemoteSource();
    notifier = AnalyticsNotifier(remoteSource: mockRemoteSource);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ClientAnalytics createAnalytics({int consistency = 75}) {
    final now = DateTime(2024, 1, 15);
    return ClientAnalytics(
      heatmapDates: ['2024-01-01', '2024-01-02'],
      volumeHistory: const [
        VolumePoint(date: '2024-01-01', volume: 1000),
        VolumePoint(date: '2024-01-02', volume: 1200),
      ],
      muscleDistribution: const [
        MusclePoint(muscle: 'Chest', count: 5),
        MusclePoint(muscle: 'Back', count: 3),
      ],
      recentPRs: [
        AnalyticsPersonalRecord(
          exercise: 'Bench Press',
          value: 100,
          type: 'weight',
          date: now,
        ),
      ],
      consistency: consistency,
    );
  }

  ClientProgress createProgress() {
    final now = DateTime(2024, 1, 15);
    return ClientProgress(
      weight: [
        MetricPoint(date: now, value: 80),
      ],
      bodyFat: [
        MetricPoint(date: now, value: 15),
      ],
      volume: const [
        VolumePoint(date: '2024-01-01', volume: 1000),
      ],
      exercisePerformance: const [
        ExercisePerformance(exercise: 'Bench Press', averageWeight: 80),
      ],
      favoriteExercises: const [
        FavoriteExercise(exercise: 'Bench Press', count: 10),
      ],
      worstPerformingExercises: const [
        WorstExercise(exercise: 'Deadlift', averageWeight: 60),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('AnalyticsNotifier', () {
    test('initial state: isLoading=false, analytics=null, error=null', () {
      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.analytics, isNull);
      expect(state.progress, isNull);
      expect(state.error, isNull);
      expect(state.isIdle, true);
    });

    group('loadAnalytics', () {
      test('sets loading then analytics on success', () async {
        final analytics = createAnalytics();
        when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
            .thenAnswer((_) async => analytics);

        final future = notifier.loadAnalytics();
        // Intermediate loading state
        expect(notifier.state.isLoading, true);

        await future;

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.analytics, analytics);
        expect(state.error, isNull);
      });

      test('sets error on API failure', () async {
        when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
            .thenThrow(Exception('Failed to load analytics'));

        await notifier.loadAnalytics();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.analytics, isNull);
        expect(state.error, contains('Failed to load analytics'));
      });
    });

    group('loadProgress', () {
      test('sets loading then progress on success', () async {
        final progress = createProgress();
        when(() => mockRemoteSource.fetchProgress())
            .thenAnswer((_) async => progress);

        final future = notifier.loadProgress();
        // Intermediate loading state
        expect(notifier.state.isLoading, true);

        await future;

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.progress, progress);
        expect(state.error, isNull);
      });

      test('sets error on API failure', () async {
        when(() => mockRemoteSource.fetchProgress())
            .thenThrow(Exception('Failed to load progress'));

        await notifier.loadProgress();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.progress, isNull);
        expect(state.error, contains('Failed to load progress'));
      });
    });

    group('loadAll', () {
      test('loads both analytics and progress on success', () async {
        final analytics = createAnalytics();
        final progress = createProgress();
        when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
            .thenAnswer((_) async => analytics);
        when(() => mockRemoteSource.fetchProgress())
            .thenAnswer((_) async => progress);

        final future = notifier.loadAll();
        expect(notifier.state.isLoading, true);

        await future;

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.analytics, analytics);
        expect(state.progress, progress);
        expect(state.error, isNull);
      });

      test('sets error on API failure', () async {
        when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
            .thenAnswer((_) async => createAnalytics());
        when(() => mockRemoteSource.fetchProgress())
            .thenThrow(Exception('Failed to load progress'));

        await notifier.loadAll();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.error, contains('Failed to load progress'));
      });
    });

    group('clearError', () {
      test('clears the error message', () async {
        when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
            .thenThrow(Exception('Some error'));
        await notifier.loadAnalytics();
        expect(notifier.state.error, contains('Some error'));

        notifier.clearError();

        expect(notifier.state.error, isNull);
      });
    });

    group('reset', () {
      test('resets state to idle', () async {
        final analytics = createAnalytics();
        when(() => mockRemoteSource.fetchAnalytics(days: any(named: 'days')))
            .thenAnswer((_) async => analytics);
        await notifier.loadAnalytics();
        expect(notifier.state.analytics, isNotNull);

        notifier.reset();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.analytics, isNull);
        expect(state.progress, isNull);
        expect(state.error, isNull);
        expect(state.isIdle, true);
      });
    });

    group('copyWith', () {
      test('clearError resets error without affecting other fields', () {
        final state = AnalyticsState(
          analytics: createAnalytics(),
          error: 'some error',
        );
        final updated = state.copyWith(clearError: true);
        expect(updated.analytics, state.analytics);
        expect(updated.error, isNull);
      });
    });
  });
}
