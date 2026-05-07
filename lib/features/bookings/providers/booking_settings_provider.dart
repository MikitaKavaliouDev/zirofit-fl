import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// BookingSettingsState
// ---------------------------------------------------------------------------

class BookingSettingsState {
  final int advanceNotice;
  final int bookingHorizon;
  final int bufferMinutes;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const BookingSettingsState({
    this.advanceNotice = 24,
    this.bookingHorizon = 30,
    this.bufferMinutes = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  BookingSettingsState copyWith({
    int? advanceNotice,
    int? bookingHorizon,
    int? bufferMinutes,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BookingSettingsState(
      advanceNotice: advanceNotice ?? this.advanceNotice,
      bookingHorizon: bookingHorizon ?? this.bookingHorizon,
      bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class BookingSettingsNotifier extends StateNotifier<BookingSettingsState> {
  final ApiClient _api;

  BookingSettingsNotifier({required ApiClient apiClient})
      : _api = apiClient,
        super(const BookingSettingsState());

  // -- Load settings --

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerBookingSettings,
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;

      state = state.copyWith(
        advanceNotice: data['advanceNotice'] as int? ?? 24,
        bookingHorizon: data['bookingHorizon'] as int? ?? 30,
        bufferMinutes: data['bufferMinutes'] as int? ?? 0,
        isLoading: false,
      );
    } catch (e) {
      // Keep defaults on error
      state = state.copyWith(isLoading: false);
    }
  }

  // -- Save settings --

  Future<bool> saveSettings() async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.trainerBookingSettings,
        body: {
          'advanceNotice': state.advanceNotice,
          'bookingHorizon': state.bookingHorizon,
          'bufferMinutes': state.bufferMinutes,
        },
      );

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Booking window settings saved',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // -- Mutators --

  void updateAdvanceNotice(int hours) {
    state = state.copyWith(
      advanceNotice: hours.clamp(2, 72),
      clearError: true,
      clearSuccess: true,
    );
  }

  void updateBookingHorizon(int days) {
    state = state.copyWith(
      bookingHorizon: days.clamp(7, 90),
      clearError: true,
      clearSuccess: true,
    );
  }

  void updateBufferMinutes(int minutes) {
    state = state.copyWith(
      bufferMinutes: minutes.clamp(0, 120),
      clearError: true,
      clearSuccess: true,
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  // -- Helpers --

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

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final bookingSettingsProvider =
    StateNotifierProvider<BookingSettingsNotifier, BookingSettingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingSettingsNotifier(apiClient: apiClient);
});
