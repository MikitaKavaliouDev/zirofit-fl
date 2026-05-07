import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/providers/exercise_provider.dart';

class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() =>
      _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String? _selectedCategory;
  String? _selectedMuscleGroup;

  static const _categories = ['Strength', 'Cardio', 'Flexibility'];
  static const _muscleGroups = [
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseListProvider.notifier).fetchExercises();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(exerciseListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(exerciseListProvider.notifier).fetchExercises(
            search: value.isNotEmpty ? value : null,
            category: _selectedCategory,
            muscleGroup: _selectedMuscleGroup,
          );
    });
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });
    ref.read(exerciseListProvider.notifier).fetchExercises(
          search:
              _searchController.text.isNotEmpty ? _searchController.text : null,
          category: _selectedCategory,
          muscleGroup: _selectedMuscleGroup,
        );
  }

  void _onMuscleGroupChanged(String? muscleGroup) {
    setState(() => _selectedMuscleGroup = muscleGroup);
    ref.read(exerciseListProvider.notifier).fetchExercises(
          search:
              _searchController.text.isNotEmpty ? _searchController.text : null,
          category: _selectedCategory,
          muscleGroup: _selectedMuscleGroup,
        );
  }

  void _refresh() {
    ref.read(exerciseListProvider.notifier).fetchExercises(
          search:
              _searchController.text.isNotEmpty ? _searchController.text : null,
          category: _selectedCategory,
          muscleGroup: _selectedMuscleGroup,
        );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(exerciseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/trainer/exercises/custom'),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Custom'),
          ),
        ],
      ),
      body: Column(
        children: [
          // -- Search bar --
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // -- Category filter chips + Muscle group dropdown --
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final category in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) => _onCategoryChanged(category),
                    ),
                  ),
                // Muscle group dropdown styled as a chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<String?>(
                    initialValue: _selectedMuscleGroup,
                    onSelected: _onMuscleGroupChanged,
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Muscles'),
                      ),
                      ..._muscleGroups.map(
                        (mg) => PopupMenuItem(
                          value: mg,
                          child: Text(mg),
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedMuscleGroup != null
                            ? theme.colorScheme.secondaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedMuscleGroup ?? 'Muscle',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _selectedMuscleGroup != null
                                  ? theme.colorScheme.onSecondaryContainer
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: _selectedMuscleGroup != null
                                ? theme.colorScheme.onSecondaryContainer
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -- Content --
          Expanded(child: _buildBody(theme, state)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body builders
  // ---------------------------------------------------------------------------

  Widget _buildBody(ThemeData theme, ExerciseListState state) {
    // Initial / loading (first page)
    if (state.status == ExerciseListStatus.initial ||
        (state.isLoading && state.exercises.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error (no cached data)
    if (state.hasError && state.exercises.isEmpty) {
      return _buildErrorState(theme, state.error!);
    }

    // Empty (loaded successfully, no results)
    if (state.isLoaded && state.exercises.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Data list with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: state.exercises.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the bottom
          if (index == state.exercises.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
            );
          }
          return _ExerciseCard(exercise: state.exercises[index]);
        },
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
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

// ---------------------------------------------------------------------------
// Exercise Card
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseCard({required this.exercise});

  IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'flexibility':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _categoryIcon(exercise.category),
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        title: Text(
          exercise.name,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (exercise.muscleGroup != null)
                Text(
                  exercise.muscleGroup!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (exercise.equipment != null)
                Text(
                  exercise.equipment!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            exercise.category ?? 'General',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () {
          // TODO: Navigate to exercise detail
        },
      ),
    );
  }
}
