import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Represents the result of a Stripe Connect onboarding flow.
///
/// Mirrors the callback params Stripe sends back after onboarding completes:
/// - [success]: Whether onboarding was completed successfully
/// - [accountId]: The connected Stripe account ID (on success)
/// - [state]: Optional state parameter for CSRF verification
/// - [errorMessage]: Human-readable error description (on failure)
class StripeOnboardingResult {
  /// Whether the onboarding flow completed successfully.
  final bool success;

  /// Human-readable error description, if any.
  final String? errorMessage;

  /// The connected Stripe account ID (`acct_xxx`), present on success.
  final String? accountId;

  /// Optional state parameter passed through from the original URL for CSRF
  /// verification.
  final String? state;

  const StripeOnboardingResult({
    required this.success,
    this.errorMessage,
    this.accountId,
    this.state,
  });
}

/// Singleton service for managing Stripe Connect onboarding.
///
/// ### Flow
/// 1. Call [startOnboarding] with the Stripe onboarding URL — opens the
///    system browser so the user can complete Stripe's Connect onboarding.
/// 2. Stripe redirects back to `zirofitapp://stripe-return?success=true&account_id=acct_xxx`
///    which is caught by [DeepLinkService] (via `app_links`) and forwarded
///    to [handleDeepLink].
/// 3. The result is broadcast on [onOnboardingComplete] for internal
///    consumers (Riverpod providers, UI controllers, etc.).
///
/// This mirrors the iOS `StripeConnectManager` which uses
/// `ASWebAuthenticationSession` + Universal Links for the same flow.
class StripeConnectService extends ChangeNotifier {
  static final StripeConnectService _instance =
      StripeConnectService._internal();
  factory StripeConnectService() => _instance;
  StripeConnectService._internal();

  /// Whether a Stripe onboarding session is currently in progress.
  bool isOnboardingInProgress = false;

  /// The last error encountered during onboarding, if any.
  String? lastError;

  final StreamController<StripeOnboardingResult> _completionController =
      StreamController<StripeOnboardingResult>.broadcast();

  /// Stream of onboarding completion results.
  ///
  /// Listen to this for internal notifications when onboarding finishes.
  Stream<StripeOnboardingResult> get onOnboardingComplete =>
      _completionController.stream;

  /// Start the Stripe Connect onboarding flow.
  ///
  /// Launches [url] (a Stripe Connect onboarding link) in the system browser.
  /// The user completes Stripe's onboarding there; Stripe redirects back to
  /// `zirofitapp://stripe-return` which is handled by [handleDeepLink].
  ///
  /// If onboarding is already in progress, this call is a no-op.
  Future<void> startOnboarding(String url) async {
    if (isOnboardingInProgress) {
      debugPrint(
        'StripeConnectService: Onboarding already in progress, ignoring.',
      );
      return;
    }

    isOnboardingInProgress = true;
    lastError = null;
    notifyListeners();

    debugPrint('StripeConnectService: Starting onboarding with $url');

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _failOnboarding('Invalid onboarding URL: $url');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _failOnboarding('Failed to launch browser for onboarding URL.');
      }
    } catch (e) {
      _failOnboarding('Error launching onboarding URL: $e');
    }
  }

  /// Cancel the in-progress onboarding session.
  ///
  /// Marks the flow as cancelled and emits a failure result on
  /// [onOnboardingComplete].
  void cancelOnboarding() {
    if (!isOnboardingInProgress) return;
    debugPrint('StripeConnectService: Cancelling onboarding.');
    _completeOnboarding(const StripeOnboardingResult(
      success: false,
      errorMessage: 'Onboarding cancelled by user.',
    ));
  }

  /// Handle the deep link callback from Stripe Connect onboarding.
  ///
  /// Called by [DeepLinkService] (via [bootstrap.dart]) when a
  /// `zirofitapp://stripe-return` URL is received. Parses the query
  /// parameters from the Stripe redirect and emits the result.
  void handleDeepLink(Uri uri) {
    debugPrint('StripeConnectService: Handling deep link: $uri');

    final success = uri.queryParameters['success'];
    final accountId = uri.queryParameters['account_id'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];

    if (success == 'true' && accountId != null && accountId.isNotEmpty) {
      _completeOnboarding(StripeOnboardingResult(
        success: true,
        accountId: accountId,
        state: state,
      ));
    } else {
      _completeOnboarding(StripeOnboardingResult(
        success: false,
        errorMessage: error ?? 'Unknown error during Stripe onboarding.',
        state: state,
      ));
    }
  }

  void _failOnboarding(String error) {
    lastError = error;
    _completeOnboarding(StripeOnboardingResult(
      success: false,
      errorMessage: error,
    ));
  }

  void _completeOnboarding(StripeOnboardingResult result) {
    isOnboardingInProgress = false;
    if (!result.success && result.errorMessage != null) {
      lastError = result.errorMessage;
    }
    notifyListeners();
    _completionController.add(result);
  }

  @override
  void dispose() {
    _completionController.close();
    super.dispose();
  }
}
