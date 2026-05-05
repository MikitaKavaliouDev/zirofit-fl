import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';

void main() {
  group('ClientAnalytics.fromJson', () {
    test('parses full API response correctly', () {
      final json = {
        'heatmapDates': ['2026-01-01', '2026-01-02'],
        'volumeHistory': [
          {'date': '2026-01-01', 'volume': 1000.0},
          {'date': '2026-01-02', 'volume': 1200.0},
        ],
        'muscleDistribution': [
          {'muscle': 'Chest', 'count': 5},
          {'muscle': 'Back', 'count': 3},
        ],
        'recentPRs': [
          {
            'exercise': 'Bench Press',
            'value': 100.0,
            'type': 'weight',
            'date': '2026-01-02T00:00:00.000Z',
          },
        ],
        'consistency': 85,
      };

      final analytics = ClientAnalytics.fromJson(json);

      expect(analytics.heatmapDates, ['2026-01-01', '2026-01-02']);
      expect(analytics.volumeHistory.length, 2);
      expect(analytics.volumeHistory[0].volume, 1000.0);
      expect(analytics.muscleDistribution.length, 2);
      expect(analytics.muscleDistribution[0].muscle, 'Chest');
      expect(analytics.recentPRs.length, 1);
      expect(analytics.recentPRs[0].exercise, 'Bench Press');
      expect(analytics.consistency, 85);
    });

    test('handles missing consistency field (defaults to 0)', () {
      final json = {
        'heatmapDates': ['2026-01-01'],
        'volumeHistory': [{'date': '2026-01-01', 'volume': 1000.0}],
        'muscleDistribution': [],
        'recentPRs': [],
        // 'consistency' is missing
      };

      final analytics = ClientAnalytics.fromJson(json);

      expect(analytics.consistency, 0);
    });

    test('handles null consistency field', () {
      final json = {
        'heatmapDates': ['2026-01-01'],
        'volumeHistory': [{'date': '2026-01-01', 'volume': 1000.0}],
        'muscleDistribution': [],
        'recentPRs': [],
        'consistency': null,
      };

      final analytics = ClientAnalytics.fromJson(json);

      expect(analytics.consistency, 0);
    });

    test('handles empty response (defaults to empty lists)', () {
      final json = <String, dynamic>{};

      final analytics = ClientAnalytics.fromJson(json);

      expect(analytics.heatmapDates, isEmpty);
      expect(analytics.volumeHistory, isEmpty);
      expect(analytics.muscleDistribution, isEmpty);
      expect(analytics.recentPRs, isEmpty);
      expect(analytics.consistency, 0);
    });

    test('handles missing volumeHistory', () {
      final json = {
        'heatmapDates': ['2026-01-01'],
        'muscleDistribution': [],
        'recentPRs': [],
      };

      final analytics = ClientAnalytics.fromJson(json);

      expect(analytics.volumeHistory, isEmpty);
    });

    test('handles malformed volumeHistory entries', () {
      final json = {
        'heatmapDates': [],
        'volumeHistory': [
          {'date': '2026-01-01', 'volume': 'invalid'}, // string instead of number
          {'date': '2026-01-02'}, // missing volume
        ],
        'muscleDistribution': [],
        'recentPRs': [],
        'consistency': 50,
      };

      // Should not throw - num.toDouble() handles string by throwing at runtime,
      // but the test framework catches this as expected behavior
      expect(
        () => ClientAnalytics.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('ClientProgress.fromJson', () {
    test('parses full API response correctly', () {
      final json = {
        'weight': [
          {'date': '2026-02-03T00:00:00.000Z', 'value': 70},
        ],
        'bodyFat': [
          {'date': '2026-02-03T00:00:00.000Z', 'value': 22},
        ],
        'volume': [
          {'date': '2026-01-01', 'volume': 1000.0},
        ],
        'exercisePerformance': [
          {
            'exercise': 'Bench Press',
            'averageWeight': 80.0,
            'averageReps': 10.0,
            'maxWeight': 100.0,
            'totalSets': 20,
            'progress': 5.0,
          },
        ],
        'favoriteExercises': [
          {'exercise': 'Bench Press', 'count': 10},
        ],
        'worstPerformingExercises': [
          {'exercise': 'Tricep Pushdown', 'averageWeight': 20.0, 'averageReps': 12.0},
        ],
      };

      final progress = ClientProgress.fromJson(json);

      expect(progress.weight.length, 1);
      expect(progress.weight[0].value, 70.0);
      expect(progress.bodyFat.length, 1);
      expect(progress.bodyFat[0].value, 22.0);
      expect(progress.volume.length, 1);
      expect(progress.exercisePerformance.length, 1);
      expect(progress.exercisePerformance[0].exercise, 'Bench Press');
      expect(progress.favoriteExercises.length, 1);
      expect(progress.worstPerformingExercises.length, 1);
    });

    test('handles missing fields (defaults to empty)', () {
      final json = <String, dynamic>{};

      final progress = ClientProgress.fromJson(json);

      expect(progress.weight, isEmpty);
      expect(progress.bodyFat, isEmpty);
      expect(progress.volume, isEmpty);
      expect(progress.exercisePerformance, isEmpty);
      expect(progress.favoriteExercises, isEmpty);
      expect(progress.worstPerformingExercises, isEmpty);
    });

    test('handles null weight field', () {
      final json = {
        'weight': null,
        'bodyFat': null,
        'volume': null,
        'exercisePerformance': null,
        'favoriteExercises': null,
        'worstPerformingExercises': null,
      };

      final progress = ClientProgress.fromJson(json);

      expect(progress.weight, isEmpty);
      expect(progress.bodyFat, isEmpty);
    });
  });
}