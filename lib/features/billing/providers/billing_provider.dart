import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class Payout {
  final String id;
  final double amount;
  final String currency;
  final String status; // pending, paid, failed, cancelled
  final DateTime createdAt;

  const Payout({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) => Payout(
        id: json['id'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: (json['currency'] as String?) ?? 'USD',
        status: (json['status'] as String?) ?? 'pending',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class RevenueTransaction {
  final String id;
  final String title;
  final String date;
  final double amount;
  final String status;
  final String type; // 'sale', 'fee', 'payout', 'refund'

  const RevenueTransaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    this.type = 'sale',
  });

  factory RevenueTransaction.fromJson(Map<String, dynamic> json) =>
      RevenueTransaction(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        date: json['date'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: (json['status'] as String?) ?? 'completed',
        type: (json['type'] as String?) ?? 'sale',
      );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class BillingState {
  // Existing subscription fields
  final String? subscriptionStatus;
  final String? checkoutUrl;
  final bool isLoading;
  final String? error;

  // Payout fields
  final List<Payout> payouts;
  final Map<String, dynamic>? stripeStatus;
  final String? stripeOnboardingUrl;
  final double totalEarned;
  final double pendingAmount;
  final double paidOutAmount;

  // Revenue fields
  final double availableForPayout;
  final double lastPayout;
  final double monthlyGrowth;
  final List<RevenueTransaction> transactions;

  const BillingState({
    this.subscriptionStatus,
    this.checkoutUrl,
    this.isLoading = false,
    this.error,
    this.payouts = const [],
    this.stripeStatus,
    this.stripeOnboardingUrl,
    this.totalEarned = 0,
    this.pendingAmount = 0,
    this.paidOutAmount = 0,
    this.availableForPayout = 0,
    this.lastPayout = 0,
    this.monthlyGrowth = 0,
    this.transactions = const [],
  });

  BillingState copyWith({
    String? subscriptionStatus,
    String? checkoutUrl,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Payout>? payouts,
    Map<String, dynamic>? stripeStatus,
    String? stripeOnboardingUrl,
    double? totalEarned,
    double? pendingAmount,
    double? paidOutAmount,
    double? availableForPayout,
    double? lastPayout,
    double? monthlyGrowth,
    List<RevenueTransaction>? transactions,
  }) {
    return BillingState(
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      payouts: payouts ?? this.payouts,
      stripeStatus: stripeStatus ?? this.stripeStatus,
      stripeOnboardingUrl:
          stripeOnboardingUrl ?? this.stripeOnboardingUrl,
      totalEarned: totalEarned ?? this.totalEarned,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      paidOutAmount: paidOutAmount ?? this.paidOutAmount,
      availableForPayout:
          availableForPayout ?? this.availableForPayout,
      lastPayout: lastPayout ?? this.lastPayout,
      monthlyGrowth: monthlyGrowth ?? this.monthlyGrowth,
      transactions: transactions ?? this.transactions,
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

      state = state.copyWith(
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

  /// Fetches payout history and Stripe Connect status.
  Future<void> fetchPayouts() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Fetch Stripe connect status
      Map<String, dynamic>? stripeData;
      try {
        final stripeResponse = await _api.get<Map<String, dynamic>>(
          ApiConstants.billingStripeStatus,
        );
        stripeData =
            stripeResponse['data'] as Map<String, dynamic>? ?? stripeResponse;
      } catch (_) {
        // Stripe status is non-critical
      }

      // Fetch payout history
      final payoutResponse = await _api.get<Map<String, dynamic>>(
        ApiConstants.billingPayouts,
      );

      final payoutData =
          payoutResponse['data'] as Map<String, dynamic>? ?? payoutResponse;

      final List<dynamic> rawPayouts = (payoutData['payouts'] as List?) ?? [];
      final payouts =
          rawPayouts.map((e) => Payout.fromJson(e as Map<String, dynamic>)).toList();

      state = state.copyWith(
        stripeStatus: stripeData,
        payouts: payouts,
        totalEarned: (payoutData['total_earned'] as num?)?.toDouble() ?? 0,
        pendingAmount: (payoutData['pending_amount'] as num?)?.toDouble() ?? 0,
        paidOutAmount: (payoutData['paid_out_amount'] as num?)?.toDouble() ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Fetches Stripe onboarding URL for connecting a bank account.
  Future<String?> fetchStripeOnboardingUrl() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.billingStripeOnboarding,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final url = data?['url'] as String?;

      state = state.copyWith(
        stripeOnboardingUrl: url,
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

  /// Fetches revenue overview and transaction history.
  Future<void> fetchRevenue() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.billingRevenue,
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final List<dynamic> rawTransactions =
          (data['transactions'] as List?) ?? [];
      final transactions = rawTransactions
          .map((e) => RevenueTransaction.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        availableForPayout:
            (data['available_for_payout'] as num?)?.toDouble() ?? 0,
        totalEarned: (data['total_earned'] as num?)?.toDouble() ?? 0,
        lastPayout: (data['last_payout'] as num?)?.toDouble() ?? 0,
        monthlyGrowth: (data['monthly_growth'] as num?)?.toDouble() ?? 0,
        transactions: transactions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Fetches the trainer's Stripe Connect onboarding status from
  /// the trainer-specific endpoint.
  Future<Map<String, dynamic>?> fetchStripeStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerStripeStatus,
      );

      final data =
          response['data'] as Map<String, dynamic>? ?? response;

      state = state.copyWith(
        stripeStatus: data,
        isLoading: false,
      );

      return data;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  /// Creates a Stripe Connect onboarding link for the trainer and returns
  /// the URL to open in a browser.
  Future<String?> getStripeOnboardingUrl() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.trainerStripeOnboarding,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final url = data?['url'] as String?;

      state = state.copyWith(
        stripeOnboardingUrl: url,
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

  /// Creates a checkout session for the given [packageId] and returns the
  /// checkout URL.
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
