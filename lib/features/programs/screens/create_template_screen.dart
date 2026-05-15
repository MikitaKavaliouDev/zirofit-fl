import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/enums/exercise_category.dart';
import 'package:zirofit_fl/data/models/enums/step_type.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/data/models/template_exercise.dart';
import 'package:zirofit_fl/features/exercises/providers/exercise_provider.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';

// ---------------------------------------------------------------------------
// Screen Phase
// ---------------------------------------------------------------------------

enum _ScreenPhase { creating, editing }

// ---------------------------------------------------------------------------
// CreateTemplateScreen
// ---------------------------------------------------------------------------

class CreateTemplateScreen extends ConsumerStatefulWidget {
  /// Optional program ID to pre-select in the program dropdown.
  final String? programId;

  const CreateTemplateScreen({super.key, this.programId});

  @override
  ConsumerState<CreateTemplateScreen> createState() =>
      _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends ConsumerState<CreateTemplateScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedProgramId = '';
  _ScreenPhase _phase = _ScreenPhase.creating;
  bool _isLoading = false;
  final List<String> _stepOrder = [];
  // Cache exercise names from the add flow (TemplateExercise has no name field)
  final Map<String, String> _stepExerciseNames = {};

  @override
  void initState() {
    super.initState();
    _selectedProgramId = widget.programId ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(programsProvider);
      if (state.userPrograms.isEmpty && !state.isLoading) {
        ref.read(programsProvider.notifier).fetchProgramsAndTemplates();
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
  // Phase 1 – Create the template
  // ---------------------------------------------------------------------------

  Future<void> _createTemplate() async {
    if (!_canCreate) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final template =
        await ref.read(programsProvider.notifier).createTemplate(
              name: name,
              description: description.isNotEmpty ? description : null,
              programId: _selectedProgramId,
            );

    if (!mounted) return;

    if (template != null) {
      // Load existing steps (if any) and transition to editing
      await ref.read(programsProvider.notifier).startEditingTemplate(
            template.id,
            _selectedProgramId,
          );

      if (!mounted) return;

      final state = ref.read(programsProvider);
      setState(() {
        _isLoading = false;
        _phase = _ScreenPhase.editing;
        _stepOrder
          ..clear()
          ..addAll(state.templateExercises.map((s) => s.id));
      });
    } else {
      final state = ref.read(programsProvider);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Failed to create template'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 2 – Add Exercise Step
  // ---------------------------------------------------------------------------

  Future<void> _openAddExerciseSheet() async {
    // Ensure exercises are loaded
    final exState = ref.read(exerciseListProvider);
    if (exState.exercises.isEmpty &&
        exState.status == ExerciseListStatus.initial) {
      ref.read(exerciseListProvider.notifier).fetchExercises();
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddExerciseSheet(),
    );

    if (result == null || !mounted) return;

    setState(() => _isLoading = true);

    final exerciseName = result.remove('_exerciseName') as String?;
    final step =
        await ref.read(programsProvider.notifier).addExerciseStep(result);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (step != null) {
      setState(() {
        _stepOrder.add(step.id);
        if (exerciseName != null) {
          _stepExerciseNames[step.id] = exerciseName;
        }
      });
    } else {
      final pState = ref.read(programsProvider);
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
  // Phase 2 – Add Rest Step
  // ---------------------------------------------------------------------------

  Future<void> _openAddRestSheet() async {
    final duration = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RestDurationPicker(),
    );

    if (duration == null || !mounted) return;

    setState(() => _isLoading = true);

    final step =
        await ref.read(programsProvider.notifier).addRestStep(duration);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (step != null) {
      setState(() => _stepOrder.add(step.id));
    } else {
      final pState = ref.read(programsProvider);
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
  // Phase 2 – Delete Step
  // ---------------------------------------------------------------------------

  Future<void> _deleteStep(String stepId) async {
    setState(() => _isLoading = true);
    final success =
        await ref.read(programsProvider.notifier).deleteExerciseStep(stepId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (success) {
        _stepOrder.remove(stepId);
        _stepExerciseNames.remove(stepId);
      }
    });

    if (!success && mounted) {
      final pState = ref.read(programsProvider);
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

  List<TemplateExercise> get _orderedSteps {
    final steps = ref.watch(programsProvider).templateExercises;
    if (_stepOrder.isEmpty) return steps;
    final stepMap = {for (final s in steps) s.id: s};
    final ordered = <TemplateExercise>[];
    for (final id in _stepOrder) {
      if (stepMap.containsKey(id)) ordered.add(stepMap[id]!);
    }
    // Append any steps not yet in the order list
    for (final s in steps) {
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
  // Finish / Done
  // ---------------------------------------------------------------------------

  void _finishEditing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template saved')),
    );
    context.pop();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(programsProvider);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Stack(
        children: [
          if (_phase == _ScreenPhase.creating)
            _buildCreatingPhase(theme, state)
          else
            _buildEditingPhase(theme),
          if (_isLoading) _buildLoadingOverlay(theme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      leading: TextButton(
        onPressed: () => context.pop(),
        child: Text(
          'Cancel',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      title: Text(
        _phase == _ScreenPhase.creating ? 'New Template' : 'Edit Template',
      ),
      centerTitle: true,
      actions: [
        if (_phase == _ScreenPhase.editing)
          TextButton(
            onPressed: _isLoading ? null : _finishEditing,
            child: Text(
              'Done',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _isLoading
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Creating Phase
  // ---------------------------------------------------------------------------

  Widget _buildCreatingPhase(ThemeData theme, ProgramsState state) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNameField(theme),
            const SizedBox(height: 12),
            _buildDescriptionField(theme),
            const SizedBox(height: 16),
            _buildProgramDropdown(theme, state),
            const SizedBox(height: 24),
            _buildCreateButton(theme),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return TextField(
      controller: _nameController,
      onChanged: (_) => setState(() {}),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Template Name (e.g. Leg Day)',
        hintStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return TextField(
      controller: _descriptionController,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Description (Optional)',
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildProgramDropdown(ThemeData theme, ProgramsState state) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedProgramId.isNotEmpty ? _selectedProgramId : null,
      decoration: InputDecoration(
        labelText: 'Program',
        hintText: 'Select a program',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: state.userPrograms.map((p) {
        return DropdownMenuItem(
          value: p.id,
          child: Text(p.name),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedProgramId = val ?? ''),
    );
  }

  Widget _buildCreateButton(ThemeData theme) {
    return FilledButton(
      onPressed: _canCreate ? _createTemplate : null,
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Create Template'),
    );
  }

  // ---------------------------------------------------------------------------
  // Editing Phase
  // ---------------------------------------------------------------------------

  Widget _buildEditingPhase(ThemeData theme) {
    final steps = _orderedSteps;
    final state = ref.watch(programsProvider);

    if (state.isLoading && steps.isEmpty && _stepOrder.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (steps.isNotEmpty) _buildSectionHeader(theme, steps.length),
        Expanded(
          child: steps.isEmpty
              ? _buildEmptyEditingState(theme)
              : _buildReorderableList(theme, steps),
        ),
        _buildEditingActions(theme),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            'Steps',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEditingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 60,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'Add exercises and rest steps',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableList(ThemeData theme, List<TemplateExercise> steps) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: steps.length,
      onReorder: _onReorder,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
      itemBuilder: (context, index) {
        return _buildStepTile(theme, steps[index], index);
      },
    );
  }

  Widget _buildEditingActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _openAddExerciseSheet,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.fitness_center, size: 20),
                label: const Text('Add Exercise'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _openAddRestSheet,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.timer, size: 20),
                label: const Text('Add Rest'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step Tile
  // ---------------------------------------------------------------------------

  Widget _buildStepTile(ThemeData theme, TemplateExercise step, int index) {
    final isRest = step.type == StepType.rest;

    return Container(
      key: ValueKey(step.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.line_weight,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Step info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRest)
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rest ${step.durationSeconds ?? 60}s',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Text(
                      _stepExerciseNames[step.id] ?? 'Exercise',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (step.tempo != null && step.tempo!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                step.tempo!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (step.targetReps != null)
                          Text(
                            '${step.targetReps} reps',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (step.targetReps != null &&
                            step.targetSets != null)
                          Text(
                            ' · ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (step.targetSets != null)
                          Text(
                            '${step.targetSets} sets',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (step.enableRpe)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'RPE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Delete button
            IconButton(
              onPressed: () => _deleteStep(step.id),
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading Overlay
  // ---------------------------------------------------------------------------

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Saving...'),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AddExerciseSheet – inline exercise search + configuration bottom sheet
// ---------------------------------------------------------------------------

class _AddExerciseSheet extends ConsumerStatefulWidget {
  const _AddExerciseSheet();

  @override
  ConsumerState<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<_AddExerciseSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  Exercise? _selectedExercise;
  final _tempoController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _restController = TextEditingController(text: '60');
  ExerciseCategory _category = ExerciseCategory.main;
  bool _enableRpe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(exerciseListProvider);
      if (state.exercises.isEmpty &&
          state.status == ExerciseListStatus.initial) {
        ref.read(exerciseListProvider.notifier).fetchExercises();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _tempoController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(exerciseListProvider.notifier).fetchExercises(
            search: value.isNotEmpty ? value : null,
          );
    });
  }

  void _confirm() {
    final fields = <String, dynamic>{
      'exercise_id': _selectedExercise!.id,
      '_exerciseName': _selectedExercise!.name,
      'tempo': _tempoController.text.isNotEmpty ? _tempoController.text : null,
      'exercise_category': _category.toJson(),
      'target_reps':
          _repsController.text.isNotEmpty ? _repsController.text : null,
      'target_sets': int.tryParse(_setsController.text),
      'duration_seconds': int.tryParse(_restController.text),
      'enable_rpe': _enableRpe,
    };
    fields.removeWhere((_, v) => v == null);
    Navigator.of(context).pop(fields);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Add Exercise',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Exercise list or config form
            Expanded(
              child: _selectedExercise == null
                  ? _buildExerciseList(theme)
                  : _buildConfigForm(theme),
            ),
            // Confirm button
            if (_selectedExercise != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Add to Template'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(ThemeData theme) {
    final exState = ref.watch(exerciseListProvider);
    final exercises = exState.exercises;

    if (exState.status == ExerciseListStatus.loading && exercises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (exState.hasError && exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 8),
            Text(
              exState.error ?? 'Failed to load exercises',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    if (exercises.isEmpty) {
      return Center(
        child: Text(
          'No exercises found',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isSelected = _selectedExercise?.id == exercise.id;
        return ListTile(
          selected: isSelected,
          selectedTileColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.fitness_center,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            exercise.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: exercise.muscleGroup != null
              ? Text(
                  exercise.muscleGroup!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          onTap: () => setState(() => _selectedExercise = exercise),
        );
      },
    );
  }

  Widget _buildConfigForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected exercise badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedExercise!.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedExercise = null),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tempo
          Text('Tempo', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          TextField(
            controller: _tempoController,
            decoration: InputDecoration(
              hintText: 'e.g. 3010',
              helperText:
                  '4-digit notation (eccentric, pause, concentric, pause)',
              helperMaxLines: 2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          // Category
          Text('Category', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          DropdownButtonFormField<ExerciseCategory>(
            initialValue: _category,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: ExerciseCategory.values.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(c.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (val) =>
                setState(() => _category = val ?? ExerciseCategory.main),
          ),
          const SizedBox(height: 16),
          // Reps & Sets row
          Row(
            children: [
              Expanded(
                child: _buildLabeledField(
                  theme,
                  label: 'Target Reps',
                  hint: 'e.g. 8-12',
                  controller: _repsController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLabeledField(
                  theme,
                  label: 'Target Sets',
                  hint: 'e.g. 3',
                  controller: _setsController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rest after exercise
          _buildLabeledField(
            theme,
            label: 'Rest after exercise (seconds)',
            hint: 'e.g. 60',
            controller: _restController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          // Enable RPE toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable RPE'),
            subtitle: const Text('Rate of Perceived Exertion'),
            value: _enableRpe,
            onChanged: (val) => setState(() => _enableRpe = val),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField(
    ThemeData theme, {
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: keyboardType,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _RestDurationPicker – simple rest duration bottom sheet
// ---------------------------------------------------------------------------

class _RestDurationPicker extends StatefulWidget {
  const _RestDurationPicker();

  @override
  State<_RestDurationPicker> createState() => _RestDurationPickerState();
}

class _RestDurationPickerState extends State<_RestDurationPicker> {
  int _duration = 60;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Rest Duration',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${_duration}s',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _duration.toDouble(),
            min: 10,
            max: 300,
            divisions: 29,
            label: '${_duration}s',
            onChanged: (val) => setState(() => _duration = val.round()),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [30, 45, 60, 90, 120, 180].map((s) {
              final isSelected = _duration == s;
              return ChoiceChip(
                label: Text('${s}s'),
                selected: isSelected,
                onSelected: (_) => setState(() => _duration = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_duration),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Add Rest Step'),
          ),
        ],
      ),
    );
  }
}
