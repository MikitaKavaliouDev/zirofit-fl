import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';

// =============================================================================
// SessionHistoryData — display model wrapping a WorkoutSession with computed
// volume & sets (returned by the backend when querying with pagination).
// =============================================================================

class SessionHistoryData {
  final WorkoutSession session;
  final double totalVolume;
  final int totalSets;

  const SessionHistoryData({
    required this.session,
    this.totalVolume = 0,
    this.totalSets = 0,
  });

  factory SessionHistoryData.fromJson(Map<String, dynamic> json) {
    final session = WorkoutSession.fromJson(json);
    return SessionHistoryData(
      session: session,
      totalVolume: (json['totalVolume'] as num? ?? 0).toDouble(),
      totalSets: json['totalSets'] as int? ?? 0,
    );
  }

  String get id => session.id;
  DateTime get startTime => session.startTime;
  DateTime? get endTime => session.endTime;
  String get name => session.name ?? 'Workout Session';
  WorkoutSessionStatus get status => session.status;
}

// =============================================================================
// Date range filter
// =============================================================================

enum HistoryDateRange { oneMonth, threeMonths, sixMonths, oneYear, all }

extension HistoryDateRangeLabel on HistoryDateRange {
  String get label {
    switch (this) {
      case HistoryDateRange.oneMonth:
        return '1M';
      case HistoryDateRange.threeMonths:
        return '3M';
      case HistoryDateRange.sixMonths:
        return '6M';
      case HistoryDateRange.oneYear:
        return '1Y';
      case HistoryDateRange.all:
        return 'ALL';
    }
  }
}

// =============================================================================
// State
// =============================================================================

class ClientHistoryState {
  final List<SessionHistoryData> sessions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final HistoryDateRange dateRange;
  final int page;
  final bool hasMore;

  const ClientHistoryState({
    this.sessions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.dateRange = HistoryDateRange.all,
    this.page = 1,
    this.hasMore = true,
  });

  ClientHistoryState copyWith({
    List<SessionHistoryData>? sessions,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    HistoryDateRange? dateRange,
    int? page,
    bool? hasMore,
  }) {
    return ClientHistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      dateRange: dateRange ?? this.dateRange,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Computed volume data for the chart, grouped by day, sorted ascending.
  List<VolumePoint> get volumeData {
    if (sessions.isEmpty) return [];

    final daily = <String, double>{};
    for (final s in sessions) {
      final dayKey =
          '${s.startTime.year}-${s.startTime.month.toString().padLeft(2, '0')}-${s.startTime.day.toString().padLeft(2, '0')}';
      daily.update(dayKey, (v) => v + s.totalVolume, ifAbsent: () => s.totalVolume);
    }

    final entries = daily.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries.map((e) => VolumePoint(date: e.key, volume: e.value)).toList();
  }
}

// =============================================================================
// Notifier
// =============================================================================

class ClientHistoryNotifier extends StateNotifier<ClientHistoryState> {
  final ApiClient _apiClient;
  final String clientId;
  static const int _perPage = 20;

  ClientHistoryNotifier({
    required ApiClient apiClient,
    required this.clientId,
  })  : _apiClient = apiClient,
        super(const ClientHistoryState());

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Fetches the first page of sessions (replaces existing data).
  Future<void> fetchHistory({HistoryDateRange? dateRange}) async {
    final range = dateRange ?? state.dateRange;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: 1,
      dateRange: range,
      sessions: [],
    );

    try {
      final queryParams = <String, dynamic>{
        'page': 1,
        'per_page': _perPage,
      };
      _applyDateRange(range, queryParams);

      final response = await _apiClient.get(
        '${ApiConstants.clients}/$clientId/sessions',
        queryParams: queryParams,
      );

      final parsed = _parseResponse(response);
      final hasMore = parsed.length >= _perPage;

      state = state.copyWith(
        sessions: parsed,
        isLoading: false,
        page: 1,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Loads the next page and appends results.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{
        'page': nextPage,
        'per_page': _perPage,
      };
      _applyDateRange(state.dateRange, queryParams);

      final response = await _apiClient.get(
        '${ApiConstants.clients}/$clientId/sessions',
        queryParams: queryParams,
      );

      final parsed = _parseResponse(response);
      final hasMore = parsed.length >= _perPage;

      state = state.copyWith(
        sessions: [...state.sessions, ...parsed],
        isLoadingMore: false,
        page: nextPage,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Changes the date range and re-fetches from page 1.
  void setDateRange(HistoryDateRange range) {
    if (range == state.dateRange) return;
    fetchHistory(dateRange: range);
  }

  /// Pull-to-refresh: re-fetches the first page.
  Future<void> refresh() => fetchHistory();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<SessionHistoryData> _parseResponse(dynamic response) {
    final data = response['data'];
    final rawList = data is Map ? data['sessions'] : data;

    if (rawList is List) {
      return rawList
          .map((e) => SessionHistoryData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  void _applyDateRange(HistoryDateRange range, Map<String, dynamic> params) {
    if (range == HistoryDateRange.all) return;

    final now = DateTime.now();
    DateTime? from;

    switch (range) {
      case HistoryDateRange.oneMonth:
        from = now.subtract(const Duration(days: 30));
      case HistoryDateRange.threeMonths:
        from = now.subtract(const Duration(days: 90));
      case HistoryDateRange.sixMonths:
        from = now.subtract(const Duration(days: 180));
      case HistoryDateRange.oneYear:
        from = now.subtract(const Duration(days: 365));
      case HistoryDateRange.all:
        return;
    }

    params['start_date'] = from!.toIso8601String().split('T')[0];
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final errorData = error.response!.data as Map;
        if (errorData['error'] is Map) {
          return (errorData['error'] as Map)['message'] as String? ??
              'An error occurred';
        }
        if (errorData['message'] is String) {
          return errorData['message'] as String;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

// =============================================================================
// Provider (family by clientId)
// =============================================================================

final clientHistoryProvider = StateNotifierProvider.family<
    ClientHistoryNotifier, ClientHistoryState, String>(
  (ref, clientId) {
    final apiClient = ApiClient.instance;
    return ClientHistoryNotifier(apiClient: apiClient, clientId: clientId);
  },
);
