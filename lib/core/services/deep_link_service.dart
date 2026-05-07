import 'dart:async';
import 'package:app_links/app_links.dart';

/// Types of deep link routes supported by the app.
enum DeepLinkRouteType {
  /// zirofitapp://auth/callback?access_token=xxx
  authCallback,

  /// zirofitapp://events/{id}
  eventDetail,

  /// zirofitapp://trainer/{id}
  trainerProfile,

  /// zirofitapp://workout/{id}
  workout,
}

/// A parsed deep link route containing the route type and extracted parameters.
class DeepLinkRoute {
  /// The type of deep link route.
  final DeepLinkRouteType type;

  /// Extracted query and path parameters as a string map.
  final Map<String, String> params;

  const DeepLinkRoute({required this.type, required this.params});

  /// Access token from auth callback URL (?access_token=xxx).
  String? get accessToken => params['access_token'];

  /// Event ID from events deep link (zirofitapp://events/{id}).
  String? get eventId => params['event_id'];

  /// Trainer ID from trainer deep link (zirofitapp://trainer/{id}).
  String? get trainerId => params['trainer_id'];

  /// Workout ID from workout deep link (zirofitapp://workout/{id}).
  String? get workoutId => params['workout_id'];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepLinkRoute &&
          type == other.type &&
          _mapEquals(params, other.params);

  @override
  int get hashCode => Object.hash(type, Object.hashAll(params.entries));

  @override
  String toString() => 'DeepLinkRoute(type: $type, params: $params)';
}

/// Compares two string maps for equality.
bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// Service for handling zirofitapp:// deep links.
///
/// Parses incoming deep link URLs and provides them via [onRoute] stream.
/// Supports the following route patterns:
/// - `zirofitapp://auth/callback?access_token=xxx` → [DeepLinkRouteType.authCallback]
/// - `zirofitapp://events/{id}` → [DeepLinkRouteType.eventDetail]
/// - `zirofitapp://trainer/{id}` → [DeepLinkRouteType.trainerProfile]
/// - `zirofitapp://workout/{id}` → [DeepLinkRouteType.workout]
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  AppLinks? _appLinks;
  final StreamController<DeepLinkRoute> _routeController =
      StreamController<DeepLinkRoute>.broadcast();

  /// Stream of parsed deep link routes from incoming links.
  Stream<DeepLinkRoute> get onRoute => _routeController.stream;

  /// Initialize the service and start listening for deep links.
  ///
  /// Call once during app startup. Sets up [AppLinks] to capture
  /// both the initial link that launched the app and subsequent
  /// links while the app is running.
  Future<void> initialize() async {
    _appLinks = AppLinks();

    // Handle the link that launched the app.
    try {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        final route = parse(initialUri.toString());
        if (route != null) {
          _routeController.add(route);
        }
      }
    } catch (_) {
      // Initial link retrieval may fail on some platforms (e.g. web).
    }

    // Listen for incoming links while the app is running.
    _appLinks!.uriLinkStream.listen((uri) {
      final route = parse(uri.toString());
      if (route != null) {
        _routeController.add(route);
      }
    });
  }

  /// Parse a [url] string into a [DeepLinkRoute].
  ///
  /// Returns `null` if the URL is not a valid `zirofitapp://` link
  /// or the path/parameters don't match a known route pattern.
  ///
  /// This is a pure parsing function — no platform dependencies — making
  /// it safe to call in unit tests without mocking.
  static DeepLinkRoute? parse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.scheme != 'zirofitapp') return null;

    // The URI format is zirofitapp://{host}/{path...}
    // e.g. zirofitapp://events/evt_001 → host='events', pathSegments=['evt_001']
    // e.g. zirofitapp://auth/callback?token=x → host='auth', pathSegments=['callback']
    final host = uri.host;
    if (host.isEmpty) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // zirofitapp://auth/callback?access_token=xxx
    if (host == 'auth') {
      if (segments.isNotEmpty && segments[0] == 'callback') {
        final token = uri.queryParameters['access_token'];
        if (token == null || token.isEmpty) return null;
        return DeepLinkRoute(
          type: DeepLinkRouteType.authCallback,
          params: {'access_token': token},
        );
      }
      return null;
    }

    // zirofitapp://events/{id}
    if (host == 'events') {
      if (segments.isEmpty) return null;
      final id = segments[0];
      if (id.isEmpty) return null;
      return DeepLinkRoute(
        type: DeepLinkRouteType.eventDetail,
        params: {'event_id': id},
      );
    }

    // zirofitapp://trainer/{id}
    if (host == 'trainer') {
      if (segments.isEmpty) return null;
      final id = segments[0];
      if (id.isEmpty) return null;
      return DeepLinkRoute(
        type: DeepLinkRouteType.trainerProfile,
        params: {'trainer_id': id},
      );
    }

    // zirofitapp://workout/{id}
    if (host == 'workout') {
      if (segments.isEmpty) return null;
      final id = segments[0];
      if (id.isEmpty) return null;
      return DeepLinkRoute(
        type: DeepLinkRouteType.workout,
        params: {'workout_id': id},
      );
    }

    return null;
  }

  /// Dispose of the service and close the stream.
  ///
  /// Call when the service is no longer needed (typically during app teardown).
  void dispose() {
    _routeController.close();
  }
}
