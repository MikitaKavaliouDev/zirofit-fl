import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class BookingsState {
  final List<Booking> bookings;
  final bool isLoading;
  final String? error;

  const BookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  BookingsState copyWith({
    List<Booking>? bookings,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingsNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class BookingsNotifier extends StateNotifier<BookingsState> {
  final ApiClient _apiClient;

  BookingsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const BookingsState());

  /// Fetches all bookings.
  Future<void> fetchBookings() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> data = await _apiClient.get(
        ApiConstants.bookings,
      );

      final List<dynamic> rawList = (data['data'] as List?) ?? [];

      final bookings = rawList
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        bookings: bookings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Confirms a booking by [id].
  Future<bool> confirmBooking(String id) async {
    try {
      final Map<String, dynamic> _ = await _apiClient.put(
        ApiConstants.bookingConfirm(id),
      );

      state = state.copyWith(
        bookings: state.bookings.map((b) {
          if (b.id == id) {
            return Booking(
              id: b.id,
              startTime: b.startTime,
              endTime: b.endTime,
              status: BookingStatus.confirmed,
              dataSharingApproved: b.dataSharingApproved,
              dataSharingApprovedAt: b.dataSharingApprovedAt,
              trainerId: b.trainerId,
              clientId: b.clientId,
              clientName: b.clientName,
              clientEmail: b.clientEmail,
              clientNotes: b.clientNotes,
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
              deletedAt: b.deletedAt,
            );
          }
          return b;
        }).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
      return false;
    }
  }

  /// Declines a booking by [id].
  Future<bool> declineBooking(String id) async {
    try {
      final Map<String, dynamic> _ = await _apiClient.put(
        ApiConstants.bookingDecline(id),
      );

      state = state.copyWith(
        bookings: state.bookings.map((b) {
          if (b.id == id) {
            return Booking(
              id: b.id,
              startTime: b.startTime,
              endTime: b.endTime,
              status: BookingStatus.cancelled,
              dataSharingApproved: b.dataSharingApproved,
              dataSharingApprovedAt: b.dataSharingApprovedAt,
              trainerId: b.trainerId,
              clientId: b.clientId,
              clientName: b.clientName,
              clientEmail: b.clientEmail,
              clientNotes: b.clientNotes,
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
              deletedAt: b.deletedAt,
            );
          }
          return b;
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
