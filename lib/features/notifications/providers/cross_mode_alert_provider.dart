import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/providers/fcm_provider.dart';
import 'package:zirofit_fl/core/services/fcm_service.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Describes an active cross-mode alert state.
///
/// When [isAlertActive] is `true`, ZiroShell should present an AlertDialog
/// offering to switch to the [targetRole] mode.
class CrossModeAlertState {
  /// The role the notification requires (e.g. 'trainer' or 'client').
  final String targetRole;

  /// The notification title to display in the dialog.
  final String notificationTitle;

  /// Whether the alert is currently active.
  final bool isAlertActive;

  /// The `notification_type` from the FCM payload, used for post-switch navigation.
  final String? notificationType;

  /// The entity `id` from the FCM payload, used for post-switch navigation.
  final String? notificationId;

  /// Raw FCM data payload, preserved so the caller can route to the correct
  /// screen after a successful mode switch.
  final Map<String, dynamic> data;

  const CrossModeAlertState({
    required this.targetRole,
    required this.notificationTitle,
    required this.isAlertActive,
    this.notificationType,
    this.notificationId,
    this.data = const {},
  });
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Watched by ZiroShell to detect cross-mode notification alerts.
///
/// `null` state means no alert is active. A non-null state with
/// [CrossModeAlertState.isAlertActive] triggers the dialog.
final crossModeAlertProvider =
    StateNotifierProvider<CrossModeAlertNotifier, CrossModeAlertState?>(
  (ref) {
    final fcmService = ref.watch(fcmServiceProvider);
    return CrossModeAlertNotifier(fcmService: fcmService, ref: ref);
  },
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CrossModeAlertNotifier extends StateNotifier<CrossModeAlertState?> {
  final FcmService _fcmService;
  final Ref _ref;
  StreamSubscription<FcmMessage>? _subscription;

  CrossModeAlertNotifier({
    required FcmService fcmService,
    required Ref ref,
  })  : _fcmService = fcmService,
        _ref = ref,
        super(null) {
    _startListening();
  }

  void _startListening() {
    _subscription = _fcmService.onMessage.listen(_handleMessage);
  }

  /// Evaluates every incoming FCM message for a role mismatch.
  ///
  /// When the notification's `role` data field differs from the current auth
  /// role AND the user's preference allows cross-mode alerts for this
  /// direction, emits an alert state.
  void _handleMessage(FcmMessage message) {
    final data = message.message.data;
    final targetRole = data['role'] as String?;
    if (targetRole == null) return;

    final authState = _ref.read(authProvider);
    final currentRole = authState.role;
    if (currentRole == null || currentRole == targetRole) return;

    // Respect user preference flags for cross-mode notification alerts.
    final preferences = _ref.read(preferencesProvider);
    final shouldShow = _shouldShowAlert(
      targetRole: targetRole,
      currentRole: currentRole,
      preferences: preferences,
    );
    if (!shouldShow) return;

    final title =
        message.message.notification?.title ?? 'Notification';

    state = CrossModeAlertState(
      targetRole: targetRole,
      notificationTitle: title,
      isAlertActive: true,
      notificationType: data['notification_type'] as String?,
      notificationId: data['id'] as String?,
      data: data,
    );
  }

  /// Returns `true` when the user's preferences allow an alert for a
  /// notification targeting [targetRole] while the current mode is
  /// [currentRole].
  bool _shouldShowAlert({
    required String targetRole,
    required String currentRole,
    required PreferencesState preferences,
  }) {
    if (targetRole == 'trainer' && currentRole == 'client') {
      return preferences.showTrainerNotificationsInClientMode;
    }
    if (targetRole == 'client' && currentRole == 'trainer') {
      return preferences.showClientNotificationsInTrainerMode;
    }
    return false;
  }

  /// Clears the active alert.
  void dismiss() {
    state = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
