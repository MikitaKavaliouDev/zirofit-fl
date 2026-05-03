import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class EventsState {
  final List<Event> events;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const EventsState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  EventsState copyWith({
    List<Event>? events,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    bool clearError = false,
  }) {
    return EventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final eventsProvider =
    StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventsNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class EventsNotifier extends StateNotifier<EventsState> {
  final ApiClient _apiClient;

  EventsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const EventsState());

  /// Fetches events with optional [page] and [category] filter.
  /// Appends to existing list when loading subsequent pages.
  Future<void> fetchEvents({int? page, String? category}) async {
    final targetPage = page ?? state.currentPage;
    final isFreshLoad = targetPage == 1;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{
        'page': targetPage,
      };
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final Map<String, dynamic> data = await _apiClient.get(
        ApiConstants.events,
        queryParams: queryParams,
      );

      final List<dynamic> rawList = (data['data'] as List?) ?? [];
      final hasMore = (data['hasMore'] as bool?) ?? false;

      final events = rawList
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        events: isFreshLoad ? events : [...state.events, ...events],
        isLoading: false,
        hasMore: hasMore,
        currentPage: targetPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Loads the next page of events.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await fetchEvents(page: state.currentPage + 1);
  }

  /// Refreshes from page 1.
  Future<void> refresh() async {
    await fetchEvents(page: 1);
  }

  /// Joins an event by [eventId].
  Future<bool> joinEvent(String eventId) async {
    try {
      final Map<String, dynamic> _ = await _apiClient.post(
        ApiConstants.eventJoin(eventId),
      );
      // Optimistically update enrolled count
      state = state.copyWith(
        events: state.events.map((e) {
          if (e.id == eventId) {
            return Event(
              id: e.id,
              trainerId: e.trainerId,
              title: e.title,
              description: e.description,
              startTime: e.startTime,
              endTime: e.endTime,
              locationName: e.locationName,
              address: e.address,
              city: e.city,
              latitude: e.latitude,
              longitude: e.longitude,
              price: e.price,
              currency: e.currency,
              capacity: e.capacity,
              enrolledCount: e.enrolledCount + 1,
              category: e.category,
              imageUrl: e.imageUrl,
              isPromoted: e.isPromoted,
              status: e.status,
              rejectionReason: e.rejectionReason,
              createdAt: e.createdAt,
              updatedAt: e.updatedAt,
            );
          }
          return e;
        }).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
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
