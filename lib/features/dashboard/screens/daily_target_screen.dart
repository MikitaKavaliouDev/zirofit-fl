import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:zirofit_fl/features/dashboard/providers/daily_target_provider.dart';

class DailyTargetScreen extends ConsumerStatefulWidget {
  const DailyTargetScreen({super.key});

  @override
  ConsumerState<DailyTargetScreen> createState() => _DailyTargetScreenState();
}

class _DailyTargetScreenState extends ConsumerState<DailyTargetScreen> {
  final _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyTargetProvider.notifier).loadTargets(_date);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(dailyTargetProvider);

    return Scaffold(
      appBar: _buildAppBar(theme, state),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(theme, state),
      // FAB is always shown to allow adding targets
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTargetSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(ThemeData theme, DailyTargetState state) {
    final dateFormat = DateFormat('EEEE, MMMM d');
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(_date),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (state.streak > 0)
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${state.streak}-day streak',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(dailyTargetProvider.notifier).loadTargets(_date);
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Content (targets + challenge)
  // ---------------------------------------------------------------------------

  Widget _buildContent(ThemeData theme, DailyTargetState state) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dailyTargetProvider.notifier).loadTargets(_date);
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Challenge card
                _buildChallengeSection(theme, state),
                const SizedBox(height: 16),

                // Section header
                Text(
                  'Today\'s Targets',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),

          // Target list or empty message
          if (state.targets.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverToBoxAdapter(
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showAddTargetSheet(context),
                    child: const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.add_circle_outline, size: 40),
                            SizedBox(height: 8),
                            Text('Tap to add your first target'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            // Reorderable target list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTargetList(theme, state),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Challenge card
  // ---------------------------------------------------------------------------

  Widget _buildChallengeSection(ThemeData theme, DailyTargetState state) {
    final challenge = state.challenge;

    if (challenge == null) {
      return Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Challenge',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Complete all targets for 7 days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () {
                  ref.read(dailyTargetProvider.notifier).startChallenge();
                },
                child: const Text('Start'),
              ),
            ],
          ),
        ),
      );
    }

    // Active challenge
    final remaining = challenge.remainingTime;
    final daysLeft = remaining.inDays;
    final hoursLeft = remaining.inHours.remainder(24);
    final progress = challenge.progress;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.amber.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Day ${challenge.completedDays} of ${challenge.totalDays}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysLeft > 0
                        ? '${daysLeft}d ${hoursLeft}h left'
                        : '${hoursLeft}h left',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.amber.withValues(alpha: 0.15),
                color: Colors.amber,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% complete',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Target list
  // ---------------------------------------------------------------------------

  Widget _buildTargetList(ThemeData theme, DailyTargetState state) {
    if (state.targets.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAddTargetSheet(context),
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.add_circle_outline, size: 40),
                  SizedBox(height: 8),
                  Text('Tap to add your first target'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.targets.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(dailyTargetProvider.notifier).reorderTargets(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevation = lerpDouble(0, 6, animation.value)!;
            return Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(16),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final target = state.targets[index];
        return _TargetCard(
          key: ValueKey(target.id),
          index: index,
          target: target,
          onToggle: () {
            ref.read(dailyTargetProvider.notifier).toggleCompleted(target.id);
          },
          onDelete: () {
            ref.read(dailyTargetProvider.notifier).removeTarget(target.id);
          },
          onIncrement: () {
            ref.read(dailyTargetProvider.notifier).adjustProgress(target.id, 1);
          },
          onDecrement: () {
            ref.read(dailyTargetProvider.notifier).adjustProgress(target.id, -1);
          },
          onSliderChanged: (value) {
            ref.read(dailyTargetProvider.notifier).updateProgress(target.id, value);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Add Target Bottom Sheet
  // ---------------------------------------------------------------------------

  void _showAddTargetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddTargetSheet(
        onSave: (target) {
          ref.read(dailyTargetProvider.notifier).addTarget(target);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Target Card
// ---------------------------------------------------------------------------

class _TargetCard extends StatelessWidget {
  final int index;
  final DailyTarget target;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<double> onSliderChanged;

  const _TargetCard({
    super.key,
    required this.index,
    required this.target,
    required this.onToggle,
    required this.onDelete,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target.targetValue > 0
        ? (target.currentValue / target.targetValue).clamp(0.0, 1.0)
        : 0.0;

    return Dismissible(
      key: ValueKey('${target.id}_dismiss'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: checkbox, title, drag handle
              Row(
                children: [
                  GestureDetector(
                    key: ValueKey('checkbox_${target.id}'),
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: target.isCompleted
                            ? Colors.green
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: target.isCompleted
                            ? null
                            : Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: target.isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      target.title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: target.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: target.isCompleted
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ),
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: target.isCompleted ? Colors.green : theme.colorScheme.primary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),

              // Current / target display
              Row(
                children: [
                  Text(
                    '${target.currentValue.toStringAsFixed(0)} / ${target.targetValue.toStringAsFixed(0)} ${target.unit}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Slider with +/- buttons
              Row(
                children: [
                  IconButton(
                    onPressed: target.currentValue <= 0 ? null : onDecrement,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 24,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Decrease',
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: target.isCompleted
                            ? Colors.green
                            : theme.colorScheme.primary,
                        inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                        thumbColor: target.isCompleted
                            ? Colors.green
                            : theme.colorScheme.primary,
                        overlayColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      child: Slider(
                        value: target.currentValue.clamp(0, target.targetValue),
                        min: 0,
                        max: target.targetValue,
                        divisions: target.targetValue > 20
                            ? target.targetValue.toInt()
                            : null,
                        onChanged: onSliderChanged,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: target.currentValue >= target.targetValue
                        ? null
                        : onIncrement,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 24,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Increase',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Target Bottom Sheet
// ---------------------------------------------------------------------------

class _AddTargetSheet extends StatefulWidget {
  final ValueChanged<DailyTarget> onSave;

  const _AddTargetSheet({required this.onSave});

  @override
  State<_AddTargetSheet> createState() => _AddTargetSheetState();
}

class _AddTargetSheetState extends State<_AddTargetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _unitController = TextEditingController();

  String _selectedType = 'steps';
  bool _customUnit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedType = value;
      final info = TargetTypeInfo.fromKey(value);
      if (info != null && info.defaultUnit.isNotEmpty) {
        _unitController.text = info.defaultUnit;
        _customUnit = false;
      } else {
        _unitController.text = '';
        _customUnit = true;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final target = DailyTarget(
      id: const Uuid().v4(),
      title: _nameController.text.trim(),
      type: _selectedType,
      targetValue: double.parse(_targetValueController.text.trim()),
      unit: _unitController.text.trim(),
      date: DateTime.now(),
    );

    widget.onSave(target);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Add Daily Target',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Target Name',
                  hintText: 'e.g. Morning Walk',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),

              // Type dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                ),
                items: TargetTypeInfo.all.map((info) {
                  return DropdownMenuItem(
                    value: info.key,
                    child: Text(info.label),
                  );
                }).toList(),
                onChanged: _onTypeChanged,
              ),
              const SizedBox(height: 16),

              // Target value
              TextFormField(
                controller: _targetValueController,
                decoration: const InputDecoration(
                  labelText: 'Target Value',
                  hintText: 'e.g. 10000',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a value';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Unit
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(
                  labelText: 'Unit',
                  hintText: _customUnit ? 'e.g. reps' : 'Auto-filled',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a unit' : null,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Add Target'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
