import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrainerEventsState {
  final List<Event> events;
  final bool isLoading;
  final String? error;

  const TrainerEventsState({
    this.events = const [],
    this.isLoading = false,
    this.error,
  });

  TrainerEventsState copyWith({
    List<Event>? events,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrainerEventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final trainerEventsProvider =
    StateNotifierProvider<TrainerEventsNotifier, TrainerEventsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainerEventsNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerEventsNotifier extends StateNotifier<TrainerEventsState> {
  final ApiClient _apiClient;

  TrainerEventsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerEventsState());

  /// Fetches the trainer's own events.
  Future<void> fetchEvents() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> data = await _apiClient.get(
        ApiConstants.trainerEvents,
      );

      final List<dynamic> rawList = (data['data'] as List?) ?? [];

      final events = rawList
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        events: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Creates a new event from the given [data] map.
  Future<bool> createEvent(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> responseData = await _apiClient.post(
        ApiConstants.trainerEvents,
        body: data,
      );

      final newEvent = Event.fromJson(
        (responseData['data'] as Map<String, dynamic>?) ?? responseData,
      );

      state = state.copyWith(
        events: [newEvent, ...state.events],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  /// Refreshes the list.
  Future<void> refresh() async {
    await fetchEvents();
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
