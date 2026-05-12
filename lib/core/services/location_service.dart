import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Location permission status enum
enum LocationPermissionStatus {
  /// Permission has not been requested yet
  notDetermined,

  /// Permission was denied
  denied,

  /// Permission was denied forever
  deniedForever,

  /// Permission was granted
  allowed,
}

/// Singleton service for location management.
///
/// Handles permission requests, current position retrieval, and
/// reverse geocoding to derive the user's current city.
/// Extends [ChangeNotifier] so widgets can listen for state changes.
class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Current user location as [LatLng] from latlong2
  LatLng? userLocation;

  /// Current location permission status
  LocationPermissionStatus authStatus = LocationPermissionStatus.notDetermined;

  /// Current city derived from reverse geocoding
  String? currentCity;

  /// Timestamp of the last location request (for throttling)
  DateTime? _lastRequestTime;

  /// Minimum interval between location requests
  static const Duration _throttleDuration = Duration(seconds: 5);

  /// Check whether device location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request current location with permission handling.
  ///
  /// Flow:
  /// 1. Throttle: ignore if called within 5 seconds of last request.
  /// 2. Check if location services are enabled.
  /// 3. Check / request permission.
  /// 4. On success, fetch position, update [userLocation], run
  ///    reverse geocoding to set [currentCity].
  ///
  /// Returns the [Position] if obtained, or `null` on failure / throttle.
  Future<Position?> requestLocation() async {
    // ── Throttle ──────────────────────────────────────────────────────
    if (_lastRequestTime != null &&
        DateTime.now().difference(_lastRequestTime!) < _throttleDuration) {
      return null;
    }
    _lastRequestTime = DateTime.now();

    // ── Location services enabled? ────────────────────────────────────
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      authStatus = LocationPermissionStatus.denied;
      notifyListeners();
      return null;
    }

    // ── Permissions ───────────────────────────────────────────────────
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        authStatus = LocationPermissionStatus.denied;
        notifyListeners();
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      authStatus = LocationPermissionStatus.deniedForever;
      notifyListeners();
      return null;
    }

    // Permission granted
    authStatus = LocationPermissionStatus.allowed;
    notifyListeners();

    // ── Get position ──────────────────────────────────────────────────
    final position = await getCurrentPosition();
    if (position != null) {
      userLocation = LatLng(position.latitude, position.longitude);
      await reverseGeocode(position);
      notifyListeners();
    }
    return position;
  }

  /// Fetch the current device position using [Geolocator].
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('LocationService: Error getting position: $e');
      return null;
    }
  }

  /// Reverse-geocode the given [Position] to populate [currentCity].
  Future<void> reverseGeocode(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        currentCity = placemarks.first.locality;
      }
    } catch (e) {
      debugPrint('LocationService: Error reverse geocoding: $e');
    }
  }
}
