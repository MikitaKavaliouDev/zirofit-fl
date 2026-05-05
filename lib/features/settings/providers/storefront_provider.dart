import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class StorefrontState {
  final bool isVisible;
  final bool isFeatured;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const StorefrontState({
    this.isVisible = true,
    this.isFeatured = false,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  StorefrontState copyWith({
    bool? isVisible,
    bool? isFeatured,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return StorefrontState(
      isVisible: isVisible ?? this.isVisible,
      isFeatured: isFeatured ?? this.isFeatured,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class StorefrontNotifier extends StateNotifier<StorefrontState> {
  final ApiClient _api;

  StorefrontNotifier({required ApiClient apiClient})
      : _api = apiClient,
        super(const StorefrontState());

  /// Fetches the storefront visibility and featured status.
  Future<void> fetchStorefront() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerStorefront,
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;

      state = state.copyWith(
        isVisible: (data['is_visible'] as bool?) ?? true,
        isFeatured: (data['is_featured'] as bool?) ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Toggles storefront visibility on/off.
  Future<void> toggleVisibility() async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    final newVisibility = !state.isVisible;

    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.trainerStorefrontVisibility,
        body: {'is_visible': newVisibility},
      );

      state = state.copyWith(
        isVisible: newVisibility,
        isSaving: false,
        successMessage:
            newVisibility ? 'Storefront is now visible' : 'Storefront is now hidden',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Toggles featured status.
  Future<void> toggleFeatured() async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    final newFeatured = !state.isFeatured;

    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.trainerStorefront,
        body: {'is_featured': newFeatured},
      );

      state = state.copyWith(
        isFeatured: newFeatured,
        isSaving: false,
        successMessage:
            newFeatured ? 'Marked as featured' : 'Featured status removed',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
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

final storefrontProvider =
    StateNotifierProvider<StorefrontNotifier, StorefrontState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StorefrontNotifier(apiClient: apiClient);
});
