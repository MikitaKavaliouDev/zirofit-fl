import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class BillingState {
  final String? subscriptionStatus;
  final String? checkoutUrl;
  final bool isLoading;
  final String? error;

  const BillingState({
    this.subscriptionStatus,
    this.checkoutUrl,
    this.isLoading = false,
    this.error,
  });

  BillingState copyWith({
    String? subscriptionStatus,
    String? checkoutUrl,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BillingState(
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final billingProvider =
    StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BillingNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class BillingNotifier extends StateNotifier<BillingState> {
  final ApiClient _api;

  BillingNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const BillingState());

  /// Fetches the current subscription status.
  Future<void> fetchSubscription() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.billingSubscription,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final status = data?['status'] as String?;

      state = BillingState(
        subscriptionStatus: status,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Creates a checkout session for the given [packageId] and returns the
  /// checkout URL. On success the URL is also stored in [BillingState.checkoutUrl].
  Future<String?> createCheckoutSession(String packageId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.createCheckoutSession,
        body: {'packageId': packageId},
      );

      final data = response['data'] as Map<String, dynamic>?;
      final url = data?['url'] as String?;

      state = state.copyWith(
        checkoutUrl: url,
        isLoading: false,
      );

      return url;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
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
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}
