import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/body_measurement.dart';

/// Data returned by [AddMeasurementSheet] when the user saves.
class MeasurementSheetResult {
  final double value;
  final DateTime date;
  final String? notes;

  const MeasurementSheetResult({
    required this.value,
    required this.date,
    this.notes,
  });
}

/// Bottom-sheet form for adding a new measurement.
///
/// Usage:
/// ```dart
/// final result = await showModalBottomSheet<MeasurementSheetResult>(
///   context: context,
///   builder: (_) => AddMeasurementSheet(type: type),
/// );
/// ```
class AddMeasurementSheet extends StatefulWidget {
  const AddMeasurementSheet({
    super.key,
    required this.type,
    this.currentWeightKg,
  });

  /// The measurement type being recorded (e.g. weight, chest, neck).
  final MeasurementType type;

  /// The most recent weight value (kg), used for weight-change warnings.
  /// Only relevant when [type] is `weight`.
  final double? currentWeightKg;

  @override
  State<AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isCore = widget.type.category == 'core';
    final unit = isCore ? _coreUnit(widget.type.id) : widget.type.unit;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.type.name,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Value input
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Value ($unit)',
                prefixIcon: const Icon(Icons.edit),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a value';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid positive number';
                }
                return null;
              },
            ),
            // Unit display below the value field
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date picker
            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text: DateFormat('MMM dd, yyyy').format(_selectedDate),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  helpText: 'Select measurement date',
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              validator: (_) => null,
            ),
            const SizedBox(height: 16),

            // Notes (optional)
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: _isSubmitting ? null : _onSave,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Measurement'),
            ),
            const SizedBox(height: 8),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final value = double.parse(_valueController.text.trim());

    // Weight change warning
    if (widget.type.id == 'weight' && widget.currentWeightKg != null) {
      final change = (value - widget.currentWeightKg!).abs();
      if (change > 5) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Large Weight Change'),
            content: Text(
              'You are about to record a weight change of '
              '${change.toStringAsFixed(1)} kg. This is a significant '
              'change. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("Yes, I'm sure"),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      } else if (change > 2) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Weight Change Notice'),
            content: Text(
              'You are about to record a weight change of '
              '${change.toStringAsFixed(1)} kg. Save anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save Anyway'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
    }

    setState(() => _isSubmitting = true);

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    if (!mounted) return;

    Navigator.of(context).pop(
      MeasurementSheetResult(
        value: value,
        date: _selectedDate,
        notes: notes,
      ),
    );
  }

  /// Returns the unit string for core measurement types.
  static String _coreUnit(String typeId) {
    switch (typeId) {
      case 'weight':
        return 'kg';
      case 'height':
        return 'cm';
      case 'body_fat':
        return '%';
      case 'caloric_intake':
        return 'kcal';
      default:
        return '';
    }
  }
}
