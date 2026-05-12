import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/services/location_service.dart';

/// Provides the singleton [LocationService] instance.
///
/// Since [LocationService] extends [ChangeNotifier], widgets can `watch`
/// this provider to react to location state changes (permission status,
/// current position, detected city) without polling.
final locationServiceProvider = ChangeNotifierProvider<LocationService>((ref) {
  return LocationService();
});
