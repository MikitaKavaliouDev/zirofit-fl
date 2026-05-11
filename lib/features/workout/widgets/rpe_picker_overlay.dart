import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';

// ---------------------------------------------------------------------------
// RPE value descriptors
// ---------------------------------------------------------------------------

/// A single RPE value with its label and description.
class _RpeEntry {
  final double value;
  final String label;
  final String description;

  const _RpeEntry({
    required this.value,
    required this.label,
    required this.description,
  });
}

const List<_RpeEntry> _kRpeValues = [
  _RpeEntry(value: 5.0, label: '5.0', description: 'Light warm-up'),
  _RpeEntry(value: 5.5, label: '5.5', description: 'Getting started'),
  _RpeEntry(value: 6.0, label: '6.0', description: 'Comfortable'),
  _RpeEntry(value: 6.5, label: '6.5', description: 'Light effort'),
  _RpeEntry(value: 7.0, label: '7.0', description: 'Moderate'),
  _RpeEntry(value: 7.5, label: '7.5', description: 'Somewhat hard'),
  _RpeEntry(value: 8.0, label: '8.0', description: 'Hard'),
  _RpeEntry(value: 8.5, label: '8.5', description: 'Very hard'),
  _RpeEntry(value: 9.0, label: '9.0', description: 'Extremely hard'),
  _RpeEntry(value: 9.5, label: '9.5', description: 'Near maximal'),
  _RpeEntry(value: 10.0, label: '10.0', description: 'Maximal effort'),
];

// ---------------------------------------------------------------------------
// RPEPickerOverlay
// ---------------------------------------------------------------------------

/// A modal bottom sheet for selecting RPE (Rate of Perceived Exertion) and
/// optionally RIR (Reps in Reserve).
///
/// Features:
/// - Horizontal scrollable list of RPE values (5.0 → 10.0, step 0.5)
/// - Description text below each value
/// - Visual highlight on the selected value
/// - RIR input (0–5) using a slider / chip row
/// - Apply button that saves to [WorkoutEnhancementNotifier]
class RPEPickerOverlay extends ConsumerStatefulWidget {
  final void Function(double rpe)? onSelected;
  final VoidCallback? onDismiss;

  const RPEPickerOverlay({
    super.key,
    this.onSelected,
    this.onDismiss,
  });

  /// Shows this overlay as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const RPEPickerOverlay(),
    );
  }

  @override
  ConsumerState<RPEPickerOverlay> createState() => _RPEPickerOverlayState();
}

class _RPEPickerOverlayState extends ConsumerState<RPEPickerOverlay> {
  late double? _selectedRpe;
  late double? _selectedRir;

  @override
  void initState() {
    super.initState();
    final rpeState = ref.read(workoutEnhancementProvider).rpeState;
    _selectedRpe = rpeState.currentRpe;
    _selectedRir = rpeState.currentRir;
  }

  void _apply() {
    final notifier = ref.read(workoutEnhancementProvider.notifier);
    if (_selectedRpe != null) {
      notifier.setRpe(_selectedRpe!);
      widget.onSelected?.call(_selectedRpe!);
    }
    if (_selectedRir != null) {
      notifier.setRir(_selectedRir!);
    }
    
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grab handle
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.speed, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Rate of Perceived Exertion',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'How hard was that set?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Horizontal RPE scroll ──
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _kRpeValues.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entry = _kRpeValues[index];
                final isSelected = _selectedRpe == entry.value;
                return _RpeChip(
                  entry: entry,
                  isSelected: isSelected,
                  theme: theme,
                  onTap: () {
                    setState(() => _selectedRpe = entry.value);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── RIR selector ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Reps in Reserve (RIR)',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedRir != null
                          ? '${_selectedRir!.toStringAsFixed(0)} reps'
                          : 'Not set',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // RIR chips 0–5
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: List.generate(6, (i) {
                    final isSelected = _selectedRir == i.toDouble();
                    return ChoiceChip(
                      label: Text('$i'),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedRir =
                              _selectedRir == i.toDouble() ? null : i.toDouble();
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Apply button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedRpe != null ? _apply : null,
                child: Text(
                  _selectedRpe != null
                      ? 'Apply RPE ${_selectedRpe!.toStringAsFixed(1)}'
                      : 'Select an RPE value',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RPE Chip
// ---------------------------------------------------------------------------

class _RpeChip extends StatelessWidget {
  final _RpeEntry entry;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _RpeChip({
    required this.entry,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              entry.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              entry.description,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
