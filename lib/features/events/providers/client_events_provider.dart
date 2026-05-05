import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClientEventsState {
  final List<Event> bookedEvents;
  final bool isLoading;
  final String? error;
  final bool joinSuccess;

  const ClientEventsState({
    this.bookedEvents = const [],
    this.isLoading = false,
    this.error,
    this.joinSuccess = false,
  });

  ClientEventsState copyWith({
    List<Event>? bookedEvents,
    bool? isLoading,
    String? error,
    bool? joinSuccess,
    bool clearError = false,
  }) {
    return ClientEventsState(
      bookedEvents: bookedEvents ?? this.bookedEvents,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      joinSuccess: joinSuccess ?? this.joinSuccess,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final clientEventsProvider =
    StateNotifierProvider<ClientEventsNotifier, ClientEventsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClientEventsNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ClientEventsNotifier extends StateNotifier<ClientEventsState> {
  final ApiClient _apiClient;

  /// Maps event ID → booking ID for booked events.
  final Map<String, String> _bookingIds = {};

  ClientEventsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const ClientEventsState());

  /// Returns the booking ID for a given [eventId], if available.
  String? getBookingId(String eventId) => _bookingIds[eventId];

  /// Fetches the client's booked events from GET /api/client/events.
  Future<void> fetchBookedEvents() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> data = await _apiClient.get(
        ApiConstants.clientEvents,
      );

      final List<dynamic> rawList = (data['data'] as List?) ?? [];

      final List<Event> events = [];
      _bookingIds.clear();

      for (final item in rawList) {
        final json = item as Map<String, dynamic>;
        events.add(Event.fromJson(json));

        // Extract booking ID if present in the response
        final bookingId = json['booking_id'] as String?;
        if (bookingId != null && json['id'] is String) {
          _bookingIds[json['id'] as String] = bookingId;
        }
      }

      state = state.copyWith(
        bookedEvents: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Joins an event by [eventId] via POST /api/events/[id]/join.
  /// Returns `true` on success, `false` on failure.
  Future<bool> joinEvent(String eventId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> responseData = await _apiClient.post(
        ApiConstants.eventJoin(eventId),
      );

      // Extract booking ID from the join response if present
      final bookingId = responseData['booking_id'] as String?;
      if (bookingId != null) {
        _bookingIds[eventId] = bookingId;
      }

      state = state.copyWith(
        isLoading: false,
        joinSuccess: true,
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

  /// Cancels a booking by [bookingId] via PUT /api/client/events/[bookingId]/cancel.
  /// Returns `true` on success, `false` on failure.
  Future<bool> cancelBooking(String bookingId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.put(
        ApiConstants.clientEventCancel(bookingId),
      );

      // Remove the cancelled booking from the local state
      final eventIdsToRemove = <String>[];
      for (final entry in _bookingIds.entries) {
        if (entry.value == bookingId) {
          eventIdsToRemove.add(entry.key);
        }
      }

      for (final eventId in eventIdsToRemove) {
        _bookingIds.remove(eventId);
      }

      state = state.copyWith(
        bookedEvents: state.bookedEvents
            .where((e) => !eventIdsToRemove.contains(e.id))
            .toList(),
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
