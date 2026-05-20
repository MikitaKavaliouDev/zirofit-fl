import 'package:flutter/material.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';

/// A modal bottom sheet for correcting the exercise name in a voice command.
///
/// Mirrors iOS [ExerciseSelectionView] with `title: "Change Exercise"` and
/// `hideActionIcons: true`. Provides a searchable list of known exercises;
/// tapping an exercise calls [onExerciseSelected] with the chosen name.
class VoiceCorrectionPicker extends StatefulWidget {
  final List<String> knownExercises;
  final ValueChanged<String> onExerciseSelected;

  const VoiceCorrectionPicker({
    super.key,
    required this.knownExercises,
    required this.onExerciseSelected,
  });

  /// Shows the picker as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required List<String> knownExercises,
    required ValueChanged<String> onExerciseSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceCorrectionPicker(
        knownExercises: knownExercises,
        onExerciseSelected: onExerciseSelected,
      ),
    );
  }

  @override
  State<VoiceCorrectionPicker> createState() => _VoiceCorrectionPickerState();
}

class _VoiceCorrectionPickerState extends State<VoiceCorrectionPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredExercises {
    final exercises = widget.knownExercises;
    if (_searchQuery.isEmpty) return exercises;
    final query = _searchQuery.toLowerCase();
    return exercises.where((e) => e.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;
    final filtered = _filteredExercises;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: colors.backgroundTertiary,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  'Change Exercise',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colors.backgroundTertiary,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Exercise list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No exercises available'
                              : 'No matching exercises',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      return ListTile(
                        title: Text(exercise),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          widget.onExerciseSelected(exercise);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
