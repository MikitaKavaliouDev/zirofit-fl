import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/daily_habit.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class HabitsState {
  final List<DailyHabit> habits;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  const HabitsState({
    this.habits = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  HabitsState copyWith({
    List<DailyHabit>? habits,
    bool? isLoading,
    String? error,
    bool? isSaving,
    bool clearError = false,
  }) {
    return HabitsState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, HabitsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HabitsNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class HabitsNotifier extends StateNotifier<HabitsState> {
  final ApiClient _apiClient;

  HabitsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const HabitsState());

  /// Fetches the client's daily habits.
  Future<void> fetchHabits() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> data = await _apiClient.get(
        ApiConstants.clientHabits,
      );

      final List<dynamic> rawList = (data['data'] as List?) ?? [];

      final habits = rawList
          .map((e) => DailyHabit.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        habits: habits,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Logs a habit completion or skip for [habitId] on [date].
  Future<void> logHabit(
    String habitId,
    DateTime date,
    bool isCompleted, {
    String? note,
  }) async {
    state = state.copyWith(isSaving: true);

    try {
      final Map<String, dynamic> _ = await _apiClient.post(
        ApiConstants.logHabit(habitId),
        body: {
          'date': date.toIso8601String().split('T')[0],
          'isCompleted': isCompleted,
          'note': ?note,
        },
      );

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
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
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}
