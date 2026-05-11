import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';

/// City picker bottom sheet.
///
/// Usage:
/// ```dart
/// final selectedCity = await CityPickerSheet.show(context);
/// if (selectedCity != null) { ... }
/// ```
class CityPickerSheet extends ConsumerStatefulWidget {
  const CityPickerSheet({super.key});

  static Future<ExploreCity?> show(BuildContext context) {
    return showModalBottomSheet<ExploreCity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CityPickerShell(),
    );
  }

  @override
  ConsumerState<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerShell extends ConsumerWidget {
  const _CityPickerShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CityPickerSheet();
  }
}

class _CityPickerSheetState extends ConsumerState<CityPickerSheet> {
  final _searchController = TextEditingController();
  List<ExploreCity> _filteredCities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    // Load metadata if cities not already loaded
    final state = ref.read(exploreProvider);
    if (state.cities.isEmpty) {
      await ref.read(exploreProvider.notifier).loadMetadata();
    }
    
    final updatedState = ref.read(exploreProvider);
    setState(() {
      _filteredCities = updatedState.cities;
      _isLoading = false;
    });
  }

  void _filterCities(String query) {
    final state = ref.read(exploreProvider);
    final cities = state.cities;
    
    if (query.isEmpty) {
      setState(() => _filteredCities = cities);
    } else {
      setState(() {
        _filteredCities = cities.where((city) {
          return city.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Select City',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search cities...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                onChanged: _filterCities,
              ),
              const SizedBox(height: 16),

              // City list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredCities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No cities found',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _filteredCities.length,
                            itemBuilder: (context, index) {
                              final city = _filteredCities[index];
                              return ListTile(
                                leading: city.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          city.imageUrl!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Icon(Icons.location_city),
                                        ),
                                      )
                                    : const Icon(Icons.location_city),
                                title: Text(city.name),
                                subtitle: city.latitude != null
                                    ? Text(
                                        '${city.latitude!.toStringAsFixed(2)}, ${city.longitude!.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodySmall,
                                      )
                                    : null,
                                onTap: () => Navigator.of(context).pop(city),
                              );
                            },
                          ),
              ),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }
}