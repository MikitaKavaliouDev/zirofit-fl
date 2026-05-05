import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/exercise.dart';

/// A modal bottom sheet for logging an exercise set (weight / reps / side).
///
/// Shows a grab handle, exercise name + muscle group, optional weight field,
/// required reps field, an optional side selector for unilateral exercises,
/// and Cancel / Log Set action buttons.
class SetInputSheet extends StatefulWidget {
  const SetInputSheet({
    super.key,
    required this.exercise,
    required this.onLog,
  });

  /// The exercise being logged.
  final Exercise exercise;

  /// Called when the user confirms the set. [side] is only provided for
  /// unilateral exercises.
  final void Function({
    required int reps,
    double? weight,
    String? side,
  }) onLog;

  /// Shows this sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Exercise exercise,
    required void Function({
      required int reps,
      double? weight,
      String? side,
    }) onLog,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SetInputSheet(exercise: exercise, onLog: onLog),
    );
  }

  @override
  State<SetInputSheet> createState() => _SetInputSheetState();
}

class _SetInputSheetState extends State<SetInputSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedSide = 'BOTH';

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = widget.exercise;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Grab handle ──
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

              // ── Header: exercise name + muscle group ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (exercise.muscleGroup != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        exercise.muscleGroup!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Weight field (optional) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Optional — leave empty for bodyweight',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),

              const SizedBox(height: 16),

              // ── Reps field (required) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextFormField(
                  controller: _repsController,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    hintText: 'Enter number of reps',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Reps is required';
                    }
                    final reps = int.tryParse(v.trim());
                    if (reps == null || reps <= 0) {
                      return 'Must be a positive number';
                    }
                    return null;
                  },
                ),
              ),

              // ── Side toggle for unilateral exercises ──
              if (exercise.isUnilateral) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Side',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'LEFT',
                            label: Text('Left'),
                          ),
                          ButtonSegment(
                            value: 'RIGHT',
                            label: Text('Right'),
                          ),
                          ButtonSegment(
                            value: 'BOTH',
                            label: Text('Both'),
                          ),
                        ],
                        selected: {_selectedSide},
                        onSelectionChanged: (selected) {
                          setState(() => _selectedSide = selected.first);
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Actions: Cancel + Log Set ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _onLogSet,
                        child: const Text('Log Set'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onLogSet() {
    if (_formKey.currentState?.validate() ?? false) {
      final reps = int.parse(_repsController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());

      widget.onLog(
        reps: reps,
        weight: weight,
        side: widget.exercise.isUnilateral ? _selectedSide : null,
      );

      Navigator.of(context).pop();
    }
  }
}
