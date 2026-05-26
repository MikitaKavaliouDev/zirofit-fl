import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/explore/widgets/marketplace_list_view.dart';
import 'package:zirofit_fl/features/explore/widgets/marketplace_map_view.dart';

/// Combined events + featured trainers marketplace screen with list/map toggle.
///
/// Mirrors iOS MarketplaceView behaviour:
/// - AppBar toggle between list and map view
/// - Search bar for filtering events/trainers
/// - Filter chips for category filtering
/// - List view shows events and featured trainers in sections
/// - Map view shows pins for events and trainers with locations
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  final List<String> _categories = [
    'All',
    'Workshop',
    'Class',
    'Seminar',
    'Competition',
    'Social',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(exploreProvider.notifier);
      notifier.loadFeatured();
      notifier.loadUpcomingEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () => setState(() => _isMapView = !_isMapView),
            tooltip: _isMapView ? 'Switch to List' : 'Switch to Map',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events and trainers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _categories.map((cat) {
                final isSelected = cat == 'All'
                    ? _selectedCategory == null
                    : _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat == 'All' ? null : cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Content area
          Expanded(
            child: _isMapView
                ? MarketplaceMapView(
                    searchQuery: _searchController.text,
                    selectedCategory: _selectedCategory,
                  )
                : MarketplaceListView(
                    searchQuery: _searchController.text,
                    selectedCategory: _selectedCategory,
                  ),
          ),
        ],
      ),
    );
  }
}
