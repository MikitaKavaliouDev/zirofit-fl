import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/services/haptic_service.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';

// ---------------------------------------------------------------------------
// RPE value descriptors (iOS-style: reps-left descriptions)
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

/// Descriptions match the iOS RPEPickerOverlay – reps-in-reserve style labels.
const List<_RpeEntry> _kRpeValues = [
  _RpeEntry(value: 5.0, label: '5.0', description: 'Light'),
  _RpeEntry(value: 5.5, label: '5.5', description: 'Warm up'),
  _RpeEntry(value: 6.0, label: '6.0', description: '4+ reps left'),
  _RpeEntry(value: 6.5, label: '6.5', description: 'Maybe 3–4 reps left'),
  _RpeEntry(value: 7.0, label: '7.0', description: '3 reps left'),
  _RpeEntry(value: 7.5, label: '7.5', description: 'Maybe 2–3 reps left'),
  _RpeEntry(value: 8.0, label: '8.0', description: '2 reps left'),
  _RpeEntry(value: 8.5, label: '8.5', description: 'Maybe 1–2 reps left'),
  _RpeEntry(value: 9.0, label: '9.0', description: '1 rep left'),
  _RpeEntry(value: 9.5, label: '9.5', description: 'Maybe 0 reps left'),
  _RpeEntry(value: 10.0, label: '10.0', description: 'Max effort'),
];

const List<_RirEntry> _kRirValues = [
  _RirEntry(value: 0, label: '0', description: 'Max effort'),
  _RirEntry(value: 1, label: '1', description: '1 rep left'),
  _RirEntry(value: 2, label: '2', description: '2 reps left'),
  _RirEntry(value: 3, label: '3', description: '3 reps left'),
  _RirEntry(value: 4, label: '4', description: '4 reps left'),
  _RirEntry(value: 5, label: '5', description: '5+ reps left'),
];

class _RirEntry {
  final int value;
  final String label;
  final String description;

  const _RirEntry({
    required this.value,
    required this.label,
    required this.description,
  });
}

// ---------------------------------------------------------------------------
// RPEPickerOverlay
// ---------------------------------------------------------------------------

/// A picker overlay for selecting RPE (Rate of Perceived Exertion) and
/// RIR (Reps in Reserve), matching the iOS RPEPickerOverlay behaviour.
///
/// Features:
/// - Horizontal scrollable list of RPE values (5.0 → 10.0, step 0.5)
/// - iOS-style reps-left descriptions below each value
/// - Visual highlight on the selected value
/// - RIR chip selector (0–5) with descriptions
/// - Apply button that saves to [WorkoutEnhancementNotifier]
/// - Optional inline mode (no bottom-sheet wrapper)
/// - Haptic feedback on selection
class RPEPickerOverlay extends ConsumerStatefulWidget {
  final void Function(double rpe)? onSelected;
  final VoidCallback? onDismiss;
  final bool isInline;

  const RPEPickerOverlay({
    super.key,
    this.onSelected,
    this.onDismiss,
    this.isInline = false,
  });

  /// Shows this overlay as a modal bottom sheet (legacy entry point).
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
  late int? _selectedRir;

  @override
  void initState() {
    super.initState();
    final rpeState = ref.read(workoutEnhancementProvider).rpeState;
    _selectedRpe = rpeState.currentRpe;
    _selectedRir = rpeState.currentRir?.toInt();
  }

  void _onSelectRpe(double value) {
    HapticService().mediumImpact();
    setState(() => _selectedRpe = value);
    // Also clear RIR when RPE is selected (they're complementary)
    if (_selectedRir != null) {
      setState(() => _selectedRir = null);
    }
  }

  void _onSelectRir(int value) {
    HapticService().selection();
    setState(() {
      _selectedRir = _selectedRir == value ? null : value;
    });
    // Also clear RPE when RIR is selected
    if (_selectedRpe != null) {
      setState(() => _selectedRpe = null);
    }
  }

  void _apply() {
    HapticService().lightImpact();
    final notifier = ref.read(workoutEnhancementProvider.notifier);
    if (_selectedRpe != null) {
      notifier.setRpe(_selectedRpe!);
      widget.onSelected?.call(_selectedRpe!);
    }
    if (_selectedRir != null) {
      notifier.setRir(_selectedRir!.toDouble());
    }
    _dismiss();
  }

  void _dismiss() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else if (!widget.isInline) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Grab handle (only when not inline) ──
          if (!widget.isInline)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

          // ── Header row ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              widget.isInline ? 0 : 0,
              24,
              0,
            ),
            child: Row(
              children: [
                Icon(Icons.speed, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rate of Perceived Exertion',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedRpe != null || _selectedRir != null)
                  GestureDetector(
                    onTap: () {
                      HapticService().lightImpact();
                      setState(() {
                        _selectedRpe = null;
                        _selectedRir = null;
                      });
                    },
                    child: Text(
                      'Clear',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'How many reps did you have left?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Horizontal RPE scroll ──
          SizedBox(
            height: 110,
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
                  onTap: () => _onSelectRpe(entry.value),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── RIR selector ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.repeat, color: cs.onSurfaceVariant, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Reps in Reserve (RIR)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // RIR chips 0–5 with descriptions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_kRirValues.length, (i) {
                    final entry = _kRirValues[i];
                    final isSelected = _selectedRir == entry.value;
                    return _RirChip(
                      entry: entry,
                      isSelected: isSelected,
                      theme: theme,
                      onTap: () => _onSelectRir(entry.value),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Apply button ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              widget.isInline ? 0 : 24,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed:
                    (_selectedRpe != null || _selectedRir != null)
                        ? _apply
                        : null,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _buildApplyLabel(),
              ),
            ),
          ),

          // Bottom spacing when inline so it doesn't hug
          if (widget.isInline) const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildApplyLabel() {
    if (_selectedRpe != null) {
      return Text('Apply RPE ${_selectedRpe!.toStringAsFixed(1)}');
    }
    if (_selectedRir != null) {
      return Text('Apply RIR $_selectedRir');
    }
    return const Text('Select RPE or RIR');
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
    final cs = theme.colorScheme;
    final accent = cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.15)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: accent, width: 2)
                : Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                    width: 1,
                  ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? accent : cs.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.description,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? accent : cs.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RIR Chip
// ---------------------------------------------------------------------------

class _RirChip extends StatelessWidget {
  final _RirEntry entry;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _RirChip({
    required this.entry,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final accent = cs.secondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: accent, width: 2)
              : Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? accent : cs.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              entry.description,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? accent : cs.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
