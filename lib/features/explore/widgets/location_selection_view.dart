import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Location Selection View
// ---------------------------------------------------------------------------

/// Result returned when a location is selected.
class LocationSelectionResult {
  final String address;
  final double latitude;
  final double longitude;

  const LocationSelectionResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

/// A full-screen modal view for searching and selecting a geographic location.
///
/// Provides a text search field, coordinate entry fields, and a map preview
/// area. Returns a [LocationSelectionResult] via [Navigator.pop] when the
/// user confirms their selection.
///
/// Usage:
/// ```dart
/// final result = await Navigator.push<LocationSelectionResult>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => const LocationSelectionView(),
///   ),
/// );
/// ```
class LocationSelectionView extends ConsumerStatefulWidget {
  /// Optional initial address to populate the search field.
  final String? initialAddress;

  /// Optional initial latitude.
  final double? initialLatitude;

  /// Optional initial longitude.
  final double? initialLongitude;

  const LocationSelectionView({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  ConsumerState<LocationSelectionView> createState() =>
      _LocationSelectionViewState();
}

class _LocationSelectionViewState
    extends ConsumerState<LocationSelectionView> {
  late TextEditingController _addressController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  final _formKey = GlobalKey<FormState>();
  bool _isSearching = false;
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
    _latController = TextEditingController(
      text: widget.initialLatitude?.toStringAsFixed(6) ?? '',
    );
    _lonController = TextEditingController(
      text: widget.initialLongitude?.toStringAsFixed(6) ?? '',
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // -- Search Field --
            Text(
              'Search Location',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Enter city, address, or place name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _addressController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _addressController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 8),
            Text(
              'Or enter coordinates manually',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // -- Search Results --
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchResults.isNotEmpty) ...[
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Search Results',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    ..._searchResults.map(
                      (result) => ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(result),
                        trailing: const Icon(Icons.add_location_alt_outlined,
                            size: 18),
                        onTap: () {
                          _addressController.text = result;
                          // Populate with approximate coordinates
                          // (in production these would come from geocoding)
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // -- Coordinate Inputs --
            Text(
              'Coordinates',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: 'e.g. 40.7128',
                      prefixIcon: Icon(Icons.explore_outlined, size: 20),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final lat = double.tryParse(value);
                        if (lat == null || lat < -90 || lat > 90) {
                          return 'Invalid latitude (-90 to 90)';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lonController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: 'e.g. -74.0060',
                      prefixIcon: Icon(Icons.explore_outlined, size: 20),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final lon = double.tryParse(value);
                        if (lon == null || lon < -180 || lon > 180) {
                          return 'Invalid longitude (-180 to 180)';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // -- Map Preview Placeholder --
            Text(
              'Map Preview',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Map integration coming soon',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coordinates will show location on map',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // -- Action Buttons --
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _onSave,
                    child: const Text('Save Location'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch() {
    final query = _addressController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    // Simulate search delay. In production this would call a geocoding API
    // (e.g. Google Places, Mapbox, or Nominatim).
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResults = [
          '$query, New York, NY',
          '$query, Los Angeles, CA',
          '$query, Chicago, IL',
        ];
      });
    });
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final address = _addressController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    if (address.isEmpty && (lat == null || lon == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an address or coordinates.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      LocationSelectionResult(
        address: address.isNotEmpty
            ? address
            : '$lat, $lon',
        latitude: lat ?? 0,
        longitude: lon ?? 0,
      ),
    );
  }
}
