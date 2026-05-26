import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/template_exercise.dart';
import 'package:zirofit_fl/data/models/enums/step_type.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';

// ---------------------------------------------------------------------------
// ClientCreateTemplateScreen
// ---------------------------------------------------------------------------

class ClientCreateTemplateScreen extends ConsumerStatefulWidget {
  /// Optional program ID to pre-select. When provided, the program picker
  /// dropdown is skipped.
  final String? programId;

  const ClientCreateTemplateScreen({super.key, this.programId});

  @override
  ConsumerState<ClientCreateTemplateScreen> createState() =>
      _ClientCreateTemplateScreenState();
}

class _ClientCreateTemplateScreenState
    extends ConsumerState<ClientCreateTemplateScreen> {
  // ---------------------------------------------------------------------------
  // Phase 0 – Create
  // ---------------------------------------------------------------------------
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedProgramId = '';

  // ---------------------------------------------------------------------------
  // Phase tracking
  // ---------------------------------------------------------------------------
  int _phase = 0; // 0 = creating, 1 = editing steps
  String? _templateId;

  // ---------------------------------------------------------------------------
  // Step tracking
  // ---------------------------------------------------------------------------
  final List<String> _stepOrder = [];
  final Map<String, String> _stepExerciseNames = {};

  bool _isLoading = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _selectedProgramId = widget.programId ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(clientProgramsProvider);
      if (state.library == null && !state.isLoading) {
        ref.read(clientProgramsProvider.notifier).fetchLibrary();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty &&
      _selectedProgramId.isNotEmpty &&
      !_isLoading;

  // ---------------------------------------------------------------------------
  // Phase 0 – Create template
  // ---------------------------------------------------------------------------

  Future<void> _createTemplate() async {
    if (!_canCreate) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final result = await ref
        .read(clientProgramsProvider.notifier)
        .createTemplate(
          name: name,
          description: description.isNotEmpty ? description : null,
          programId: _selectedProgramId,
        );

    if (!mounted) return;

    if (result != null) {
      final data = result['data'] as Map<String, dynamic>? ?? result;
      final id = data['id'] as String?;

      setState(() {
        _isLoading = false;
        _phase = 1;
        _templateId = id ?? result['template_id'] as String?;
      });
    } else {
      setState(() => _isLoading = false);
      final pState = ref.read(clientProgramsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pState.error ?? 'Failed to create template'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 1 – Add exercise step
  // ---------------------------------------------------------------------------

  Future<void> _openAddExerciseDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddExerciseDialog(),
    );

    if (result == null || !mounted || _templateId == null) return;

    setState(() => _isLoading = true);

    final exerciseName = result.remove('_exerciseName') as String?;
    final step = await ref
        .read(clientProgramsProvider.notifier)
        .addExerciseStep(_templateId!, result);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (step != null) {
      final stepData = step['data'] as Map<String, dynamic>? ?? step;
      final stepId = stepData['id'] as String?;

      setState(() {
        if (stepId != null) {
          _stepOrder.add(stepId);
          if (exerciseName != null) {
            _stepExerciseNames[stepId] = exerciseName;
          }
        }
      });
    } else {
      final pState = ref.read(clientProgramsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pState.error ?? 'Failed to add exercise'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 1 – Add rest step
  // ---------------------------------------------------------------------------

  Future<void> _openAddRestDialog() async {
    final duration = await showDialog<int>(
      context: context,
      builder: (_) => const _AddRestDialog(),
    );

    if (duration == null || !mounted || _templateId == null) return;

    setState(() => _isLoading = true);

    final step = await ref
        .read(clientProgramsProvider.notifier)
        .addRestStep(_templateId!, duration);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (step != null) {
      final stepData = step['data'] as Map<String, dynamic>? ?? step;
      final stepId = stepData['id'] as String?;

      setState(() {
        if (stepId != null) _stepOrder.add(stepId);
      });
    } else {
      final pState = ref.read(clientProgramsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pState.error ?? 'Failed to add rest step'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 1 – Delete step
  // ---------------------------------------------------------------------------

  Future<void> _deleteStep(String stepId) async {
    if (_templateId == null) return;

    setState(() => _isLoading = true);

    final success =
        await ref.read(clientProgramsProvider.notifier).deleteExerciseStep(
              _templateId!,
              stepId,
            );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (success) {
        _stepOrder.remove(stepId);
        _stepExerciseNames.remove(stepId);
      }
    });

    if (!success && mounted) {
      final pState = ref.read(clientProgramsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pState.error ?? 'Failed to delete step'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Reorder
  // ---------------------------------------------------------------------------

  List<TemplateExercise> _orderedSteps(ClientProgramsState state) {
    if (_templateId == null) return [];
    final library = state.library;
    if (library == null) return [];

    final allExercises = <TemplateExercise>[];

    // Search in personal programs
    for (final program in library.personalPrograms) {
      for (final template in program.templates) {
        if (template.id == _templateId) {
          allExercises.addAll(template.exercises);
        }
      }
    }

    // Search in top-level personal templates
    for (final template in library.personalTemplates) {
      if (template.id == _templateId) {
        allExercises.addAll(template.exercises);
      }
    }

    // Search in top-level system templates
    for (final template in library.systemTemplates) {
      if (template.id == _templateId) {
        allExercises.addAll(template.exercises);
      }
    }

    if (_stepOrder.isEmpty) {
      allExercises.sort((a, b) => a.order.compareTo(b.order));
      return allExercises;
    }

    final stepMap = {for (final s in allExercises) s.id: s};
    final ordered = <TemplateExercise>[];
    for (final id in _stepOrder) {
      if (stepMap.containsKey(id)) ordered.add(stepMap[id]!);
    }
    // Append steps not yet tracked locally
    for (final s in allExercises) {
      if (!_stepOrder.contains(s.id)) ordered.add(s);
    }
    return ordered;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final step = _stepOrder.removeAt(oldIndex);
      _stepOrder.insert(newIndex, step);
    });
  }

  // ---------------------------------------------------------------------------
  // Finish
  // ---------------------------------------------------------------------------

  void _finishEditing() {
    context.pop(true);
  }

  // ---------------------------------------------------------------------------
  // Build helpers – Phase 0: create form
  // ---------------------------------------------------------------------------

  Widget _buildPhase0() {
    final programsState = ref.watch(clientProgramsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Template',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          if (widget.programId == null) ...[
            _buildProgramDropdown(programsState),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Template Name',
              hintText: 'e.g. Full Body A',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'e.g. Push day focusing on chest and shoulders',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _canCreate ? _createTemplate : null,
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramDropdown(ClientProgramsState state) {
    final programs = state.library?.personalPrograms ?? [];
    return DropdownButtonFormField<String>(
      initialValue: _selectedProgramId.isEmpty ? null : _selectedProgramId,
      decoration: const InputDecoration(
        labelText: 'Program',
        hintText: 'Select a program',
      ),
      items: programs.map((p) {
        return DropdownMenuItem(
          value: p.id,
          child: Text(p.name),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedProgramId = val);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build helpers – Phase 1: edit steps
  // ---------------------------------------------------------------------------

  Widget _buildPhase1() {
    final state = ref.watch(clientProgramsProvider);
    final steps = _orderedSteps(state);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Steps',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Text(
                '${steps.length} step${steps.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // Step list or empty state
        if (steps.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center_outlined,
                      size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No steps yet',
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text('Add exercises and rest periods below',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              itemCount: steps.length,
              onReorder: _onReorder,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final step = steps[index];
                final stepName = _stepExerciseNames[step.id] ??
                    step.exerciseId ??
                    'Exercise';
                final subtitle = step.type == StepType.rest
                    ? '${step.durationSeconds ?? 60}s rest'
                    : [
                        if (step.targetSets != null)
                          '${step.targetSets}×${step.targetReps ?? ''}',
                        if (step.tempo != null && step.tempo!.isNotEmpty)
                          step.tempo!,
                      ].join(' · ');

                return Card(
                  key: ValueKey(step.id),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    title: Text(stepName),
                    subtitle: subtitle.isNotEmpty
                        ? Text(subtitle,
                            style: theme.textTheme.bodySmall)
                        : null,
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: theme.colorScheme.error),
                      onPressed: () => _deleteStep(step.id),
                    ),
                  ),
                );
              },
            ),
          ),
        // Bottom actions
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _openAddExerciseDialog,
                icon: const Icon(Icons.fitness_center),
                label: const Text('Add Exercise'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _openAddRestDialog,
                icon: const Icon(Icons.timer),
                label: const Text('Add Rest'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _finishEditing,
                icon: const Icon(Icons.check),
                label: const Text('Finish'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_phase == 0 ? 'New Template' : 'Edit Steps'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _phase == 0 ? _buildPhase0() : _buildPhase1(),
    );
  }
}

// ---------------------------------------------------------------------------
// _AddExerciseDialog – exercise creation form
// ---------------------------------------------------------------------------

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog();

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _tempoController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'MAIN';
  final List<String> _categories = ['MAIN', 'SUPERSET', 'WARMUP', 'COOLDOWN'];

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _tempoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.of(context).pop(<String, dynamic>{
      '_exerciseName': name,
      'name': name,
      'target_sets': int.tryParse(_setsController.text.trim()),
      'target_reps': _repsController.text.trim(),
      'tempo': _tempoController.text.trim(),
      'notes': _notesController.text.trim(),
      'category': _category,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Exercise'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g. Bench Press',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    decoration: const InputDecoration(
                      labelText: 'Target Sets',
                      hintText: '3',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    decoration: const InputDecoration(
                      labelText: 'Target Reps',
                      hintText: '10',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tempoController,
              decoration: const InputDecoration(
                labelText: 'Tempo',
                hintText: 'e.g. 2-0-2-0',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(() => _category = val ?? 'MAIN'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _AddRestDialog – simple rest duration picker
// ---------------------------------------------------------------------------

class _AddRestDialog extends StatefulWidget {
  const _AddRestDialog();

  @override
  State<_AddRestDialog> createState() => _AddRestDialogState();
}

class _AddRestDialogState extends State<_AddRestDialog> {
  int _duration = 60;

  static const _presets = [30, 45, 60, 90, 120, 180];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Rest Duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_duration}s',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _duration.toDouble(),
            min: 30,
            max: 180,
            divisions: 15,
            label: '${_duration}s',
            onChanged: (val) => setState(() => _duration = val.round()),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _presets.map((s) {
              final isSelected = _duration == s;
              return ChoiceChip(
                label: Text('${s}s'),
                selected: isSelected,
                onSelected: (_) => setState(() => _duration = s),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_duration),
          child: const Text('Add Rest'),
        ),
      ],
    );
  }
}
