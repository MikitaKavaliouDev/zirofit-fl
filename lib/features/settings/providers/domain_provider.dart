import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DomainState {
  final String? domain;
  final bool isLoading;
  final String? error;
  final bool isVerified;
  final bool isAdding;

  const DomainState({
    this.domain,
    this.isLoading = false,
    this.error,
    this.isVerified = false,
    this.isAdding = false,
  });

  DomainState copyWith({
    String? domain,
    bool? isLoading,
    String? error,
    bool? isVerified,
    bool? isAdding,
    bool clearError = false,
    bool clearDomain = false,
  }) {
    return DomainState(
      domain: clearDomain ? null : (domain ?? this.domain),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isVerified: isVerified ?? this.isVerified,
      isAdding: isAdding ?? this.isAdding,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DomainNotifier extends StateNotifier<DomainState> {
  final ApiClient _api;

  DomainNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const DomainState());

  /// Adds a custom domain.
  Future<bool> addDomain(String domain) async {
    state = state.copyWith(isAdding: true, clearError: true);

    try {
      final Map<String, dynamic> response = await _api.post(
        ApiConstants.domainAdd,
        body: {'domain': domain},
      );

      // If the API returns domain info, use it
      if (response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        state = state.copyWith(
          domain: data['domain'] as String? ?? domain,
          isAdding: false,
          isVerified: (data['verified'] as bool?) ?? false,
        );
      } else {
        state = state.copyWith(
          domain: domain,
          isAdding: false,
        );
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isAdding: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  /// Verifies the current custom domain.
  Future<bool> verifyDomain() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> response = await _api.post(
        ApiConstants.domainVerify,
      );

      final bool verified = (response['data'] as Map<String, dynamic>?)?['verified'] as bool? ?? true;

      state = state.copyWith(
        isLoading: false,
        isVerified: verified,
      );

      return verified;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  /// Resets the state (e.g., on screen exit).
  void reset() {
    state = const DomainState();
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

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final domainProvider =
    StateNotifierProvider<DomainNotifier, DomainState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DomainNotifier(apiClient: apiClient);
});
