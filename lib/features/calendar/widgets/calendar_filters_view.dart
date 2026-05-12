import 'package:flutter/material.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';

// ---------------------------------------------------------------------------
// Filter Type Definitions
// ---------------------------------------------------------------------------

/// The type of filter chip in a [CalendarFiltersView].
enum CalendarFilterType {
  dateRange,
  trainer,
  client,
  workoutType,
}

/// A single filter option within a filter group.
class CalendarFilterOption {
  final String id;
  final String label;
  final IconData? icon;

  const CalendarFilterOption({
    required this.id,
    required this.label,
    this.icon,
  });
}

/// A group of related filter chips.
class CalendarFilterGroup {
  final CalendarFilterType type;
  final String label;
  final List<CalendarFilterOption> options;
  final bool allowMultiple;

  const CalendarFilterGroup({
    required this.type,
    required this.label,
    required this.options,
    this.allowMultiple = false,
  });
}

// ---------------------------------------------------------------------------
// CalendarFiltersView
// ---------------------------------------------------------------------------

/// Horizontal scrollable filter chips for the calendar view.
///
/// Each filter group is rendered as a labeled section with horizontally
/// scrollable chips. Selected chips use the accent color fill; unselected
/// chips use an outline style. Supports both single-select (date range,
/// workout type) and multi-select (trainer, client) modes.
///
/// Mirrors iOS [CalendarFiltersView].
class CalendarFiltersView extends StatelessWidget {
  /// The filter groups to display.
  final List<CalendarFilterGroup> groups;

  /// Currently selected option IDs (single-select groups).
  final Map<CalendarFilterType, String> selectedIds;

  /// Currently selected option IDs (multi-select groups).
  final Map<CalendarFilterType, Set<String>> multiSelectedIds;

  /// Called when a single-select chip is tapped.
  final void Function(CalendarFilterType type, String id)? onFilterChanged;

  /// Called when a multi-select chip is toggled.
  final void Function(
      CalendarFilterType type, String id, bool selected)? onMultiFilterChanged;

  const CalendarFiltersView({
    super.key,
    required this.groups,
    this.selectedIds = const {},
    this.multiSelectedIds = const {},
    this.onFilterChanged,
    this.onMultiFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: themeColors.backgroundPrimary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: groups.map((group) => _buildFilterGroup(context, group)).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterGroup(BuildContext context, CalendarFilterGroup group) {
    final accent = context.themeColors.accent;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          for (int i = 0; i < group.options.length; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
              child: _FilterChip(
                label: group.options[i].label,
                icon: group.options[i].icon,
                isSelected: _isSelected(group, group.options[i]),
                accentColor: accent,
                onTap: () => _onChipTap(group, group.options[i]),
              ),
            ),
        ],
      ),
    );
  }

  bool _isSelected(CalendarFilterGroup group, CalendarFilterOption option) {
    if (group.allowMultiple) {
      return multiSelectedIds[group.type]?.contains(option.id) ?? false;
    }
    return selectedIds[group.type] == option.id;
  }

  void _onChipTap(CalendarFilterGroup group, CalendarFilterOption option) {
    if (group.allowMultiple) {
      final current = Set<String>.from(multiSelectedIds[group.type] ?? {});
      if (current.contains(option.id)) {
        current.remove(option.id);
      } else {
        current.add(option.id);
      }
      onMultiFilterChanged?.call(group.type, option.id, current.contains(option.id));
    } else {
      if (selectedIds[group.type] == option.id) {
        // Tapping the already-selected chip deselects it
        onFilterChanged?.call(group.type, '');
      } else {
        onFilterChanged?.call(group.type, option.id);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// _FilterChip
// ---------------------------------------------------------------------------

/// A single filter chip with selected/unselected styling.
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : accentColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
