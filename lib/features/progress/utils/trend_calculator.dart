import 'package:zirofit_fl/data/models/client_analytics.dart';

// ---------------------------------------------------------------------------
// TrendCalculator
// ---------------------------------------------------------------------------
//
// iOS-style two-period trend comparison.
// Given a list of data points and the current period (e.g., 30 days),
// splits into:
//   - Current period: most recent N data points
//   - Previous period: N data points before the current period
// Then calculates percent change: ((current - previous) / previous) * 100

class TrendCalculator {
  /// Calculates volume trend: percent change in total volume.
  ///
  /// Compares total volume in the most recent [days] data points against
  /// the [days] data points before that. Returns [fallback] when there
  /// is insufficient data for a meaningful comparison.
  static double calculateVolumeTrend(
    List<VolumePoint> data,
    double fallback,
    int days,
  ) {
    final (current, previous) = _splitPeriods(data, days);
    if (current.isEmpty || previous.isEmpty) return fallback;

    final currentTotal =
        current.fold<double>(0, (sum, p) => sum + p.volume);
    final previousTotal =
        previous.fold<double>(0, (sum, p) => sum + p.volume);

    return _percentChange(currentTotal, previousTotal);
  }

  /// Calculates frequency trend: percent change in workout count.
  ///
  /// Compares the number of data points in the most recent [days] entries
  /// against the [days] entries before that. Returns [fallback] when there
  /// is insufficient data for a meaningful comparison.
  static double calculateFrequencyTrend(
    List<VolumePoint> data,
    double fallback,
    int days,
  ) {
    final (current, previous) = _splitPeriods(data, days);
    if (current.isEmpty || previous.isEmpty) return fallback;

    return _percentChange(
      current.length.toDouble(),
      previous.length.toDouble(),
    );
  }

  /// Calculates average volume trend: percent change in avg volume per
  /// session. Compares average volume per data point in the most recent
  /// [days] entries against the [days] entries before that. Returns
  /// [fallback] when there is insufficient data for a meaningful comparison.
  static double calculateAvgVolumeTrend(
    List<VolumePoint> data,
    double fallback,
    int days,
  ) {
    final (current, previous) = _splitPeriods(data, days);
    if (current.isEmpty || previous.isEmpty) return fallback;

    final currentAvg =
        current.fold<double>(0, (sum, p) => sum + p.volume) /
            current.length;
    final previousAvg =
        previous.fold<double>(0, (sum, p) => sum + p.volume) /
            previous.length;

    return _percentChange(currentAvg, previousAvg);
  }

  /// Splits [data] into two periods based on [days].
  ///
  /// Returns a record `(currentPeriod, previousPeriod)` where:
  /// - [currentPeriod] = the most recent [days] entries (empty if insufficient)
  /// - [previousPeriod] = the entries before [currentPeriod] (may be partial)
  ///
  /// Data is sorted by date ascending before splitting.
  static (List<VolumePoint> current, List<VolumePoint> previous)
      _splitPeriods(List<VolumePoint> data, int days) {
    if (data.length < days || days <= 0) return ([], []);

    // Sort by date ascending (oldest first)
    final sorted = List<VolumePoint>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    final splitIndex = sorted.length - days;
    final current = sorted.sublist(splitIndex);
    final previous = sorted.sublist(0, splitIndex);

    return (current, previous);
  }

  /// Calculates percent change from [previous] to [current].
  ///
  /// Edge cases:
  /// - previous == 0 && current > 0  → 100.0
  /// - previous == 0 && current == 0 →   0.0
  /// - Otherwise → ((current - previous) / previous) * 100
  static double _percentChange(double current, double previous) {
    if (previous == 0 && current > 0) return 100.0;
    if (previous == 0 && current == 0) return 0.0;
    return ((current - previous) / previous) * 100;
  }
}
