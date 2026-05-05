import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/features/progress/data/analytics_remote_source.dart';
import 'package:zirofit_fl/features/progress/models/analytics_widget_config.dart';
import 'package:zirofit_fl/features/progress/providers/analytics_provider.dart';
import 'package:zirofit_fl/features/progress/providers/goal_provider.dart'
    hide VolumePoint;
import 'package:zirofit_fl/features/progress/providers/widget_config_provider.dart';
import 'package:zirofit_fl/features/progress/screens/progress_screen.dart';
import 'package:zirofit_fl/features/progress/widgets/analytics_skeleton.dart';

class MockAnalyticsRemoteSource extends Mock
    implements AnalyticsRemoteSource {}

class FakeAnalyticsNotifier extends AnalyticsNotifier {
  FakeAnalyticsNotifier()
      : super(remoteSource: MockAnalyticsRemoteSource());

  @override
  Future<void> loadAll({int days = 30}) async {
    // Simulate entering loading state without calling the mock remote source.
    state = state.copyWith(isLoading: true, clearError: true);
  }

  void simulateLoadAllSuccess(
      ClientAnalytics analytics, ClientProgress progress) {
    state = state.copyWith(isLoading: true, clearError: true);
    state = AnalyticsState(analytics: analytics, progress: progress);
  }

  void simulateLoadAllError(String error) {
    state = state.copyWith(isLoading: true, clearError: true);
    state = state.copyWith(isLoading: false, error: error);
  }

  void simulateLoading() {
    state = state.copyWith(isLoading: true, clearError: true);
  }
}

class FakeGoalsNotifier extends GoalsNotifier {
  FakeGoalsNotifier();
}

class FakeWidgetConfigNotifier extends WidgetConfigNotifier {
  FakeWidgetConfigNotifier() {
    state = List.from(AnalyticsWidgetConfig.defaults);
  }
}

ClientAnalytics createTestAnalytics() {
  return ClientAnalytics(
    heatmapDates: ['2025-01-01', '2025-01-02', '2025-01-03'],
    volumeHistory: const [
      VolumePoint(date: '2025-01-01', volume: 1000),
      VolumePoint(date: '2025-01-02', volume: 1200),
      VolumePoint(date: '2025-01-03', volume: 1100),
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
        date: DateTime(2025, 1, 3),
      ),
    ],
    consistency: 80,
  );
}

ClientProgress createTestProgress() {
  final now = DateTime(2025, 1, 1);
  return ClientProgress(
    weight: [MetricPoint(date: now, value: 80)],
    bodyFat: [MetricPoint(date: now, value: 15)],
    volume: const [VolumePoint(date: '2025-01-01', volume: 1000)],
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

extension PumpProgressScreen on WidgetTester {
  Future<void> pumpProgressScreen({
    FakeAnalyticsNotifier? analyticsNotifier,
    FakeGoalsNotifier? goalsNotifier,
    FakeWidgetConfigNotifier? widgetConfigNotifier,
  }) async {
    final analytics = analyticsNotifier ?? FakeAnalyticsNotifier();
    final goals = goalsNotifier ?? FakeGoalsNotifier();
    final widgets = widgetConfigNotifier ?? FakeWidgetConfigNotifier();

    await pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWith((ref) => analytics),
          goalsProvider.overrideWith((ref) => goals),
          widgetConfigProvider.overrideWith((ref) => widgets),
        ],
        child: const MaterialApp(home: PersonalAnalyticsScreen()),
      ),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PersonalAnalyticsScreen', () {
    testWidgets('renders loading skeleton when isLoading and no data',
        (tester) async {
      // Larger viewport needed for AnalyticsSkeleton (overflows at 600h).
      await tester.binding.setSurfaceSize(const Size(800, 1400));

      final notifier = FakeAnalyticsNotifier();
      notifier.simulateLoading();

      await tester.pumpProgressScreen(analyticsNotifier: notifier);

      expect(find.byType(AnalyticsSkeleton), findsOneWidget);
    });

    testWidgets('renders error state with retry button', (tester) async {
      final notifier = FakeAnalyticsNotifier();
      notifier.simulateLoadAllError('Failed to fetch analytics');

      await tester.pumpProgressScreen(analyticsNotifier: notifier);

      expect(find.text('Failed to load analytics'), findsOneWidget);
      expect(find.text('Failed to fetch analytics'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders empty state when idle', (tester) async {
      await tester.pumpProgressScreen();

      expect(find.text('No analytics data yet'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('renders data state without errors', (tester) async {
      // Larger viewport needed for ActivityHeatMapWidget (overflows at 800w).
      await tester.binding.setSurfaceSize(const Size(1200, 1400));

      final notifier = FakeAnalyticsNotifier();
      notifier.simulateLoadAllSuccess(
        createTestAnalytics(),
        createTestProgress(),
      );

      await tester.pumpProgressScreen(analyticsNotifier: notifier);

      expect(find.byType(PersonalAnalyticsScreen), findsOneWidget);
    });

    testWidgets('does not throw provider modification error when mounted',
        (tester) async {
      // Larger viewport needed (postFrameCallback transitions to loading,
      // which renders AnalyticsSkeleton that overflows at 600h).
      await tester.binding.setSurfaceSize(const Size(800, 1400));

      await tester.pumpProgressScreen();
      await tester.pump();

      expect(find.byType(PersonalAnalyticsScreen), findsOneWidget);
    });

    testWidgets('renders app bar with correct title and actions',
        (tester) async {
      await tester.pumpProgressScreen();

      expect(find.text('Analytics'), findsOneWidget);
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
    });

    testWidgets('retry button triggers reload in error state',
        (tester) async {
      // Larger viewport needed (retry transitions to loading, rendering the
      // AnalyticsSkeleton which overflows at 600h).
      await tester.binding.setSurfaceSize(const Size(800, 1400));

      final notifier = FakeAnalyticsNotifier();
      notifier.simulateLoadAllError('Connection error');

      await tester.pumpProgressScreen(analyticsNotifier: notifier);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(notifier.state.isLoading, isTrue);
    });

    testWidgets('refresh button triggers reload in empty state',
        (tester) async {
      // Larger viewport needed (refresh transitions to loading, rendering the
      // AnalyticsSkeleton which overflows at 600h).
      await tester.binding.setSurfaceSize(const Size(800, 1400));

      final notifier = FakeAnalyticsNotifier();

      await tester.pumpProgressScreen(analyticsNotifier: notifier);
      await tester.pump();
      notifier.reset();

      await tester.pump();
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pump();

      expect(notifier.state.isLoading, isTrue);
    });
  });
}
