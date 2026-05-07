import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DataSharingState {
  final bool shareWorkouts;
  final bool shareMeasurements;
  final bool sharePhotos;
  final bool shareCheckIns;
  final String expirationType; // 'forever' | 'date'
  final DateTime? expirationDate;
  final bool isSaving;
  final String? error;

  const DataSharingState({
    this.shareWorkouts = true,
    this.shareMeasurements = true,
    this.sharePhotos = true,
    this.shareCheckIns = true,
    this.expirationType = 'forever',
    this.expirationDate,
    this.isSaving = false,
    this.error,
  });

  DataSharingState copyWith({
    bool? shareWorkouts,
    bool? shareMeasurements,
    bool? sharePhotos,
    bool? shareCheckIns,
    String? expirationType,
    DateTime? expirationDate,
    bool? isSaving,
    String? error,
    bool clearError = false,
    bool clearExpirationDate = false,
  }) {
    return DataSharingState(
      shareWorkouts: shareWorkouts ?? this.shareWorkouts,
      shareMeasurements: shareMeasurements ?? this.shareMeasurements,
      sharePhotos: sharePhotos ?? this.sharePhotos,
      shareCheckIns: shareCheckIns ?? this.shareCheckIns,
      expirationType: expirationType ?? this.expirationType,
      expirationDate: clearExpirationDate ? null : (expirationDate ?? this.expirationDate),
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Resets all fields to defaults.
  static const defaults = DataSharingState();

  /// Converts state to a JSON map for the PUT body.
  Map<String, dynamic> toJson() {
    return {
      'shareWorkouts': shareWorkouts,
      'shareMeasurements': shareMeasurements,
      'sharePhotos': sharePhotos,
      'shareCheckIns': shareCheckIns,
      'expirationType': expirationType,
      if (expirationType == 'date' && expirationDate != null)
        'expirationDate': expirationDate!.toIso8601String(),
    };
  }

  /// Creates state from API response JSON.
  factory DataSharingState.fromJson(Map<String, dynamic> json) {
    return DataSharingState(
      shareWorkouts: (json['shareWorkouts'] as bool?) ?? true,
      shareMeasurements: (json['shareMeasurements'] as bool?) ?? true,
      sharePhotos: (json['sharePhotos'] as bool?) ?? true,
      shareCheckIns: (json['shareCheckIns'] as bool?) ?? true,
      expirationType: (json['expirationType'] as String?) ?? 'forever',
      expirationDate: json['expirationDate'] != null
          ? DateTime.tryParse(json['expirationDate'] as String)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DataSharingNotifier extends StateNotifier<DataSharingState> {
  final ApiClient _api;

  DataSharingNotifier({required ApiClient apiClient})
      : _api = apiClient,
        super(const DataSharingState());

  // -- Fetch settings --

  /// GET /api/client/sharing
  Future<void> fetchSettings() async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.clientSharing,
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;
      state = DataSharingState.fromJson(data).copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Toggle category (local only) --

  /// Flips the boolean flag for the given sharing [category].
  /// Category must be one of: 'workouts', 'measurements', 'photos', 'checkIns'.
  void toggleCategory(String category) {
    switch (category) {
      case 'workouts':
        state = state.copyWith(shareWorkouts: !state.shareWorkouts);
      case 'measurements':
        state = state.copyWith(shareMeasurements: !state.shareMeasurements);
      case 'photos':
        state = state.copyWith(sharePhotos: !state.sharePhotos);
      case 'checkIns':
        state = state.copyWith(shareCheckIns: !state.shareCheckIns);
    }
  }

  // -- Set expiration (local only) --

  /// Sets the expiration [type] ('forever' | 'date') and optionally a [date].
  void setExpiration(String type, [DateTime? date]) {
    state = state.copyWith(
      expirationType: type,
      expirationDate: type == 'date' ? date : null,
      clearExpirationDate: type != 'date',
    );
  }

  // -- Save settings to API --

  /// PUT /api/client/sharing with all current state values.
  Future<void> saveSettings() async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.clientSharing,
        body: state.toJson(),
      );

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Reset to defaults --

  /// Restores all fields to their default values.
  void resetToDefaults() {
    state = const DataSharingState();
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

final dataSharingProvider =
    StateNotifierProvider<DataSharingNotifier, DataSharingState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DataSharingNotifier(apiClient: apiClient);
});
