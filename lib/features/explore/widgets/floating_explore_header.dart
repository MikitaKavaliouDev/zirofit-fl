import 'package:flutter/material.dart';

/// Floating header for Explore screen - city selector + search + map buttons.
///
/// Usage:
/// ```dart
/// FloatingExploreHeader(
///   selectedCity: state.locationFilter,
///   onCityTap: () => showCityPicker(...),
///   onSearchTap: () => Navigator.push(...TrainerDiscoveryScreen),
///   onMapTap: () => Navigator.push(...TrainerMapScreen),
/// )
/// ```
class FloatingExploreHeader extends StatelessWidget {
  final String? selectedCity;
  final VoidCallback onCityTap;
  final VoidCallback onSearchTap;
  final VoidCallback onMapTap;

  const FloatingExploreHeader({
    super.key,
    this.selectedCity,
    required this.onCityTap,
    required this.onSearchTap,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // City selector
            Expanded(
              child: InkWell(
                onTap: onCityTap,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        selectedCity ?? 'Select City',
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            // Search button
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: onSearchTap,
              tooltip: 'Search trainers',
            ),
            // Map button
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: onMapTap,
              tooltip: 'View map',
            ),
          ],
        ),
      ),
    );
  }
}