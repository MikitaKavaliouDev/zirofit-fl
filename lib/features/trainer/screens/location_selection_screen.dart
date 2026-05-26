import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong2;

// ---------------------------------------------------------------------------
// Location Selection Screen with Service Radius
// ---------------------------------------------------------------------------

/// Trainer-facing screen to select a service location and set a service radius
/// (1–100 km). Displays an interactive map with a circle overlay showing the
/// coverage area.
class LocationSelectionScreen extends ConsumerStatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final double initialRadiusKm;

  const LocationSelectionScreen({
    super.key,
    this.initialLatitude = 40.7128,
    this.initialLongitude = -74.006,
    this.initialRadiusKm = 25,
  });

  @override
  ConsumerState<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState
    extends ConsumerState<LocationSelectionScreen> {
  late final MapController _mapController;
  late latlong2.LatLng _center;
  late double _radiusKm;
  String _address = '';
  bool _isGeocoding = false;
  bool _isLocating = false;

  static const _kUserAgent = 'ZiroFitFL/1.0';
  static const _kMinRadius = 1.0;
  static const _kMaxRadius = 100.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _center = latlong2.LatLng(
      widget.initialLatitude,
      widget.initialLongitude,
    );
    _radiusKm = widget.initialRadiusKm.clamp(_kMinRadius, _kMaxRadius);
    _reverseGeocode(_center);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Geocoding
  // --------------------------------------------------------------------------

  Future<void> _reverseGeocode(latlong2.LatLng latlng) async {
    if (_isGeocoding) return;
    setState(() => _isGeocoding = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${latlng.latitude}&lon=${latlng.longitude}'
        '&format=json&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': _kUserAgent},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          setState(
            () => _address = displayName.split(',').take(3).join(','),
          );
        }
      }
    } catch (_) {
      // Silently fail
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;
      final loc = latlong2.LatLng(position.latitude, position.longitude);
      setState(() => _center = loc);
      _mapController.move(loc, 12);
      _reverseGeocode(loc);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onMapTap(latlong2.LatLng latlng) {
    HapticFeedback.lightImpact();
    setState(() => _center = latlng);
    _reverseGeocode(latlng);
  }

  // --------------------------------------------------------------------------
  // Save
  // --------------------------------------------------------------------------

  void _save() {
    final result = {
      'latitude': _center.latitude,
      'longitude': _center.longitude,
      'radiusKm': _radiusKm,
      'address': _address,
    };
    Navigator.pop(context, result);
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Location & Radius'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 11,
                    onTap: (_, latlng) => _onMapTap(latlng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.zirofit.fl',
                    ),
                    // Circle overlay for service radius
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _center,
                          radius: _radiusKm * 1000.0 / _zoomToMeters(11),
                          color: colorScheme.primary
                              .withValues(alpha: 0.15),
                          borderColor: colorScheme.primary,
                          borderStrokeWidth: 2.0,
                        ),
                      ],
                    ),
                    // Center marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _center,
                          child: Icon(
                            Icons.location_on_rounded,
                            color: colorScheme.primary,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Current location button
                Positioned(
                  top: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'current_location',
                    onPressed: _useCurrentLocation,
                    child: _isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
                // Address label
                if (_address.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _address,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isGeocoding)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Radius slider
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Radius header
                  Row(
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Service Radius',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set the area you\'re willing to travel for sessions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Radius value display
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_radiusKm.round()} km',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Slider
                  Slider(
                    value: _radiusKm,
                    min: _kMinRadius,
                    max: _kMaxRadius,
                    divisions: 99,
                    label: '${_radiusKm.round()} km',
                    onChanged: (value) {
                      setState(() => _radiusKm = value);
                    },
                  ),

                  // Min/Max labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_kMinRadius.round()} km',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${_kMaxRadius.round()} km',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Approximate meters per pixel at a given zoom level.
  double _zoomToMeters(double zoom) {
    // Each zoom level halves the visible distance.
    // At zoom 11, 1 pixel ≈ 38.2 meters at the equator.
    return 38.2 * (1 << (11 - zoom.round()).clamp(0, 20));
  }
}
