import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong2;

/// Step 2: Map picker with address search and draggable pin.
class MapLocationStep extends ConsumerStatefulWidget {
  const MapLocationStep({super.key});

  @override
  ConsumerState<MapLocationStep> createState() => _MapLocationStepState();
}

class _MapLocationStepState extends ConsumerState<MapLocationStep> {
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();
  latlong2.LatLng? _selectedLocation;
  String _address = '';
  bool _isSearching = false;
  bool _isGeocoding = false;

  static const _kDefaultLat = 40.7128;
  static const _kDefaultLng = -74.006;
  static const _kUserAgent = 'ZiroFitFL/1.0';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) {
        final loc = latlong2.LatLng(position.latitude, position.longitude);
        setState(() => _selectedLocation = loc);
        _mapController.move(loc, 13);
        _reverseGeocode(loc);
      }
    } catch (_) {
      const loc = latlong2.LatLng(_kDefaultLat, _kDefaultLng);
      setState(() => _selectedLocation = loc);
      _mapController.move(loc, 10);
    }
  }

  /// Reverse geocode via Nominatim API.
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

  /// Forward geocode via Nominatim API.
  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': _kUserAgent},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final result = data[0] as Map<String, dynamic>;
          final lat = double.parse(result['lat'] as String);
          final lon = double.parse(result['lon'] as String);
          final displayName = result['display_name'] as String?;

          final loc = latlong2.LatLng(lat, lon);
          setState(() {
            _selectedLocation = loc;
            _address = displayName != null
                ? displayName.split(',').take(3).join(',')
                : query;
            _isSearching = false;
          });
          _mapController.move(loc, 14);
        } else {
          _showError('Could not find address');
        }
      } else {
        _showError('Search failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Could not find address. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;
      final loc = latlong2.LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = loc);
      _mapController.move(loc, 14);
      _reverseGeocode(loc);
    } catch (e) {
      if (mounted) {
        _showError('Could not get location. Check permissions.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onMapTap(latlong2.LatLng latlng) {
    HapticFeedback.lightImpact();
    setState(() => _selectedLocation = latlng);
    _reverseGeocode(latlng);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final center = _selectedLocation ??
        const latlong2.LatLng(_kDefaultLat, _kDefaultLng);
    final hasLocation = _selectedLocation != null;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Column(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 40,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Location',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Set your location so we can find\nservices near you',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search address or city',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _searchAddress(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _searchAddress,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        Icons.search_rounded,
                        color: colorScheme.onPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _useCurrentLocation,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: colorScheme.onSecondaryContainer,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Address display
          if (_address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
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
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Map
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 13,
                        onTap: (_, latlng) => _onMapTap(latlng),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.zirofit.fl',
                        ),
                        if (hasLocation)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: center,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Tap hint overlay
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Tap map to drop pin',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
