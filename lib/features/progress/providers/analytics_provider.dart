import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/features/progress/data/analytics_remote_source.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final remoteSource = ref.watch(analyticsRemoteSourceProvider);
  return AnalyticsNotifier(remoteSource: remoteSource);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AnalyticsState {
  final ClientAnalytics? analytics;
  final ClientProgress? progress;
  final bool isLoading;
  final String? error;

  const AnalyticsState({
    this.analytics,
    this.progress,
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith({
    ClientAnalytics? analytics,
    ClientProgress? progress,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AnalyticsState(
      analytics: analytics ?? this.analytics,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasData => analytics != null || progress != null;
  bool get isIdle => !isLoading && !hasData && error == null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsRemoteSource _remoteSource;

  AnalyticsNotifier({required AnalyticsRemoteSource remoteSource})
      : _remoteSource = remoteSource,
        super(const AnalyticsState());

  /// GET /api/client/analytics?days=30
  /// Loads analytics data (heatmap, volume, muscle distribution, PRs, consistency).
  Future<void> loadAnalytics({int days = 30}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final analytics = await _remoteSource.fetchAnalytics(days: days);
      state = state.copyWith(
        analytics: analytics,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// GET /api/client/progress
  /// Loads progress data (weight, body fat, volume, exercise performance).
  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final progress = await _remoteSource.fetchProgress();
      state = state.copyWith(
        progress: progress,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// GET /api/client/analytics + /api/client/progress
  /// Convenience method to load both analytics and progress data.
  Future<void> loadAll({int days = 30}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _remoteSource.fetchAnalytics(days: days),
        _remoteSource.fetchProgress(),
      ]);
      state = AnalyticsState(
        analytics: results[0] as ClientAnalytics,
        progress: results[1] as ClientProgress,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clears any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Resets to idle state.
  void reset() {
    state = const AnalyticsState();
  }
}
