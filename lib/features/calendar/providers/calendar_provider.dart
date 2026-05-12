import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Calendar View Mode
// ---------------------------------------------------------------------------

/// The display mode of the calendar.
enum CalendarViewMode {
  month,
  day,
  agenda,
}

// ---------------------------------------------------------------------------
// Calendar Event (union of Booking & WorkoutSession for display)
// ---------------------------------------------------------------------------

/// A unified event type for calendar display.
/// Can represent either a Booking or a WorkoutSession.
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String type; // 'booking' or 'session'
  final String? clientId;
  final String? clientName;
  final String? clientAvatarUrl;
  final String status;
  final String? notes;
  final Booking? booking;
  final WorkoutSession? session;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.clientId,
    this.clientName,
    this.clientAvatarUrl,
    required this.status,
    this.notes,
    this.booking,
    this.session,
  });

  /// Parses an event from the unified /api/trainer/calendar response.
  /// The API returns `data.events[]` with fields:
  ///   id, title, start, end, type, clientId, clientName, clientAvatarUrl, notes
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final apiType = json['type'] as String? ?? '';
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Event',
      startTime: DateTime.parse(json['start'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : DateTime.parse(json['end'] as String),
      type: _mapEventType(apiType),
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String?,
      clientAvatarUrl: json['clientAvatarUrl'] as String?,
      status: _deriveStatus(apiType),
      notes: json['notes'] as String?,
    );
  }

  factory CalendarEvent.fromBooking(Booking booking) {
    return CalendarEvent(
      id: booking.id,
      title: booking.clientName ?? 'Booking',
      startTime: booking.startTime,
      endTime: booking.endTime,
      type: 'booking',
      clientId: booking.clientId,
      clientName: booking.clientName,
      status: booking.status.toJson(),
      notes: booking.clientNotes,
      booking: booking,
    );
  }

  factory CalendarEvent.fromSession(WorkoutSession session) {
    return CalendarEvent(
      id: session.id,
      title: session.name ?? 'Workout Session',
      startTime: session.startTime,
      endTime: session.endTime ?? session.startTime.add(const Duration(hours: 1)),
      type: 'session',
      clientId: session.clientId,
      status: session.status.toJson(),
      notes: session.notes,
      session: session,
    );
  }

  /// Maps the API event type (e.g. "session_completed") to the display type.
  static String _mapEventType(String apiType) {
    if (apiType.startsWith('booking')) return 'booking';
    return 'session'; // includes "session_completed", "session_scheduled", etc.
  }

  /// Derives a status string from the API event type (e.g. "session_completed" -> "completed").
  static String _deriveStatus(String apiType) {
    final parts = apiType.split('_');
    if (parts.length > 1) return parts.last;
    return 'scheduled';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          id == other.id &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => Object.hash(id, startTime, endTime);
}

// ---------------------------------------------------------------------------
// Calendar State
// ---------------------------------------------------------------------------

class CalendarState {
  final List<CalendarEvent> events;
  final bool isLoading;
  final String? error;
  final DateTime selectedDate;
  final CalendarViewMode viewMode;

  CalendarState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    DateTime? selectedDate,
    this.viewMode = CalendarViewMode.month,
  }) : selectedDate = selectedDate ?? DateTime(2024, 1, 1);

  CalendarState copyWith({
    List<CalendarEvent>? events,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
    CalendarViewMode? viewMode,
    bool clearError = false,
  }) {
    return CalendarState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedDate: selectedDate ?? this.selectedDate,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  /// Get events for a specific date (events starting on this date)
  List<CalendarEvent> getEventsForDate(DateTime date) {
    return events.where((event) {
      return event.startTime.year == date.year &&
          event.startTime.month == date.month &&
          event.startTime.day == date.day;
    }).toList();
  }

  /// Get events for the currently selected date
  List<CalendarEvent> get selectedDateEvents => getEventsForDate(selectedDate);

  /// Get events from the selected date forward (for Agenda view)
  List<CalendarEvent> getEventsFromDateForward() {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return events
        .where((event) => event.startTime.isAfter(startOfDay) ||
            _isSameDay(event.startTime, selectedDate))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Generate dates around the selected date for the date strip
  List<DateTime> get daysAroundSelected {
    const totalDays = 60;
    const half = totalDays ~/ 2;
    return List.generate(totalDays, (i) {
      return selectedDate.subtract(Duration(days: half - i));
    });
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ---------------------------------------------------------------------------
// Calendar Notifier
// ---------------------------------------------------------------------------

class CalendarNotifier extends StateNotifier<CalendarState> {
  final ApiClient _apiClient;

  CalendarNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(CalendarState());

  /// Fetch events for a date range
  Future<void> fetchEvents(DateTime start, DateTime end) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> response = await _apiClient.get(
        ApiConstants.trainerCalendar,
        queryParams: {
          'startDate': start.toIso8601String(),
          'endDate': end.toIso8601String(),
        },
      );

      final data = response['data'] as Map<String, dynamic>;
      final eventsData = data['events'] as List<dynamic>? ?? [];

      final allEvents = eventsData
          .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      state = state.copyWith(
        events: allEvents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Create a new session
  Future<bool> createSession(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> response = await _apiClient.post(
        ApiConstants.trainerCalendar,
        body: data,
      );

      final sessionData = response['data'] as Map<String, dynamic>;
      final session = WorkoutSession.fromJson(sessionData);
      final event = CalendarEvent.fromSession(session);

      state = state.copyWith(
        events: [...state.events, event]..sort((a, b) => a.startTime.compareTo(b.startTime)),
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

  /// Update an existing session
  Future<bool> updateSession(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> response = await _apiClient.put(
        ApiConstants.calendarSession(id),
        body: data,
      );

      final sessionData = response['data'] as Map<String, dynamic>;
      final updatedSession = WorkoutSession.fromJson(sessionData);
      final updatedEvent = CalendarEvent.fromSession(updatedSession);

      final updatedEvents = state.events.map((event) {
        if (event.id == id) {
          return updatedEvent;
        }
        return event;
      }).toList();

      state = state.copyWith(
        events: updatedEvents,
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

  /// Delete a session
  Future<bool> deleteSession(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete(ApiConstants.calendarSession(id));

      final updatedEvents = state.events.where((event) => event.id != id).toList();

      state = state.copyWith(
        events: updatedEvents,
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

  /// Send a reminder for a session
  Future<bool> sendReminder(String id) async {
    try {
      await _apiClient.post(ApiConstants.sessionRemind(id));
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
      return false;
    }
  }

  /// Update the selected date
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  /// Set the view mode
  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Set view mode and date together (for page swipe in day view)
  void setViewModeAndDate(CalendarViewMode mode, DateTime date) {
    state = state.copyWith(viewMode: mode, selectedDate: date);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _extractErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString();
    }
    return 'An unexpected error occurred';
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CalendarNotifier(apiClient: apiClient);
});
