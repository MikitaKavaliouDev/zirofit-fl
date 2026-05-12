import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';

/// iOS-style filter bottom sheet for trainer discovery.
///
/// Presents sections for sort order, location, specialty multi-select,
/// minimum rating slider, and a reset-all button.
///
/// Usage:
/// ```dart
/// final applied = await DiscoveryFilterSheet.show(context);
/// ```
class DiscoveryFilterSheet extends ConsumerStatefulWidget {
  const DiscoveryFilterSheet({super.key});

  /// Returns `true` if the user tapped Apply (filters may have changed).
  static Future<bool> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FilterSheetShell(),
    ).then((result) => result ?? false);
  }

  @override
  ConsumerState<DiscoveryFilterSheet> createState() =>
      _DiscoveryFilterSheetState();
}

/// Thin shell so [show] can use a plain [ConsumerWidget] builder.
class _FilterSheetShell extends ConsumerWidget {
  const _FilterSheetShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DiscoveryFilterSheet();
  }
}

class _DiscoveryFilterSheetState extends ConsumerState<DiscoveryFilterSheet> {
  late DiscoverySortBy? _sortBy;
  late TextEditingController _locationController;
  late List<String> _selectedSpecialties;
  late double _minRating;

  @override
  void initState() {
    super.initState();
    final state = ref.read(exploreProvider);
    _sortBy = state.sortBy;
    _locationController = TextEditingController(text: state.locationFilter ?? '');
    _selectedSpecialties = List<String>.from(state.selectedSpecialties);
    _minRating = state.minRating ?? 0;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _toggleSpecialty(String specialty) {
    setState(() {
      if (_selectedSpecialties.contains(specialty)) {
        _selectedSpecialties.remove(specialty);
      } else {
        _selectedSpecialties.add(specialty);
      }
    });
  }

  void _resetAll() {
    setState(() {
      _sortBy = null;
      _locationController.clear();
      _selectedSpecialties.clear();
      _minRating = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final state = ref.watch(exploreProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: mediaQuery.viewInsets.bottom + 16,
          ),
          child: Column(
            children: [
              // ── Handle bar ──────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Title row ────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Filters',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _resetAll,
                    child: Text(
                      'Reset All',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Scrollable content ──────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // ── Sort By ───────────────────────────────────────
                    _sectionHeader(theme, 'Sort By'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<DiscoverySortBy>(
                        segments: DiscoverySortBy.values.map((sort) {
                          return ButtonSegment<DiscoverySortBy>(
                            value: sort,
                            label: Text(
                              sort.label,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        selected: _sortBy != null ? {_sortBy!} : {},
                        onSelectionChanged: (selected) {
                          setState(() => _sortBy = selected.firstOrNull);
                        },
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          textStyle: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Location ──────────────────────────────────────
                    _sectionHeader(theme, 'Location'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'City or region…',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // ── Specialty (multi-select) ─────────────────────
                    _sectionHeader(theme, 'Specialty'),
                    const SizedBox(height: 8),
                    if (state.specialties.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No specialties available',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.specialties.map((specialty) {
                          final isSelected =
                              _selectedSpecialties.contains(specialty);
                          return FilterChip(
                            label: Text(specialty),
                            selected: isSelected,
                            onSelected: (_) => _toggleSpecialty(specialty),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),

                    // ── Minimum Rating ────────────────────────────────
                    _sectionHeader(theme, 'Minimum Rating'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _minRating == 0
                              ? 'Any'
                              : _minRating.toStringAsFixed(1),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _minRating > 0
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '5.0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _minRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      label: _minRating.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() => _minRating = value);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // ── Apply button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _apply() {
    final notifier = ref.read(exploreProvider.notifier);
    notifier.applyFilters(
      sortBy: _sortBy,
      location: _locationController.text.isNotEmpty
          ? _locationController.text
          : null,
      specialties:
          _selectedSpecialties.isNotEmpty ? _selectedSpecialties : null,
      minRating: _minRating > 0 ? _minRating : null,
    );
    Navigator.of(context).pop(true);
  }
}
