import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// FCM message classification
// ---------------------------------------------------------------------------

/// How the push notification was received.
enum FcmMessageType {
  /// Received while the app is in the foreground.
  foreground,

  /// App was in the background and user tapped the notification.
  background,

  /// App was terminated and the notification launched it.
  terminated,
}

/// A push notification event containing the original [RemoteMessage] and
/// how it was received ([type]).
class FcmMessage {
  final FcmMessageType type;
  final RemoteMessage message;

  const FcmMessage({required this.type, required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FcmMessage &&
          type == other.type &&
          message.messageId == other.message.messageId &&
          message.data == other.message.data;

  @override
  int get hashCode => Object.hash(type, message.messageId, message.data);

  @override
  String toString() => 'FcmMessage(type: $type, data: ${message.data})';
}

// ---------------------------------------------------------------------------
// Notification tap → navigation helpers
// ---------------------------------------------------------------------------

/// Keys used in the push notification data payload for navigation.
class FcmNotificationKeys {
  FcmNotificationKeys._();

  /// Screen type, e.g. "chat", "event", "workout", "notification".
  static const String screen = 'screen';

  /// Entity ID the notification refers to.
  static const String id = 'id';

  /// Screen type values.
  static const String screenChat = 'chat';
  static const String screenEvent = 'event';
  static const String screenWorkout = 'workout';
  static const String screenNotification = 'notification';
}

/// Determines the GoRouter location from an [FcmMessage] notification payload.
///
/// Returns `null` when the payload doesn't contain enough info to navigate.
String? routeForFcmMessage(FcmMessage message) {
  final data = message.message.data;
  final screen = data[FcmNotificationKeys.screen];
  final id = data[FcmNotificationKeys.id];

  switch (screen) {
    case FcmNotificationKeys.screenChat:
      if (id != null && id.isNotEmpty) {
        // Navigate to the appropriate chat route; role-specific path is set
        // by the caller or can default to chat list.
        return '/chat/$id';
      }
      return '/chat';

    case FcmNotificationKeys.screenEvent:
      if (id != null && id.isNotEmpty) {
        return '/events/$id';
      }
      return '/events';

    case FcmNotificationKeys.screenWorkout:
      if (id != null && id.isNotEmpty) {
        return '/workout/$id';
      }
      return '/client/workout';

    case FcmNotificationKeys.screenNotification:
      return '/notifications';

    default:
      // Generic fallback — navigate to the notifications list so the user
      // can see the full notification history.
      return '/notifications';
  }
}

/// Invoked when the user taps a push notification (background or terminated).
///
/// Pushes the resolved route via [router], falling back to `/notifications`.
void handleNotificationTap(FcmMessage message, GoRouter router) {
  final route = routeForFcmMessage(message);
  if (route != null) {
    router.go(route);
  } else {
    router.go('/notifications');
  }
}

// ---------------------------------------------------------------------------
// FCM Service
// ---------------------------------------------------------------------------

/// Service responsible for Firebase Cloud Messaging lifecycle.
///
/// Handles:
/// - FCM token retrieval and refresh listening
/// - Foreground, background, and terminated message streams
/// - Notification tap → navigation dispatch
///
/// Designed to be injectable for testing. Use [FcmService.create] in
/// production or construct directly with overridden streams for tests.
class FcmService {
  // ---------------------------------------------------------------------------
  // Dependencies (injectable)
  // ---------------------------------------------------------------------------

  final FirebaseMessaging messaging;
  final Stream<RemoteMessage> foregroundMessageStream;
  final Stream<RemoteMessage> backgroundOpenStream;

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  final StreamController<FcmMessage> _messageController =
      StreamController<FcmMessage>.broadcast();

  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _backgroundOpenSubscription;

  String? _currentToken;

  // ---------------------------------------------------------------------------
  // Factory / constructor
  // ---------------------------------------------------------------------------

  /// Creates the service with real Firebase dependencies.
  static FcmService create() {
    return FcmService(
      messaging: FirebaseMessaging.instance,
      foregroundMessageStream: FirebaseMessaging.onMessage,
      backgroundOpenStream: FirebaseMessaging.onMessageOpenedApp,
    );
  }

  FcmService({
    required this.messaging,
    required this.foregroundMessageStream,
    required this.backgroundOpenStream,
  });

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Stream of all push notification events (foreground, background, terminated).
  Stream<FcmMessage> get onMessage => _messageController.stream;

  /// Stream of FCM token changes (initial token + refresh).
  Stream<String> get onToken => _tokenController.stream;

  /// The most recently retrieved FCM token, or `null` before initialization.
  String? get currentToken => _currentToken;

  /// Initializes all message listeners.
  ///
  /// [Firebase.initializeApp] must have been called before this (typically
  /// in the app bootstrap or main function).
  ///
  /// Call once during app startup (e.g. in [AppBootstrap.initialize]).
  Future<void> initialize() async {
    await _requestPermission();
    await _fetchToken();
    _listenToTokenRefresh();
    _listenToForegroundMessages();
    _listenToBackgroundMessageOpens();
    await _handleInitialMessage();

    debugPrint('[FcmService] initialized — token: $_currentToken');
  }

  /// Tears down all listeners and closes streams.
  ///
  /// Call when the service is no longer needed.
  void dispose() {
    _tokenSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _backgroundOpenSubscription?.cancel();
    _messageController.close();
    _tokenController.close();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<void> _requestPermission() async {
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _fetchToken() async {
    _currentToken = await messaging.getToken();
    if (_currentToken != null) {
      _tokenController.add(_currentToken!);
    }
  }

  void _listenToTokenRefresh() {
    _tokenSubscription = messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _tokenController.add(token);
    });
  }

  void _listenToForegroundMessages() {
    _foregroundSubscription = foregroundMessageStream.listen((message) {
      _messageController.add(
        FcmMessage(type: FcmMessageType.foreground, message: message),
      );
    });
  }

  void _listenToBackgroundMessageOpens() {
    _backgroundOpenSubscription = backgroundOpenStream.listen((message) {
      _messageController.add(
        FcmMessage(type: FcmMessageType.background, message: message),
      );
    });
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _messageController.add(
        FcmMessage(type: FcmMessageType.terminated, message: initialMessage),
      );
    }
  }
}
