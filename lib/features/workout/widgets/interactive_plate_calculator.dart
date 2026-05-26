import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// InteractivePlateCalculator
// ---------------------------------------------------------------------------

/// Interactive plate calculator matching iOS PlateCalculatorOverlay.swift
///
/// Features:
/// - Visual barbell representation with colored plates
/// - Tap-to-add plates (25, 20, 15, 10, 5, 2.5, 1.25 kg)
/// - Clear/reset button
/// - Color-coded plates (red=25, blue=20, yellow=15, green=10, white=5, etc.)
/// - Current weight display
/// - Barbell visualization
class InteractivePlateCalculator extends StatefulWidget {
  final double initialWeight;
  final double barWeight;
  final void Function(double weight) onWeightChanged;
  final VoidCallback onDismiss;

  const InteractivePlateCalculator({
    super.key,
    this.initialWeight = 20.0,
    this.barWeight = 20.0,
    required this.onWeightChanged,
    required this.onDismiss,
  });

  @override
  State<InteractivePlateCalculator> createState() => _InteractivePlateCalculatorState();
}

class _InteractivePlateCalculatorState extends State<InteractivePlateCalculator> {
  late double _totalWeight;

  /// Standard KG plate weights in descending order
  static const List<double> _availablePlates = [25, 20, 15, 10, 5, 2.5, 1.25];

  /// Colour mapping matching standard competition plate colors
  static final Map<double, Color> _plateColors = {
    25: const Color(0xFFE53935), // Red
    20: const Color(0xFF1565C0), // Blue
    15: const Color(0xFFFDD835), // Yellow
    10: const Color(0xFF1B5E20), // Green
    5: const Color(0xFFFFFFFF), // White
    2.5: const Color(0xFF7B1FA2), // Purple
    1.25: const Color(0xFF9E9E9E), // Grey
  };

  @override
  void initState() {
    super.initState();
    _totalWeight = widget.initialWeight;
  }

  /// Calculate plates needed per side
  List<double> _calculatePlatesPerSide() {
    final result = <double>[];
    var remaining = (_totalWeight - widget.barWeight) / 2;

    if (remaining <= 0) return result;

    for (final plate in _availablePlates) {
      while (remaining >= plate) {
        result.add(plate);
        remaining -= plate;
      }
    }
    return result;
  }

  void _addPlate(double weight) {
    HapticFeedback.lightImpact();
    setState(() {
      _totalWeight += weight * 2;
    });
    widget.onWeightChanged(_totalWeight);
  }

  void _clear() {
    HapticFeedback.lightImpact();
    setState(() {
      _totalWeight = widget.barWeight;
    });
    widget.onWeightChanged(_totalWeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platesPerSide = _calculatePlatesPerSide();

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Grab handle ──
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Weight display ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  '${_totalWeight.toStringAsFixed(1)} kg',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Bar: ${widget.barWeight.toStringAsFixed(0)} kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Barbell visualization ──
          _buildBarbellVisual(theme, platesPerSide),

          const SizedBox(height: 16),

          // ── Plate selection grid ──
          Expanded(
            child: _buildPlateGrid(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBarbellVisual(ThemeData theme, List<double> platesPerSide) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left plates (mirrored)
            ...platesPerSide.reversed.map((p) => _buildPlateVisual(p, false)),
            // Left sleeve
            Container(
              width: 80,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Bar center
            Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Right sleeve
            Container(
              width: 80,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Right plates
            ...platesPerSide.map((p) => _buildPlateVisual(p, true)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlateVisual(double weight, bool isRight) {
    final color = _plateColors[weight] ?? Colors.grey;
    final height = _getPlateHeight(weight);
    final width = _getPlateWidth(weight);

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: color == Colors.white
            ? Border.all(color: Colors.grey.shade400)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          weight.toStringAsFixed(weight % 1 == 0 ? 0 : 2),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  double _getPlateHeight(double weight) {
    switch (weight) {
      case 25: return 80;
      case 20: return 80;
      case 15: return 70;
      case 10: return 60;
      case 5: return 50;
      case 2.5: return 40;
      case 1.25: return 30;
      default: return 40;
    }
  }

  double _getPlateWidth(double weight) {
    switch (weight) {
      case 25: return 12;
      case 20: return 12;
      case 15: return 10;
      case 10: return 10;
      case 5: return 8;
      case 2.5: return 8;
      case 1.25: return 8;
      default: return 8;
    }
  }

  Widget _buildPlateGrid(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'Tap plates to add',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ..._availablePlates.map((plate) => _buildPlateButton(plate, theme)),
                // Clear button
                _buildClearButton(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlateButton(double weight, ThemeData theme) {
    final color = _plateColors[weight] ?? Colors.grey;
    final displayWeight = weight == weight.roundToDouble()
        ? weight.toStringAsFixed(0)
        : weight.toStringAsFixed(2);

    return GestureDetector(
      onTap: () => _addPlate(weight),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayWeight,
            style: TextStyle(
              color: color == Colors.white || color == const Color(0xFFFDD835)
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(ThemeData theme) {
    return GestureDetector(
      onTap: _clear,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}