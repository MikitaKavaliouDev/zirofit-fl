import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// WorkoutNumericKeyboard
// ---------------------------------------------------------------------------

/// A custom numeric keypad for quickly entering weight / rep values during a
/// workout.  Replaces the system keyboard with large, easy-to-tap buttons.
///
/// Layout:
/// ┌─────┬─────┬─────┬──────┐
/// │  1  │  2  │  3  │  C  │
/// ├─────┼─────┼─────┼──────┤
/// │  4  │  5  │  6  │ +/- │
/// ├─────┼─────┼─────┤ 2.5  │
/// │  7  │  8  │  9  │      │
/// ├─────┼─────┼─────┼──────┤
/// │  .  │  0  │ +/- │ Next │
/// └─────┴─────┴─────┴──────┘
///
/// Provides haptic feedback on each key press.
class WorkoutNumericKeyboard extends StatefulWidget {
  const WorkoutNumericKeyboard({
    super.key,
    this.initialValue = '',
    this.onChanged,
    this.onSubmitted,
    this.submitLabel = 'Next',
    this.unit = 'kg',
  });

  /// Initial text value shown in the display.
  final String initialValue;

  /// Called whenever the display value changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user taps the submit / Enter button.
  final ValueChanged<String>? onSubmitted;

  /// Label for the submit button (default "Next").
  final String submitLabel;

  /// Optional unit label shown next to the display value (default "kg").
  final String unit;

  @override
  State<WorkoutNumericKeyboard> createState() => _WorkoutNumericKeyboardState();
}

class _WorkoutNumericKeyboardState extends State<WorkoutNumericKeyboard> {
  late String _value;
  bool _isNegative = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();

    setState(() {
      switch (key) {
        case 'C':
          _value = '';
          _isNegative = false;
          break;
        case '+/-':
          _isNegative = !_isNegative;
          break;
        case '.':
          if (!_value.contains('.')) {
            _value = _value.isEmpty ? '0.' : '$_value.';
          }
          break;
        default:
          // Digits
          if (_value == '0' && key != '.') {
            _value = key; // replace leading zero
          } else if (_value.length < 8) {
            _value += key;
          }
      }
    });

    widget.onChanged?.call(_buildFormattedValue());
  }

  void _onSubmit() {
    HapticFeedback.heavyImpact();
    widget.onSubmitted?.call(_buildFormattedValue());
  }

  void _onToggle2Point5() {
    HapticFeedback.lightImpact();
    final current = double.tryParse(_buildFormattedValue()) ?? 0;
    final newValue = _isNegative
        ? (current - 2.5).toStringAsFixed(1)
        : (current + 2.5).toStringAsFixed(1);
    setState(() {
      _value = newValue;
      _isNegative = false;
    });
    widget.onChanged?.call(_buildFormattedValue());
  }

  String _buildFormattedValue() {
    // If value is empty, show nothing
    if (_value.isEmpty) return '';
    final prefix = _isNegative ? '-' : '';
    return '$prefix$_value';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = _buildFormattedValue();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Value display ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayValue.isEmpty ? '0' : displayValue,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (displayValue.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  widget.unit,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Keyboard grid ──
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: 1 2 3 C
              _buildRow(theme, ['1', '2', '3', 'C']),
              const SizedBox(height: 8),
              // Row 2: 4 5 6 +/-2.5
              _buildRow(theme, ['4', '5', '6', '±2.5']),
              const SizedBox(height: 8),
              // Row 3: 7 8 9 +/- toggle
              _buildRow(theme, ['7', '8', '9', '+/-']),
              const SizedBox(height: 8),
              // Row 4: . 0 (spacer) Next
              _buildBottomRow(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(ThemeData theme, List<String> labels) {
    return Row(
      children: labels.map((label) {
        final isSpecial = label == 'C' || label == '+/-' || label == '±2.5';
        final isClear = label == 'C';

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _KeyboardButton(
              label: label,
              isSpecial: isSpecial,
              isClear: isClear,
              theme: theme,
              onTap: label == '±2.5' ? _onToggle2Point5 : () => _onKeyPress(label),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow(ThemeData theme) {
    return Row(
      children: [
        // .
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _KeyboardButton(
              label: '.',
              theme: theme,
              onTap: () => _onKeyPress('.'),
            ),
          ),
        ),
        // 0
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _KeyboardButton(
              label: '0',
              theme: theme,
              onTap: () => _onKeyPress('0'),
            ),
          ),
        ),
        // +/- toggle
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _KeyboardButton(
              label: '+/-',
              isSpecial: true,
              theme: theme,
              onTap: () => _onKeyPress('+/-'),
            ),
          ),
        ),
        // Next / Submit
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _KeyboardButton(
              label: widget.submitLabel,
              isSubmit: true,
              theme: theme,
              onTap: _onSubmit,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Keyboard Button
// ---------------------------------------------------------------------------

class _KeyboardButton extends StatelessWidget {
  final String label;
  final bool isSpecial;
  final bool isClear;
  final bool isSubmit;
  final ThemeData theme;
  final VoidCallback onTap;

  const _KeyboardButton({
    required this.label,
    required this.theme,
    required this.onTap,
    this.isSpecial = false,
    this.isClear = false,
    this.isSubmit = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;

    if (isSubmit) {
      bgColor = theme.colorScheme.primary;
      fgColor = theme.colorScheme.onPrimary;
    } else if (isClear) {
      bgColor = theme.colorScheme.errorContainer;
      fgColor = theme.colorScheme.onErrorContainer;
    } else if (isSpecial) {
      bgColor = theme.colorScheme.surfaceContainerHighest;
      fgColor = theme.colorScheme.onSurfaceVariant;
    } else {
      bgColor = theme.colorScheme.surfaceContainerLow;
      fgColor = theme.colorScheme.onSurface;
    }

    return SizedBox(
      height: 56,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isSubmit ? FontWeight.w600 : FontWeight.w500,
                color: fgColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
