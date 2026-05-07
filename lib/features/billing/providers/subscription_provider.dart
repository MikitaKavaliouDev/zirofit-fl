import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// Represents a trainer's subscription with plan details.
class TrainerSubscription {
  final String planName;
  final String price;
  final String currency;
  final String interval;
  final String status;
  final DateTime? nextBillingDate;
  final List<String> features;

  const TrainerSubscription({
    required this.planName,
    required this.price,
    required this.currency,
    required this.interval,
    required this.status,
    this.nextBillingDate,
    this.features = const [],
  });

  factory TrainerSubscription.fromJson(Map<String, dynamic> json) {
    final featuresRaw = json['features'];
    final List<String> features;
    if (featuresRaw is List) {
      features = featuresRaw.map((e) => e.toString()).toList();
    } else {
      features = [];
    }

    return TrainerSubscription(
      planName: (json['plan_name'] as String?) ?? 'Free Plan',
      price: (json['price'] as num?)?.toStringAsFixed(2) ?? '0.00',
      currency: (json['currency'] as String?) ?? 'USD',
      interval: (json['interval'] as String?) ?? 'month',
      status: (json['status'] as String?) ?? 'inactive',
      nextBillingDate: json['next_billing_date'] != null
          ? DateTime.tryParse(json['next_billing_date'] as String)
          : null,
      features: features,
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SubscriptionState {
  final TrainerSubscription? subscription;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.subscription,
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    TrainerSubscription? subscription,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSubscription = false,
  }) {
    return SubscriptionState(
      subscription:
          clearSubscription ? null : (subscription ?? this.subscription),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubscriptionNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final ApiClient _api;

  SubscriptionNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const SubscriptionState());

  /// Fetches the current trainer subscription details.
  Future<void> fetchSubscription() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.billingSubscription,
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final subscription = TrainerSubscription.fromJson(data);

      state = state.copyWith(
        subscription: subscription,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Gets the Stripe Customer Portal link for managing the subscription.
  Future<String?> getPortalLink() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.billingPortal,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final url = data?['url'] as String?;

      state = state.copyWith(isLoading: false);

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
