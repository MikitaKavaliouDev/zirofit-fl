import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';
import 'package:zirofit_fl/features/programs/widgets/template_picker_sheet.dart';

/// Local model for a routine's workout slot.
class RoutineSlot {
  final String id;
  WorkoutTemplate template;
  String label;

  RoutineSlot({
    String? id,
    required this.template,
    String? label,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label = label ?? 'Day 1';

  RoutineSlot copyWith({
    WorkoutTemplate? template,
    String? label,
  }) {
    return RoutineSlot(
      id: id,
      template: template ?? this.template,
      label: label ?? this.label,
    );
  }
}

/// Screen for creating or editing a routine.
///
/// Includes name/description fields and a list of workout slots that can be
/// reordered, renamed, or removed. Tapping "Add Workout" opens the
/// [TemplatePickerSheet] to select a template for a new slot.
class RoutineBuilderScreen extends ConsumerStatefulWidget {
  /// If non-null, the screen operates in "edit" mode.
  final WorkoutProgram? routine;

  const RoutineBuilderScreen({super.key, this.routine});

  @override
  ConsumerState<RoutineBuilderScreen> createState() =>
      _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends ConsumerState<RoutineBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _labelControllers = <String, TextEditingController>{};
  final _scrollController = ScrollController();

  final List<RoutineSlot> _slots = [];
  bool _isSaving = false;

  bool get _isEditing => widget.routine != null;

  @override
  void initState() {
    super.initState();

    final routine = widget.routine;
    if (routine != null) {
      _nameController.text = routine.name;
      _descriptionController.text = routine.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final c in _labelControllers.values) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _addSlot(WorkoutTemplate template) {
    setState(() {
      final day = _slots.length + 1;
      final slot = RoutineSlot(
        template: template,
        label: 'Day $day',
      );
      _labelControllers[slot.id] = TextEditingController(text: slot.label);
      _slots.add(slot);
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeSlot(String id) {
    setState(() {
      _slots.removeWhere((s) => s.id == id);
      _labelControllers.remove(id)?.dispose();
    });
    _renumberDays();
  }

  void _renumberDays() {
    for (var i = 0; i < _slots.length; i++) {
      final newLabel = 'Day ${i + 1}';
      _slots[i] = _slots[i].copyWith(label: newLabel);
      _labelControllers[_slots[i].id]?.text = newLabel;
    }
  }

  Future<void> _openTemplatePicker() async {
    final template = await TemplatePickerSheet.show(context);
    if (template != null) {
      _addSlot(template);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      final String programId;

      if (_isEditing) {
        // Edit mode: program already exists, add templates for new slots
        programId = widget.routine!.id;
      } else {
        // Create mode: persist program first
        final program = await ref.read(programsProvider.notifier).createProgram(
              name,
              description.isNotEmpty ? description : null,
            );

        if (program == null) {
          final state = ref.read(programsProvider);
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'Failed to create routine'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }
        programId = program.id;
      }

      // Create a template for each slot under the program
      for (final slot in _slots) {
        final label = _labelControllers[slot.id]?.text ?? slot.label;
        await ref.read(programsProvider.notifier).createTemplate(
              name: slot.template.name,
              description: label,
              programId: programId,
            );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Routine "$name" saved')),
      );
      setState(() => _isSaving = false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save routine: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Routine' : 'New Routine'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                hintText: 'e.g. Weekly Push Workout',
              ),
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a routine name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description of the routine',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Workout Slots section
            Row(
              children: [
                Text(
                  'Workout Slots',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (_slots.isNotEmpty)
                  Text(
                    '${_slots.length} ${_slots.length == 1 ? 'session' : 'sessions'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_slots.isEmpty)
              _EmptySlotsPlaceholder(onAdd: _openTemplatePicker, theme: theme)
            else
              ..._buildSlotCards(theme),

            const SizedBox(height: 16),

            // Add Workout button
            OutlinedButton.icon(
              onPressed: _openTemplatePicker,
              icon: const Icon(Icons.add),
              label: const Text('Add Workout'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSlotCards(ThemeData theme) {
    return List.generate(_slots.length, (index) {
      final slot = _slots[index];
      final labelController = _labelControllers.putIfAbsent(
        slot.id,
        () => TextEditingController(text: slot.label),
      );

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day label row with reorder handle and delete
              Row(
                children: [
                  // Reorder handle
                  Icon(
                    Icons.drag_handle,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  // Day label text field
                  Expanded(
                    child: TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                      onChanged: (value) {
                        final idx = _slots.indexWhere((s) => s.id == slot.id);
                        if (idx != -1) {
                          _slots[idx] = _slots[idx].copyWith(label: value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  IconButton(
                    onPressed: () => _removeSlot(slot.id),
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: 'Remove',
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Template info
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      slot.template.name,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Empty slots placeholder
// ---------------------------------------------------------------------------

class _EmptySlotsPlaceholder extends StatelessWidget {
  final VoidCallback onAdd;
  final ThemeData theme;

  const _EmptySlotsPlaceholder({
    required this.onAdd,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first workout template',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
