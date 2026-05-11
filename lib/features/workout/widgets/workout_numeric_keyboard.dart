import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// WorkoutNumericKeyboard
// ---------------------------------------------------------------------------

/// Enhanced numeric keypad matching iOS WorkoutNumericKeyboard.swift
///
/// Layout:
/// ┌────────────────────────────┬───────────┐
/// │  1  │  2  │  3            │ Dismiss   │
/// ├─────┼─────┼───────────────┤ Plate/RPE │
/// │  4  │  5  │  6           │  - │ +   │
/// ├─────┼─────┼───────────────┤   Next    │
/// │  7  │  8  │  9           │           │
/// ├─────┼─────┼───────────────┤           │
/// │  ,  │  0  │  ⌫           │           │
/// └────────────────────────────┴───────────┘
///
/// Features:
/// - 3-column number pad + decimal/comma
/// - Backspace key
/// - +/- increment buttons (1.25kg step for weight, 1 for reps)
/// - Next/Done for field navigation
/// - Contextual action: plate calculator (weight) or RPE (reps)
/// - Haptic feedback on key press
/// - Max value validation (999)
enum NumericKeyboardInputType { weight, reps }

class WorkoutNumericKeyboard extends StatefulWidget {
  final String initialValue;
  final NumericKeyboardInputType inputType;
  final void Function(String value) onChanged;
  final void Function(String value) onNext;
  final VoidCallback onDismiss;
  final void Function() onAction; // Plate/RPE toggle

  const WorkoutNumericKeyboard({
    super.key,
    this.initialValue = '',
    this.inputType = NumericKeyboardInputType.weight,
    required this.onChanged,
    required this.onNext,
    required this.onDismiss,
    required this.onAction,
  });

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

  @override
  void didUpdateWidget(WorkoutNumericKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _value = widget.initialValue;
    }
  }

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();

    setState(() {
      switch (key) {
        case 'C':
          _value = '';
          _isNegative = false;
          break;
        case '⌫':
          if (_value.isNotEmpty) {
            _value = _value.substring(0, _value.length - 1);
          }
          break;
        case '+/-':
          _isNegative = !_isNegative;
          break;
        case ',':
          // Support comma as decimal separator (iOS uses comma in some locales)
          if (!_value.contains('.') && !_value.contains(',')) {
            _value = _value.isEmpty ? '0,' : '$_value,';
          }
          break;
        default:
          // Digits
          if (_value == '0' && key != ',') {
            _value = key;
          } else if (_value.length < 8) {
            _value += key;
          }
      }
    });

    _emitValue();
  }

  void _onIncrement(bool positive) {
    HapticFeedback.mediumImpact();

    final current = double.tryParse(_value.replaceAll(',', '.')) ?? 0;
    double newValue;
    final increment = widget.inputType == NumericKeyboardInputType.weight ? 1.25 : 1.0;

    if (positive) {
      newValue = (current / increment).round() * increment + increment;
    } else {
      newValue = ((current / increment).round() * increment - increment).clamp(0.0, double.infinity);
    }

    newValue = newValue.clamp(0, 999);

    setState(() {
      if (newValue == newValue.roundToDouble()) {
        _value = newValue.toStringAsFixed(0);
      } else {
        _value = newValue.toStringAsFixed(2).replaceAll('.', ',');
      }
      _isNegative = false;
    });

    _emitValue();
  }

  void _onSubmit() {
    HapticFeedback.heavyImpact();
    widget.onNext(_buildFormattedValue());
  }

  String _buildFormattedValue() {
    if (_value.isEmpty) return '';
    final prefix = _isNegative ? '-' : '';
    return '$prefix$_value';
  }

  void _emitValue() {
    widget.onChanged(_buildFormattedValue());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = _buildFormattedValue();

    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Display ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayValue.isEmpty ? '0' : displayValue,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.inputType == NumericKeyboardInputType.weight)
                    Text(
                      'kg',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // ── Keyboard grid ──
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number pad (3x4 grid)
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildNumberRow(['1', '2', '3'], theme),
                        const SizedBox(height: 8),
                        _buildNumberRow(['4', '5', '6'], theme),
                        const SizedBox(height: 8),
                        _buildNumberRow(['7', '8', '9'], theme),
                        const SizedBox(height: 8),
                        _buildNumberRow([',', '0', '⌫'], theme),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Action column
                  SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        // Dismiss button
                        _KeyboardActionButton(
                          icon: Icons.keyboard_arrow_down,
                          onTap: widget.onDismiss,
                          theme: theme,
                        ),
                        const SizedBox(height: 8),

                        // Plate Calculator (weight) or RPE (reps)
                        _KeyboardActionButton(
                          label: widget.inputType == NumericKeyboardInputType.weight
                              ? null
                              : 'RPE',
                          icon: widget.inputType == NumericKeyboardInputType.weight
                              ? Icons.grid_3x3
                              : null,
                          onTap: widget.onAction,
                          theme: theme,
                          isPrimary: true,
                        ),
                        const SizedBox(height: 8),

                        // Increment buttons
                        Row(
                          children: [
                            Expanded(
                              child: _KeyboardActionButton(
                                icon: Icons.remove,
                                onTap: () => _onIncrement(false),
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _KeyboardActionButton(
                                icon: Icons.add,
                                onTap: () => _onIncrement(true),
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Next/Done button
                        _KeyboardActionButton(
                          label: 'Next',
                          onTap: _onSubmit,
                          theme: theme,
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<String> keys, ThemeData theme) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _KeyboardNumberButton(
              label: key,
              onTap: () => _onKeyPress(key),
              theme: theme,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Number Button
// ---------------------------------------------------------------------------

class _KeyboardNumberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  const _KeyboardNumberButton({
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: label == '⌫'
                ? Icon(
                    Icons.backspace_outlined,
                    color: theme.colorScheme.onSurface,
                    size: 22,
                  )
                : Text(
                    label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action Button
// ---------------------------------------------------------------------------

class _KeyboardActionButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isPrimary;

  const _KeyboardActionButton({
    this.label,
    this.icon,
    required this.onTap,
    required this.theme,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Material(
        color: isPrimary
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    color: isPrimary
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  )
                : Text(
                    label ?? '',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPrimary
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}