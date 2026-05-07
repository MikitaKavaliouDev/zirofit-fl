import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/trainer/providers/custom_exercises_provider.dart';

class CustomExercisesScreen extends ConsumerStatefulWidget {
  const CustomExercisesScreen({super.key});

  @override
  ConsumerState<CustomExercisesScreen> createState() =>
      _CustomExercisesScreenState();
}

class _CustomExercisesScreenState
    extends ConsumerState<CustomExercisesScreen> {
  static const List<String> _muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Legs',
    'Glutes',
    'Core',
    'Full Body',
  ];

  static const List<String> _equipmentOptions = [
    'None',
    'Barbell',
    'Dumbbell',
    'Kettlebell',
    'Cable',
    'Machine',
    'Resistance Bands',
    'Bodyweight',
    'EZ Bar',
    'Medicine Ball',
    'TRX',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerCustomExercisesProvider.notifier).fetchExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(trainerCustomExercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Exercises'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddExerciseDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add'),
          ),
        ],
      ),
      body: state.isLoading && state.exercises.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.exercises.isEmpty
              ? _buildEmptyState(theme)
              : _buildExercisesList(theme, state.exercises),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No custom exercises yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create custom exercises for your clients',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddExerciseDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(ThemeData theme, List<Exercise> exercises) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(trainerCustomExercisesProvider.notifier).fetchExercises(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return _ExerciseCard(
            exercise: exercise,
            onEdit: () => _showEditExerciseDialog(context, exercise),
            onDelete: () => _showDeleteConfirmation(context, exercise),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add Exercise Dialog
  // ---------------------------------------------------------------------------

  void _showAddExerciseDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final videoUrlController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedMuscleGroup = _muscleGroups.first;
    String selectedEquipment = _equipmentOptions.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Exercise'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Name *',
                      hintText: 'e.g., Bulgarian Split Squat',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Describe the exercise...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Muscle Group *',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _muscleGroups.map((mg) {
                      final isSelected = mg == selectedMuscleGroup;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(mg, style: const TextStyle(fontSize: 12)),
                        onSelected: (_) => setState(() => selectedMuscleGroup = mg),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Equipment',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _equipmentOptions.map((eq) {
                      final isSelected = eq == selectedEquipment;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(eq, style: const TextStyle(fontSize: 12)),
                        onSelected: (_) =>
                            setState(() => selectedEquipment = eq),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: videoUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Video URL (optional)',
                      hintText: 'https://youtube.com/watch?v=...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null || !uri.hasScheme) {
                        return 'Enter a valid URL (include https://)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final Map<String, dynamic> data = {
                    'name': nameController.text,
                    'muscleGroup': selectedMuscleGroup,
                    'equipment': selectedEquipment,
                  };
                  if (descriptionController.text.trim().isNotEmpty) {
                    data['description'] = descriptionController.text;
                  }
                  if (videoUrlController.text.trim().isNotEmpty) {
                    data['videoUrl'] = videoUrlController.text;
                  }
                  ref
                      .read(trainerCustomExercisesProvider.notifier)
                      .createExercise(data);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit Exercise Dialog
  // ---------------------------------------------------------------------------

  void _showEditExerciseDialog(BuildContext context, Exercise exercise) {
    final nameController = TextEditingController(text: exercise.name);
    final descriptionController =
        TextEditingController(text: exercise.description ?? '');
    final videoUrlController =
        TextEditingController(text: exercise.videoUrl ?? '');
    final formKey = GlobalKey<FormState>();
    String selectedMuscleGroup = exercise.muscleGroup ?? _muscleGroups.first;
    String selectedEquipment = exercise.equipment ?? _equipmentOptions.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Exercise'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Muscle Group *',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _muscleGroups.map((mg) {
                      final isSelected = mg == selectedMuscleGroup;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(mg, style: const TextStyle(fontSize: 12)),
                        onSelected: (_) => setState(() => selectedMuscleGroup = mg),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Equipment',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _equipmentOptions.map((eq) {
                      final isSelected = eq == selectedEquipment;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(eq, style: const TextStyle(fontSize: 12)),
                        onSelected: (_) =>
                            setState(() => selectedEquipment = eq),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: videoUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Video URL (optional)',
                      hintText: 'https://youtube.com/watch?v=...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null || !uri.hasScheme) {
                        return 'Enter a valid URL (include https://)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final Map<String, dynamic> data = {
                    'name': nameController.text,
                    'muscleGroup': selectedMuscleGroup,
                    'equipment': selectedEquipment,
                  };
                  if (descriptionController.text.trim().isNotEmpty) {
                    data['description'] = descriptionController.text;
                  }
                  if (videoUrlController.text.trim().isNotEmpty) {
                    data['videoUrl'] = videoUrlController.text;
                  }
                  ref
                      .read(trainerCustomExercisesProvider.notifier)
                      .updateExercise(exercise.id, data);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete Confirmation
  // ---------------------------------------------------------------------------

  void _showDeleteConfirmation(BuildContext context, Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
          'Are you sure you want to delete "${exercise.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(trainerCustomExercisesProvider.notifier)
                  .deleteExercise(exercise.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${exercise.name}" deleted')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise Card
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseCard({
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (exercise.description != null &&
                          exercise.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          exercise.description!,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Delete'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (exercise.muscleGroup != null)
                  _TagChip(
                    label: exercise.muscleGroup!,
                    icon: Icons.accessibility_new,
                    color: Colors.blue,
                  ),
                if (exercise.equipment != null)
                  _TagChip(
                    label: exercise.equipment!,
                    icon: Icons.build,
                    color: Colors.orange,
                  ),
                if (exercise.videoUrl != null)
                  _TagChip(
                    label: 'Video',
                    icon: Icons.videocam,
                    color: Colors.red,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tag Chip
// ---------------------------------------------------------------------------

class _TagChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TagChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
