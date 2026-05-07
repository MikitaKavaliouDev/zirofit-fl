import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/utils/json_helpers.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// TimeSlot model
// ---------------------------------------------------------------------------

class TimeSlot {
  final DateTime start;
  final DateTime end;

  const TimeSlot({required this.start, required this.end});

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        start: readDateTime(json, 'start_time', 'start'),
        end: readDateTime(json, 'end_time', 'end'),
      );

  Map<String, dynamic> toJson() => {
        'start_time': dateTimeToJson(start),
        'end_time': dateTimeToJson(end),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TimeSlot(start: $start, end: $end)';
}

// ---------------------------------------------------------------------------
// Trainer model
// ---------------------------------------------------------------------------

class Trainer {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? specialty;
  final double? rating;

  const Trainer({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.specialty,
    this.rating,
  });

  factory Trainer.fromJson(Map<String, dynamic> json) => Trainer(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        specialty: json['specialty'] as String?,
        rating: (json['rating'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        if (specialty != null) 'specialty': specialty,
        if (rating != null) 'rating': rating,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trainer &&
          id == other.id &&
          name == other.name &&
          avatarUrl == other.avatarUrl &&
          specialty == other.specialty &&
          rating == other.rating;

  @override
  int get hashCode => Object.hash(id, name, avatarUrl, specialty, rating);

  @override
  String toString() =>
      'Trainer(id: $id, name: $name, avatarUrl: $avatarUrl, specialty: $specialty, rating: $rating)';
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClientBookingState {
  final DateTime? selectedDate;
  final List<TimeSlot> availableSlots;
  final Trainer? trainerInfo;
  final bool isLoading;
  final String? error;
  final bool pendingBooking;

  const ClientBookingState({
    this.selectedDate,
    this.availableSlots = const [],
    this.trainerInfo,
    this.isLoading = false,
    this.error,
    this.pendingBooking = false,
  });

  ClientBookingState copyWith({
    DateTime? selectedDate,
    List<TimeSlot>? availableSlots,
    Trainer? trainerInfo,
    bool? isLoading,
    String? error,
    bool? pendingBooking,
    bool clearError = false,
  }) {
    return ClientBookingState(
      selectedDate: selectedDate ?? this.selectedDate,
      availableSlots: availableSlots ?? this.availableSlots,
      trainerInfo: trainerInfo ?? this.trainerInfo,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pendingBooking: pendingBooking ?? this.pendingBooking,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final clientBookingProvider =
    StateNotifierProvider<ClientBookingNotifier, ClientBookingState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClientBookingNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ClientBookingNotifier extends StateNotifier<ClientBookingState> {
  final ApiClient _apiClient;

  ClientBookingNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const ClientBookingState());

  /// Fetches a trainer's schedule (availability) for a given [date].
  /// Stores trainer info and available time slots.
  Future<void> fetchTrainerAvailability(String trainerId, DateTime date) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> response = await _apiClient.get(
        ApiConstants.trainerSchedule(trainerId),
        queryParams: {
          'date': _formatDate(date),
        },
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;

      // Parse trainer info
      final trainerData = data['trainer'] as Map<String, dynamic>?;
      final trainer = trainerData != null
          ? Trainer.fromJson(trainerData)
          : Trainer(id: trainerId, name: '');

      // Parse available slots
      final slotsRaw = data['slots'] as List<dynamic>? ?? [];
      final slots = slotsRaw
          .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        trainerInfo: trainer,
        availableSlots: slots,
        selectedDate: date,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Updates the selected date and re-fetches availability for the stored
  /// trainer. Does nothing if no trainer has been loaded yet.
  Future<void> selectDate(DateTime date) async {
    final trainerId = state.trainerInfo?.id;
    if (trainerId == null) {
      state = state.copyWith(selectedDate: date);
      return;
    }
    await fetchTrainerAvailability(trainerId, date);
  }

  /// Requests a new booking with [trainerId] for the given [slot].
  /// Returns the booking ID on success, `null` on failure.
  Future<String?> requestBooking(String trainerId, TimeSlot slot) async {
    state = state.copyWith(pendingBooking: true, clearError: true);

    try {
      final Map<String, dynamic> response = await _apiClient.post(
        ApiConstants.bookings,
        body: {
          'trainer_id': trainerId,
          'start_time': dateTimeToJson(slot.start),
          'end_time': dateTimeToJson(slot.end),
        },
      );

      state = state.copyWith(pendingBooking: false);
      return response['data']?['id'] as String? ??
          response['id'] as String?;
    } catch (e) {
      state = state.copyWith(
        pendingBooking: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  /// Cancels a booking by [bookingId].
  /// Returns `true` on success, `false` on failure.
  Future<bool> cancelBooking(String bookingId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> _ = await _apiClient.post(
        ApiConstants.bookingCancel(bookingId),
      );

      state = state.copyWith(isLoading: false);
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

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
