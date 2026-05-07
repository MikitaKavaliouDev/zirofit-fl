import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// EmailVerification state
// ---------------------------------------------------------------------------

/// Status of a resend-verification-email request.
enum ResendStatus { idle, sending, sent, error }

/// Immutable state for the email verification flow.
class EmailVerificationState {
  final bool isPolling;
  final bool isConfirmed;
  final bool hasTimedOut;
  final String? error;
  final ResendStatus resendStatus;

  const EmailVerificationState({
    this.isPolling = false,
    this.isConfirmed = false,
    this.hasTimedOut = false,
    this.error,
    this.resendStatus = ResendStatus.idle,
  });

  EmailVerificationState copyWith({
    bool? isPolling,
    bool? isConfirmed,
    bool? hasTimedOut,
    String? error,
    ResendStatus? resendStatus,
    bool clearError = false,
  }) {
    return EmailVerificationState(
      isPolling: isPolling ?? this.isPolling,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      hasTimedOut: hasTimedOut ?? this.hasTimedOut,
      error: clearError ? null : (error ?? this.error),
      resendStatus: resendStatus ?? this.resendStatus,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final emailVerificationProvider = StateNotifierProvider.autoDispose<
    EmailVerificationNotifier, EmailVerificationState>(
  (ref) {
    final apiClient = ref.watch(apiClientProvider);
    return EmailVerificationNotifier(apiClient: apiClient);
  },
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class EmailVerificationNotifier
    extends StateNotifier<EmailVerificationState> {
  final ApiClient _apiClient;
  Timer? _pollTimer;
  int _pollCount = 0;

  /// Maximum number of polls before giving up (24 × 5s = 120s).
  static const int maxPolls = 24;

  EmailVerificationNotifier({
    required ApiClient apiClient,
  }) : _apiClient = apiClient,
       super(const EmailVerificationState());

  // -- Polling ---------------------------------------------------------------

  /// Starts the 5-second polling loop and fires an immediate check.
  void startPolling() {
    state = state.copyWith(isPolling: true, clearError: true);
    _pollTimer?.cancel();
    _pollCount = 0;

    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkEmailConfirmation(),
    );

    // Fire an immediate check so the user isn't waiting 5s for the first poll.
    _checkEmailConfirmation();
  }

  Future<void> _checkEmailConfirmation() async {
    if (_pollCount >= maxPolls) {
      _pollTimer?.cancel();
      state = state.copyWith(isPolling: false, hasTimedOut: true);
      return;
    }
    _pollCount++;

    try {
      final Map<String, dynamic> response =
          await _apiClient.get(ApiConstants.me);
      final data =
          (response['data'] as Map<String, dynamic>?) ?? response;
      final emailConfirmedAt = data['emailConfirmedAt'] as String?;

      if (emailConfirmedAt != null && emailConfirmedAt.isNotEmpty) {
        _pollTimer?.cancel();
        state = state.copyWith(
          isPolling: false,
          isConfirmed: true,
        );
      }
    } catch (_) {
      // Network hiccups — silently continue polling.
    }
  }

  // -- Resend ---------------------------------------------------------------

  /// Sends a request to re-send the verification email.
  Future<void> resendEmail() async {
    state = state.copyWith(
      resendStatus: ResendStatus.sending,
      clearError: true,
    );

    try {
      await _apiClient.post(ApiConstants.resendVerification);
      state = state.copyWith(resendStatus: ResendStatus.sent);
    } catch (_) {
      state = state.copyWith(
        resendStatus: ResendStatus.error,
        error: 'Failed to resend verification email.',
      );
    }
  }

  // -- Lifecycle ------------------------------------------------------------

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
