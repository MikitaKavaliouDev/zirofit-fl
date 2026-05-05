import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:zirofit_fl/data/models/fitness_goal.dart';
import 'package:zirofit_fl/features/progress/providers/goal_provider.dart';
import 'package:zirofit_fl/features/progress/widgets/goal_card.dart';

/// Screen for creating, editing, and managing fitness goals.
///
/// Supports three goal types: sessions (weekly workouts), volume (weekly
/// volume in kg), and PR (personal record target). Goals are persisted via
/// [GoalsNotifier] backed by SharedPreferences.
class GoalSettingScreen extends ConsumerStatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  ConsumerState<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends ConsumerState<GoalSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _exerciseNameController = TextEditingController();

  GoalType _selectedType = GoalType.sessions;
  int _sessionsTarget = 3;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String? _editingGoalId;

  @override
  void dispose() {
    _targetController.dispose();
    _exerciseNameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Edit mode
  // ---------------------------------------------------------------------------

  void _startEditing(FitnessGoal goal) {
    setState(() {
      _editingGoalId = goal.id;
      _selectedType = goal.type;
      _startDate = goal.startDate;
      _endDate = goal.endDate;

      switch (goal.type) {
        case GoalType.sessions:
          _sessionsTarget = goal.targetValue.round();
          _targetController.clear();
          _exerciseNameController.clear();
        case GoalType.volume:
          _targetController.text = goal.targetValue.toStringAsFixed(
            goal.targetValue == goal.targetValue.roundToDouble() ? 0 : 1,
          );
          _exerciseNameController.clear();
        case GoalType.pr:
          _exerciseNameController.text = goal.exerciseName ?? '';
          _targetController.text = goal.targetValue.toStringAsFixed(
            goal.targetValue == goal.targetValue.roundToDouble() ? 0 : 1,
          );
      }
    });
  }

  void _resetForm() {
    setState(() {
      _editingGoalId = null;
      _selectedType = GoalType.sessions;
      _sessionsTarget = 3;
      _startDate = DateTime.now();
      _endDate = null;
      _targetController.clear();
      _exerciseNameController.clear();
      _formKey.currentState?.reset();
    });
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final double targetValue;
    switch (_selectedType) {
      case GoalType.sessions:
        targetValue = _sessionsTarget.toDouble();
        break;
      case GoalType.volume:
      case GoalType.pr:
        targetValue = double.parse(_targetController.text.trim());
    }

    final goal = FitnessGoal(
      id: _editingGoalId ?? const Uuid().v4(),
      type: _selectedType,
      targetValue: targetValue,
      startDate: DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
      ),
      endDate: _endDate != null
          ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
          : null,
      exerciseName:
          _selectedType == GoalType.pr
              ? _exerciseNameController.text.trim()
              : null,
    );

    await ref.read(goalsProvider.notifier).setGoal(goal);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editingGoalId != null ? 'Goal updated' : 'Goal created',
        ),
      ),
    );

    _resetForm();
  }

  Future<void> _deleteGoal(String goalId) async {
    await ref.read(goalsProvider.notifier).removeGoal(goalId);
  }

  // ---------------------------------------------------------------------------
  // Date picker
  // ---------------------------------------------------------------------------

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: isStart ? now.subtract(const Duration(days: 365)) : _startDate,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Type switch handler
  // ---------------------------------------------------------------------------

  void _onTypeChanged(GoalType? type) {
    if (type == null || type == _selectedType) return;
    setState(() {
      _selectedType = type;
      _targetController.clear();
      _exerciseNameController.clear();
      _sessionsTarget = 3;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalsState = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Goals'),
        leading: BackButton(
          onPressed: () {
            if (_editingGoalId != null) {
              _resetForm();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Goal type selector --
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SegmentedButton<GoalType>(
                  segments: const [
                    ButtonSegment(
                      value: GoalType.sessions,
                      label: Text('Workouts'),
                      icon: Icon(Icons.calendar_month_rounded),
                    ),
                    ButtonSegment(
                      value: GoalType.volume,
                      label: Text('Volume'),
                      icon: Icon(Icons.monitor_weight_rounded),
                    ),
                    ButtonSegment(
                      value: GoalType.pr,
                      label: Text('PR'),
                      icon: Icon(Icons.emoji_events_rounded),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (sel) => _onTypeChanged(sel.first),
                  showSelectedIcon: false,
                ),
              ),

              // -- Form --
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingGoalId != null
                                ? 'Edit Goal'
                                : 'New Goal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Type-specific fields
                          ..._buildTypeSpecificFields(theme),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Start date
                          _DateField(
                            label: 'Start Date',
                            date: _startDate,
                            onTap: () => _pickDate(isStart: true),
                          ),
                          const SizedBox(height: 12),

                          // End date
                          _DateField(
                            label: 'End Date (optional)',
                            date: _endDate,
                            onTap: () => _pickDate(isStart: false),
                            onClear: _endDate != null
                                ? () => setState(() => _endDate = null)
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // Action buttons
                          Row(
                            children: [
                              if (_editingGoalId != null) ...[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _resetForm,
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: FilledButton(
                                  onPressed: _saveGoal,
                                  child: Text(
                                    _editingGoalId != null ? 'Update' : 'Save Goal',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // -- Existing goals --
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Your Goals',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (goalsState.goals.isEmpty)
                _EmptyState(theme: theme)
              else
                ...goalsState.goals.map(
                  (goal) => GoalCard(
                    goal: goal,
                    onEdit: () => _startEditing(goal),
                    onDelete: () => _deleteGoal(goal.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Type-specific form fields
  // ---------------------------------------------------------------------------

  List<Widget> _buildTypeSpecificFields(ThemeData theme) {
    switch (_selectedType) {
      case GoalType.sessions:
        return [_buildSessionsStepper(theme)];
      case GoalType.volume:
        return [_buildVolumeField(theme)];
      case GoalType.pr:
        return [
          _buildExerciseNameField(theme),
          const SizedBox(height: 16),
          _buildTargetField(
            theme,
            label: 'Target Value',
            hint: 'e.g. 100',
            suffix: '',
          ),
        ];
    }
  }

  Widget _buildSessionsStepper(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sessions per week',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepperButton(
              icon: Icons.remove_rounded,
              onTap: _sessionsTarget > 1
                  ? () => setState(() => _sessionsTarget--)
                  : null,
            ),
            const SizedBox(width: 20),
            Text(
              '$_sessionsTarget',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 20),
            _StepperButton(
              icon: Icons.add_rounded,
              onTap: _sessionsTarget < 7
                  ? () => setState(() => _sessionsTarget++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVolumeField(ThemeData theme) {
    return _buildTargetField(
      theme,
      label: 'Target Weekly Volume',
      hint: 'e.g. 10000',
      suffix: 'kg',
    );
  }

  Widget _buildExerciseNameField(ThemeData theme) {
    return TextFormField(
      controller: _exerciseNameController,
      decoration: const InputDecoration(
        labelText: 'Exercise Name',
        hintText: 'e.g. Bench Press',
        prefixIcon: Icon(Icons.fitness_center_rounded),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (_selectedType == GoalType.pr &&
            (value == null || value.trim().isEmpty)) {
          return 'Please enter an exercise name';
        }
        return null;
      },
    );
  }

  Widget _buildTargetField(
    ThemeData theme, {
    required String label,
    required String hint,
    required String suffix,
  }) {
    return TextFormField(
      controller: _targetController,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix.isNotEmpty ? suffix : null,
        prefixIcon: const Icon(Icons.speed_rounded),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a target value';
        }
        final parsed = double.tryParse(value.trim());
        if (parsed == null || parsed <= 0) {
          return 'Target must be greater than 0';
        }
        return null;
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: onTap != null
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = date != null
        ? DateFormat('MMM dd, yyyy').format(date!)
        : 'Not set';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded),
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Text(
          formatted,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: date != null
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No goals set',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first fitness goal!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
