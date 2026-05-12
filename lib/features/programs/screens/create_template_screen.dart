import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/exercise_selection_view.dart';

// ---------------------------------------------------------------------------
// TemplateStep – local model for a step in the template being built
// ---------------------------------------------------------------------------

class TemplateStep {
  final String id;
  final String type;
  final Exercise exercise;

  const TemplateStep({
    required this.id,
    required this.type,
    required this.exercise,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateStep && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// CreateTemplateScreen
// ---------------------------------------------------------------------------

class CreateTemplateScreen extends ConsumerStatefulWidget {
  const CreateTemplateScreen({super.key});

  @override
  ConsumerState<CreateTemplateScreen> createState() =>
      _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends ConsumerState<CreateTemplateScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TemplateStep> _steps = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _steps.isNotEmpty &&
      !_isSaving;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _saveTemplate() async {
    if (!_canSave) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final exerciseIds = _steps.map((s) => s.exercise.id).toList();

    final success = await ref.read(programsProvider.notifier).createTemplate(
          name: name,
          description: description.isNotEmpty ? description : null,
          exerciseIds: exerciseIds,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template "$name" created')),
      );
      context.pop();
    } else {
      final state = ref.read(programsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Failed to create template'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _openExercisePicker() {
    Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => ExerciseSelectionView(
          onDone: (selectedExercises) {
            setState(() {
              for (final ex in selectedExercises) {
                // Avoid duplicates by checking exercise ID
                final alreadyAdded =
                    _steps.any((s) => s.exercise.id == ex.id);
                if (!alreadyAdded) {
                  _steps.add(TemplateStep(
                    id: '${ex.id}_${DateTime.now().millisecondsSinceEpoch}',
                    type: 'exercise',
                    exercise: ex,
                  ));
                }
              }
            });
          },
        ),
      ),
    );
  }

  void _removeStep(int index) {
    setState(() => _steps.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'Cancel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        title: const Text('New Template'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _canSave ? _saveTemplate : null,
            child: Text(
              'Save',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _canSave
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                // Header section
                _buildHeaderSection(theme),
                // Content (empty state or list)
                Expanded(
                  child: _steps.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildStepList(theme),
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_isSaving) _buildLoadingOverlay(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header section
  // ---------------------------------------------------------------------------

  Widget _buildHeaderSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          TextField(
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
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
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
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(ThemeData theme) {
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
              'Your Template is Empty',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openExercisePicker,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Exercise'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step list (ReorderableListView)
  // ---------------------------------------------------------------------------

  Widget _buildStepList(ThemeData theme) {
    return Column(
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                'Exercises',
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
                  '${_steps.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Reorderable list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: _steps.length + 1, // +1 for the "Add Exercise" button
            onReorder: _onReorder,
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
            itemBuilder: (context, index) {
              if (index == _steps.length) {
                return _buildAddExerciseTile(theme, key: const ValueKey('__add_button__'));
              }
              return _buildExerciseTile(theme, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseTile(ThemeData theme, int index) {
    final step = _steps[index];
    final exercise = step.exercise;

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
            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exercise.muscleGroup != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      exercise.muscleGroup!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Delete button
            IconButton(
              onPressed: () => _removeStep(index),
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

  Widget _buildAddExerciseTile(ThemeData theme, {required Key key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: OutlinedButton.icon(
        onPressed: _openExercisePicker,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: const Text('Add Exercise'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading overlay
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
              Text('Saving Template...'),
            ],
          ),
        ),
      ),
    );
  }
}
