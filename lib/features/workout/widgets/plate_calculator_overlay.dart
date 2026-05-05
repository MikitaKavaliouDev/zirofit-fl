import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/plate_calculation.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';

// ---------------------------------------------------------------------------
// PlateCalculatorOverlay
// ---------------------------------------------------------------------------

/// An overlay (AlertDialog) for calculating barbell plate configurations.
///
/// Features:
/// - Target weight input field
/// - Bar weight toggle: 20 kg (men's) / 15 kg (women's)
/// - Results display: weight per side + plate breakdown
/// - Visual barbell representation with coloured plates
/// - Powered by [calculatePlates] from the data layer
class PlateCalculatorOverlay extends ConsumerStatefulWidget {
  const PlateCalculatorOverlay({super.key});

  /// Shows this overlay as a dialog.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const PlateCalculatorOverlay(),
    );
  }

  @override
  ConsumerState<PlateCalculatorOverlay> createState() =>
      _PlateCalculatorOverlayState();
}

class _PlateCalculatorOverlayState
    extends ConsumerState<PlateCalculatorOverlay> {
  final _weightController = TextEditingController();
  double _barWeight = 20.0;
  PlateCalculation? _result;

  /// Colour mapping for each plate weight (matches standard colour-coding).
  static final Map<double, Color> _plateColors = <double, Color>{
    25: const Color(0xFFE53935), // Red
    20: const Color(0xFF1565C0), // Blue
    15: const Color(0xFFFDD835), // Yellow
    10: const Color(0xFF1B5E20), // Green
    5: const Color(0xFFFFFFFF), // White
    2.5: const Color(0xFF212121), // Black
    1.25: const Color(0xFF9E9E9E), // Grey (silver)
  };

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final text = _weightController.text.trim();
    final weight = double.tryParse(text);
    if (weight == null || weight <= 0) return;

    final notifier = ref.read(workoutEnhancementProvider.notifier);
    notifier.calculateForWeightWithBar(weight, barWeight: _barWeight);

    // Read back from the provider state
    setState(() {
      _result = ref.read(workoutEnhancementProvider).plateCalculation;
    });
  }

  void _clear() {
    _weightController.clear();
    setState(() => _result = null);
    ref.read(workoutEnhancementProvider.notifier).clearPlateCalculation();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Row(
        children: [
          Icon(Icons.calculate, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Plate Calculator',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Target weight input ──
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Total weight (kg)',
                hintText: 'e.g. 100',
                suffixIcon: _weightController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clear,
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _calculate(),
            ),

            const SizedBox(height: 16),

            // ── Bar weight toggle ──
            Row(
              children: [
                Text(
                  'Bar:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 20.0, label: Text('20 kg (men)')),
                    ButtonSegment(value: 15.0, label: Text('15 kg (women)')),
                  ],
                  selected: {_barWeight},
                  onSelectionChanged: (v) {
                    setState(() => _barWeight = v.first);
                    if (_result != null) _calculate();
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Calculate button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _weightController.text.trim().isNotEmpty ? _calculate : null,
                child: const Text('Calculate'),
              ),
            ),

            // ── Results ──
            if (_result != null) ...[
              const SizedBox(height: 20),
              _buildResults(theme),
            ],

            const SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildResults(ThemeData theme) {
    final calc = _result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Divider(color: theme.colorScheme.outlineVariant),

        // Weight per side
        Row(
          children: [
            Text(
              'Per side:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${calc.weightPerSide.toStringAsFixed(1)} kg',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Bar:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${calc.barWeight.toStringAsFixed(0)} kg',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Plate breakdown header
        Text(
          'Plates (each side):',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        // Plate breakdown rows
        if (calc.platesPerSide.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No plates needed — weight is less than or equal to bar weight.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          ...calc.platesPerSide.map(
            (plate) => _PlateRow(
              plate: plate,
              color: _plateColors[plate.weight] ?? Colors.grey,
              theme: theme,
            ),
          ),

          const SizedBox(height: 16),

          // ── Visual barbell ──
          _VisualBarbell(
            plates: calc.platesPerSide,
            plateColors: _plateColors,
            theme: theme,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Plate row
// ---------------------------------------------------------------------------

class _PlateRow extends StatelessWidget {
  final PlateSet plate;
  final Color color;
  final ThemeData theme;

  const _PlateRow({
    required this.plate,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Colour swatch
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: color == Colors.white
                  ? Border.all(color: Colors.grey.shade400)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${plate.weight.toStringAsFixed(plate.weight % 1 == 0 ? 0 : 2)} kg',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '× ${plate.count}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visual Barbell
// ---------------------------------------------------------------------------

/// A simple horizontal barbell representation showing plates on each side.
class _VisualBarbell extends StatelessWidget {
  final List<PlateSet> plates;
  final Map<double, Color> plateColors;
  final ThemeData theme;

  const _VisualBarbell({
    required this.plates,
    required this.plateColors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Build plate widgets (heaviest → closest to centre, like a real bar)
    final plateWidgets = <Widget>[];
    for (final plate in plates.reversed) {
      for (var i = 0; i < plate.count; i++) {
        plateWidgets.add(
          Container(
            width: 20,
            height: 36,
            decoration: BoxDecoration(
              color: plateColors[plate.weight] ?? Colors.grey,
              borderRadius: BorderRadius.circular(3),
              border: (plateColors[plate.weight] ?? Colors.grey) == Colors.white
                  ? Border.all(color: Colors.grey.shade400)
                  : null,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barbell view:',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left plates (reversed for symmetry)
                ...plateWidgets.reversed,
                // Bar centre
                Container(
                  width: 40,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '⏤',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                // Right plates
                ...plateWidgets,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
