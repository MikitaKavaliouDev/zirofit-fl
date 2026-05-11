import 'package:flutter/material.dart';

/// Browse by category section - filter chips for specialty filtering.
///
/// Usage:
/// ```dart
/// BrowseByCategorySection(
///   categories: state.specialties,
///   selectedCategory: state.selectedSpecialty,
///   onCategoryTap: (category) => notifier.setSpecialty(category),
/// )
/// ```
class BrowseByCategorySection extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final void Function(String? category) onCategoryTap;

  const BrowseByCategorySection({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Browse by Category',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: categories.map((category) {
              final isSelected = category == selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => onCategoryTap(isSelected ? null : category),
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}