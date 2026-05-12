import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;

import 'package:zirofit_fl/features/onboarding/providers/onboarding_provider.dart';

/// Step 7: Find nearby trainers on map with filterable list.
class TrainerFinderStep extends ConsumerStatefulWidget {
  const TrainerFinderStep({super.key});

  @override
  ConsumerState<TrainerFinderStep> createState() => _TrainerFinderStepState();
}

class _TrainerFinderStepState extends ConsumerState<TrainerFinderStep> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  bool _showList = false;

  static const _kDefaultLat = 40.7128;
  static const _kDefaultLng = -74.006;

    // Mock trainers for demonstration
  final List<_MockTrainer> _trainers = const [
    _MockTrainer(
      id: 't1',
      name: 'Alex Johnson',
      specialty: 'Strength & Conditioning',
      rating: 4.9,
      lat: 40.7138,
      lng: -74.005,
    ),
    _MockTrainer(
      id: 't2',
      name: 'Sarah Chen',
      specialty: 'Yoga & Flexibility',
      rating: 4.8,
      lat: 40.7118,
      lng: -74.008,
    ),
    _MockTrainer(
      id: 't3',
      name: 'Marcus Williams',
      specialty: 'Weight Loss & Nutrition',
      rating: 4.7,
      lat: 40.7148,
      lng: -74.003,
    ),
    _MockTrainer(
      id: 't4',
      name: 'Priya Patel',
      specialty: 'Endurance & Cardio',
      rating: 4.9,
      lat: 40.7108,
      lng: -74.007,
    ),
  ];

  List<_MockTrainer> get _filteredTrainers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _trainers;
    return _trainers.where((t) {
      return t.name.toLowerCase().contains(query) ||
          t.specialty.toLowerCase().contains(query);
    }).toList();
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
    final filtered = _filteredTrainers;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 12),
            child: Column(
              children: [
                Icon(
                  Icons.people_rounded,
                  size: 40,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Find Your Trainer',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Browse nearby trainers or skip this step',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Search + toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by name or specialty',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: _showList
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _showList = !_showList);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        _showList ? Icons.map_rounded : Icons.list_rounded,
                        color: _showList
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Map or List view
          Expanded(
            child: _showList ? _buildListView(filtered, theme, colorScheme) : _buildMapView(colorScheme),
          ),

          // Skip hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'You can skip this and find a trainer later',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(ColorScheme colorScheme) {
    final lat = ref.watch(onboardingProvider).latitude ?? _kDefaultLat;
    final lng = ref.watch(onboardingProvider).longitude ?? _kDefaultLng;
    final center = latlong2.LatLng(lat, lng);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.zirofit.fl',
            ),
            MarkerLayer(
              markers: _trainers.map((t) {
                final isSelected =
                    ref.watch(onboardingProvider).trainerId == t.id;
                return Marker(
                  point: latlong2.LatLng(t.lat, t.lng),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(onboardingProvider.notifier)
                          .setTrainerId(t.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            t.name.split(' ').first,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
    List<_MockTrainer> trainers,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (trainers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No trainers found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: trainers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = trainers[index];
        final isSelected = ref.watch(onboardingProvider).trainerId == t.id;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(onboardingProvider.notifier).setTrainerId(t.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.specialty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        t.rating.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MockTrainer {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final double lat;
  final double lng;

  const _MockTrainer({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.lat,
    required this.lng,
  });
}
