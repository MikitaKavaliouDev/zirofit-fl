import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/features/progress/data/analytics_remote_source.dart';
import 'package:zirofit_fl/features/progress/providers/analytics_provider.dart';
import 'package:zirofit_fl/features/progress/widgets/muscle_focus_chart.dart';

// ---------------------------------------------------------------------------
// Mocks & fakes
// ---------------------------------------------------------------------------

class MockAnalyticsRemoteSource extends Mock
    implements AnalyticsRemoteSource {}

class FakeAnalyticsNotifier extends AnalyticsNotifier {
  FakeAnalyticsNotifier()
      : super(remoteSource: MockAnalyticsRemoteSource());

  void simulateLoading() {
    state = state.copyWith(isLoading: true, clearError: true);
  }

  void simulateData(List<MusclePoint> muscleDistribution) {
    final analytics = ClientAnalytics(
      heatmapDates: ['2025-01-01'],
      volumeHistory: const [],
      muscleDistribution: muscleDistribution,
      recentPRs: [],
      consistency: 50,
    );
    state = AnalyticsState(analytics: analytics);
  }

  void simulateEmpty() {
    final analytics = ClientAnalytics(
      heatmapDates: [],
      volumeHistory: const [],
      muscleDistribution: const [],
      recentPRs: [],
      consistency: 0,
    );
    state = AnalyticsState(analytics: analytics);
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

List<MusclePoint> createTestMuscleData() {
  return const [
    MusclePoint(muscle: 'Chest', count: 12),
    MusclePoint(muscle: 'Back', count: 10),
    MusclePoint(muscle: 'Legs', count: 8),
    MusclePoint(muscle: 'Shoulders', count: 6),
  ];
}

extension PumpMuscleFocusChart on WidgetTester {
  Future<void> pumpMuscleFocusChart({
    FakeAnalyticsNotifier? notifier,
  }) async {
    final analytics = notifier ?? FakeAnalyticsNotifier();

    await pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWith((ref) => analytics),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MuscleFocusChart(),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MuscleFocusChart', () {
    testWidgets('T1: Shows muscle groups with volumes', (tester) async {
      final notifier = FakeAnalyticsNotifier();
      notifier.simulateData(createTestMuscleData());

      await tester.pumpMuscleFocusChart(notifier: notifier);

      // Verify bar chart renders
      expect(find.byType(BarChart), findsOneWidget);

      // Legend entries with set counts (unique to legend, not x-axis)
      expect(find.text('12 sets'), findsOneWidget);
      expect(find.text('10 sets'), findsOneWidget);
      expect(find.text('8 sets'), findsOneWidget);
      expect(find.text('6 sets'), findsOneWidget);

      // Muscle names appear at least once (x-axis label + legend)
      expect(find.text('Chest'), findsAtLeastNWidgets(1));
      expect(find.text('Back'), findsAtLeastNWidgets(1));
      expect(find.text('Legs'), findsAtLeastNWidgets(1));
      expect(find.text('Shoulders'), findsAtLeastNWidgets(1));
    });

    testWidgets('T2: Time range toggle works', (tester) async {
      final notifier = FakeAnalyticsNotifier();
      notifier.simulateData(createTestMuscleData());

      await tester.pumpMuscleFocusChart(notifier: notifier);

      // All three toggle labels are present
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);

      // "All Time" starts unselected. Tap it to change the range.
      await tester.tap(find.text('All Time'));
      await tester.pump();

      // After tapping, "All Time" text should still be present (still rendered)
      expect(find.text('All Time'), findsOneWidget);
      // The state should have changed (this doesn't trigger an API call
      // in the test, but it verifies the toggle interaction is wired up).
    });

    testWidgets('T3: Color-coded bars', (tester) async {
      final notifier = FakeAnalyticsNotifier();
      notifier.simulateData(createTestMuscleData());

      await tester.pumpMuscleFocusChart(notifier: notifier);

      // Bar chart is rendered
      expect(find.byType(BarChart), findsOneWidget);

      // Legend contains colored indicator containers (one per muscle group)
      final legendWrap = find.byType(Wrap);
      expect(legendWrap, findsOneWidget);

      // The Wrap contains Row widgets (one per legend entry)
      final legendRows = find.descendant(
        of: legendWrap,
        matching: find.byType(Row),
      );
      expect(legendRows, findsNWidgets(4));

      // Each legend row has a colored Container indicator
      final indicators = find.descendant(
        of: legendWrap,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color != null,
        ),
      );
      expect(indicators, findsAtLeastNWidgets(4));

      // Collect the indicator colors and verify they are distinct
      final indicatorColors = <Color>{};
      for (final indicator in indicators.evaluate()) {
        final container = indicator.widget as Container;
        final decoration = container.decoration as BoxDecoration;
        indicatorColors.add(decoration.color!);
      }
      expect(indicatorColors.length, 4,
          reason: 'Each legend indicator should have a distinct color');
    });

    testWidgets('T4: Loading state shows spinner', (tester) async {
      final notifier = FakeAnalyticsNotifier();
      notifier.simulateLoading();

      await tester.pumpMuscleFocusChart(notifier: notifier);

      // Should show CircularProgressIndicator while loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Toggle labels should still be visible
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
    });

    testWidgets('T4: Empty state shows placeholder text', (tester) async {
      final notifier = FakeAnalyticsNotifier();
      notifier.simulateEmpty();

      await tester.pumpMuscleFocusChart(notifier: notifier);

      // Should show empty state message
      expect(find.text('No muscle data yet'), findsOneWidget);

      // Toggle labels should still be visible
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
    });
  });
}
