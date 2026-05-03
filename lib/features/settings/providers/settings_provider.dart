import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SettingsState {
  final int defaultCheckInDay; // 0=Sun..6=Sat
  final int defaultCheckInHour;
  final String weightUnit; // 'KG', 'LB'
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const SettingsState({
    this.defaultCheckInDay = 0,
    this.defaultCheckInHour = 9,
    this.weightUnit = 'KG',
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  SettingsState copyWith({
    int? defaultCheckInDay,
    int? defaultCheckInHour,
    String? weightUnit,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SettingsState(
      defaultCheckInDay: defaultCheckInDay ?? this.defaultCheckInDay,
      defaultCheckInHour: defaultCheckInHour ?? this.defaultCheckInHour,
      weightUnit: weightUnit ?? this.weightUnit,
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

class SettingsNotifier extends StateNotifier<SettingsState> {
  final ApiClient _api;

  SettingsNotifier({required ApiClient apiClient})
      : _api = apiClient,
        super(const SettingsState());

  // -- Load settings --

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      // GET /api/profile/me returns profile data including settings
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.profileMe,
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;

      state = state.copyWith(
        defaultCheckInDay: (data['defaultCheckInDay'] as int?) ?? state.defaultCheckInDay,
        defaultCheckInHour: (data['defaultCheckInHour'] as int?) ?? state.defaultCheckInHour,
        weightUnit: (data['weightUnit'] as String?) ?? state.weightUnit,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Save check-in defaults --

  Future<void> saveCheckInDefaults(int day, int hour) async {
    state = state.copyWith(
      defaultCheckInDay: day,
      defaultCheckInHour: hour,
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.trainerSettings,
        body: {
          'defaultCheckInDay': day,
          'defaultCheckInHour': hour,
        },
      );

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Check-in defaults saved successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Toggle weight unit --

  Future<void> toggleWeightUnit(String unit) async {
    state = state.copyWith(
      weightUnit: unit,
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.trainerSettings,
        body: {
          'weightUnit': unit,
        },
      );

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Weight unit updated to $unit',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
    }
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
        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 401) {
            return 'Unauthorized. Please log in again.';
          }
          if (error.response?.statusCode == 429) {
            return 'Too many attempts. Please try again later.';
          }
          break;
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

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SettingsNotifier(apiClient: apiClient);
});
