import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/check_in.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class CheckInGroup {
  final DateTime date;
  final List<CheckIn> checkIns;

  const CheckInGroup({
    required this.date,
    required this.checkIns,
  });

  @override
  String toString() =>
      'CheckInGroup(date: ${date.toIso8601String()}, checkIns: ${checkIns.length})';
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CheckInHistoryState {
  final List<CheckInGroup> groups;
  final bool isLoading;
  final String? error;

  const CheckInHistoryState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  CheckInHistoryState copyWith({
    List<CheckInGroup>? groups,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CheckInHistoryState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CheckInHistoryNotifier extends StateNotifier<CheckInHistoryState> {
  final ApiClient _api;

  CheckInHistoryNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const CheckInHistoryState(isLoading: true));

  /// GET /api/client/check-ins
  /// Fetches the client's check-in history and groups it by date.
  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.clientCheckIns,
      );

      final rawList = result['data'] as List<dynamic>? ?? [];
      final checkIns = rawList
          .map((e) => CheckIn.fromJson(e as Map<String, dynamic>))
          .toList();

      final groups = CheckInHistoryNotifier.groupByDate(checkIns);

      state = state.copyWith(
        groups: groups,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Pull-to-refresh — re-fetches the full history.
  Future<void> refresh() => fetchHistory();

  // ---------------------------------------------------------------------------
  // Grouping logic
  // ---------------------------------------------------------------------------

  /// Groups a list of [CheckIn]s by their calendar date and returns
  /// [CheckInGroup]s sorted by date descending (most recent first).
  static List<CheckInGroup> groupByDate(List<CheckIn> checkIns) {
    final Map<int, List<CheckIn>> grouped = {};

    for (final ci in checkIns) {
      // Normalise to start of day (local time)
      final dayStart = DateTime(ci.date.year, ci.date.month, ci.date.day);
      final key = dayStart.millisecondsSinceEpoch;
      grouped.putIfAbsent(key, () => []).add(ci);
    }

    // Sort keys descending (most recent first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((key) {
      final date = DateTime.fromMillisecondsSinceEpoch(key);
      return CheckInGroup(date: date, checkIns: grouped[key]!);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Error helpers
  // ---------------------------------------------------------------------------

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
      return 'Something went wrong. Please try again.';
    }
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final checkInHistoryProvider =
    StateNotifierProvider<CheckInHistoryNotifier, CheckInHistoryState>((ref) {
  return CheckInHistoryNotifier();
});
