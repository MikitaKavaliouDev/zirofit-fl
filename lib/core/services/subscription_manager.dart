import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// SubscriptionManager — Pro Status Singleton
// =============================================================================

/// Singleton that manages the user's Pro subscription status.
///
/// Currently hardcoded to `true` for the BETA period. Designed as an
/// abstraction layer for future RevenueCat / StoreKit integration.
///
/// Usage:
/// ```dart
/// final isPro = ref.watch(subscriptionManagerProvider).isPro;
/// ```
class SubscriptionManager extends ChangeNotifier {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  /// Whether the current user has an active Pro subscription.
  ///
  /// Hardcoded to `true` during the BETA period. In the future this will
  /// check against RevenueCat / StoreKit receipt validation.
  bool get isPro => true;

  /// Trigger a refresh of the subscription status from the store backend.
  ///
  /// No-op during BETA. Will later sync with RevenueCat / StoreKit.
  Future<void> refresh() async {
    // TODO: Integrate with RevenueCat / StoreKit when ready
    notifyListeners();
  }

  /// Restore purchases from the store.
  ///
  /// No-op during BETA.
  Future<bool> restorePurchases() async {
    // TODO: Integrate with RevenueCat / StoreKit when ready
    return true;
  }
}

// =============================================================================
// Riverpod Provider
// =============================================================================

final subscriptionManagerProvider = ChangeNotifierProvider<SubscriptionManager>(
  (ref) => SubscriptionManager(),
);

/// Convenience provider that exposes just the `isPro` boolean.
final isProProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionManagerProvider).isPro;
});
