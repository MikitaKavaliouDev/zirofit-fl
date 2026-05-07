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

class BookingManagementState {
  final List<Booking> pendingBookings;
  final List<Booking> confirmedBookings;
  final List<Booking> declinedBookings;
  final bool isLoading;
  final String? error;
  final bool isActionInProgress;

  const BookingManagementState({
    this.pendingBookings = const [],
    this.confirmedBookings = const [],
    this.declinedBookings = const [],
    this.isLoading = false,
    this.error,
    this.isActionInProgress = false,
  });

  BookingManagementState copyWith({
    List<Booking>? pendingBookings,
    List<Booking>? confirmedBookings,
    List<Booking>? declinedBookings,
    bool? isLoading,
    String? error,
    bool? isActionInProgress,
    bool clearError = false,
  }) {
    return BookingManagementState(
      pendingBookings: pendingBookings ?? this.pendingBookings,
      confirmedBookings: confirmedBookings ?? this.confirmedBookings,
      declinedBookings: declinedBookings ?? this.declinedBookings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final bookingManagementProvider = StateNotifierProvider<
    BookingManagementNotifier, BookingManagementState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingManagementNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class BookingManagementNotifier extends StateNotifier<BookingManagementState> {
  final ApiClient _apiClient;

  BookingManagementNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const BookingManagementState());

  /// Fetches all booking categories from the trainer endpoint.
  /// Makes three parallel requests for pending, confirmed, and cancelled.
  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _fetchByStatus('pending'),
        _fetchByStatus('confirmed'),
        _fetchByStatus('cancelled'),
      ]);

      state = state.copyWith(
        pendingBookings: results[0],
        confirmedBookings: results[1],
        declinedBookings: results[2],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Approves (confirms) a pending booking by [id].
  /// Moves the booking from pending to confirmed locally and refreshes.
  Future<bool> approveBooking(String id) async {
    state = state.copyWith(isActionInProgress: true, clearError: true);

    try {
      final Map<String, dynamic> _ =
          await _apiClient.post(ApiConstants.bookingApprove(id));

      // Find and move the booking locally
      final booking = state.pendingBookings.firstWhere(
        (b) => b.id == id,
        orElse: () => throw Exception('Booking $id not found in pending list'),
      );

      state = state.copyWith(
        pendingBookings:
            state.pendingBookings.where((b) => b.id != id).toList(),
        confirmedBookings: [
          ...state.confirmedBookings,
          Booking(
            id: booking.id,
            startTime: booking.startTime,
            endTime: booking.endTime,
            status: BookingStatus.confirmed,
            dataSharingApproved: booking.dataSharingApproved,
            dataSharingApprovedAt: booking.dataSharingApprovedAt,
            trainerId: booking.trainerId,
            clientId: booking.clientId,
            clientName: booking.clientName,
            clientEmail: booking.clientEmail,
            clientNotes: booking.clientNotes,
            createdAt: booking.createdAt,
            updatedAt: booking.updatedAt,
            deletedAt: booking.deletedAt,
          ),
        ],
        isActionInProgress: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  /// Declines (cancels) a pending booking by [id].
  /// Moves the booking from pending to declined locally and refreshes.
  Future<bool> declineBooking(String id) async {
    state = state.copyWith(isActionInProgress: true, clearError: true);

    try {
      final Map<String, dynamic> _ =
          await _apiClient.post(ApiConstants.bookingDecline(id));

      // Find and move the booking locally
      final booking = state.pendingBookings.firstWhere(
        (b) => b.id == id,
        orElse: () => throw Exception('Booking $id not found in pending list'),
      );

      state = state.copyWith(
        pendingBookings:
            state.pendingBookings.where((b) => b.id != id).toList(),
        declinedBookings: [
          ...state.declinedBookings,
          Booking(
            id: booking.id,
            startTime: booking.startTime,
            endTime: booking.endTime,
            status: BookingStatus.cancelled,
            dataSharingApproved: booking.dataSharingApproved,
            dataSharingApprovedAt: booking.dataSharingApprovedAt,
            trainerId: booking.trainerId,
            clientId: booking.clientId,
            clientName: booking.clientName,
            clientEmail: booking.clientEmail,
            clientNotes: booking.clientNotes,
            createdAt: booking.createdAt,
            updatedAt: booking.updatedAt,
            deletedAt: booking.deletedAt,
          ),
        ],
        isActionInProgress: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<List<Booking>> _fetchByStatus(String status) async {
    final Map<String, dynamic> data = await _apiClient.get(
      ApiConstants.trainerBookings,
      queryParams: {'status': status},
    );

    final List<dynamic> rawList = (data['data'] as List?) ?? [];
    return rawList
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
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
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}
