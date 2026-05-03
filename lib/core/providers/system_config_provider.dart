import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SystemConfigState {
  final Map<String, dynamic> flags;
  final bool isLoading;
  final String? error;

  const SystemConfigState({
    this.flags = const {},
    this.isLoading = false,
    this.error,
  });

  SystemConfigState copyWith({
    Map<String, dynamic>? flags,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SystemConfigState(
      flags: flags ?? this.flags,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final systemConfigProvider =
    StateNotifierProvider<SystemConfigNotifier, SystemConfigState>((ref) {
  return SystemConfigNotifier();
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SystemConfigNotifier extends StateNotifier<SystemConfigState> {
  final ApiClient _api;

  SystemConfigNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const SystemConfigState());

  /// GET /api/system/config
  Future<void> fetchConfig() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.systemConfig,
      );

      final flags = result['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

      state = SystemConfigState(flags: flags);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Clears any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
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
      return 'Something went wrong. Please try again.';
    }
    return error.toString();
  }
}
