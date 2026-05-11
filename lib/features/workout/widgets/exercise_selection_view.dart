import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/providers/exercise_provider.dart';
import 'package:zirofit_fl/features/exercises/widgets/exercise_row.dart';

// ---------------------------------------------------------------------------
// Sort mode
// ---------------------------------------------------------------------------

enum _SortMode { aToZ, mostUsed, recentlyUsed }

// ---------------------------------------------------------------------------
// ExerciseSelectionView
// ---------------------------------------------------------------------------

/// A full-screen exercise browser / selector.
///
/// Presents a searchable, filterable, multi-selectable list of exercises built
/// on top of [exerciseListProvider]. Returns selected exercises via [onDone].
class ExerciseSelectionView extends ConsumerStatefulWidget {
  const ExerciseSelectionView({
    super.key,
    this.onDone,
  });

  /// Called with the selected [Exercise] list when the user taps Done or the
  /// bottom "Add N Exercises" button.
  final void Function(List<Exercise> selected)? onDone;

  @override
  ConsumerState<ExerciseSelectionView> createState() =>
      _ExerciseSelectionViewState();
}

class _ExerciseSelectionViewState
    extends ConsumerState<ExerciseSelectionView> {
  // -- controllers --
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  // -- selection state (ephemeral) --
  final Set<String> _selectedIds = {};

  // -- filter / sort state --
  _SortMode _sortMode = _SortMode.aToZ;
  String? _selectedBodyPart;
  String? _selectedCategory;

  // -- section keys for alphabet index scrolling --
  final Map<String, GlobalKey> _sectionKeys = {};

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Fetch exercises on initial load, matching ExerciseListScreen pattern.
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
  // Scroll → load more
  // ---------------------------------------------------------------------------

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(exerciseListProvider.notifier).loadMore();
    }
  }

  // ---------------------------------------------------------------------------
  // Search (400 ms debounce)
  // ---------------------------------------------------------------------------

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(exerciseListProvider.notifier).fetchExercises(
            search: value.isNotEmpty ? value : null,
          );
    });
  }

  void _onSearchCleared() {
    _searchController.clear();
    _debounce?.cancel();
    ref.read(exerciseListProvider.notifier).fetchExercises(search: null);
  }

  // ---------------------------------------------------------------------------
  // Sort / filter
  // ---------------------------------------------------------------------------

  void _onSortChanged(_SortMode? mode) {
    if (mode != null) setState(() => _sortMode = mode);
  }

  void _onBodyPartChanged(String? bodyPart) {
    setState(() => _selectedBodyPart = bodyPart);
  }

  void _onCategoryChanged(String? category) {
    setState(() => _selectedCategory = category);
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void _onExerciseTap(Exercise exercise) {
    setState(() {
      if (_selectedIds.contains(exercise.id)) {
        _selectedIds.remove(exercise.id);
      } else {
        _selectedIds.add(exercise.id);
      }
    });
  }

  void _onDone() {
    if (_selectedIds.isEmpty) return;
    final allExercises = ref.read(exerciseListProvider).exercises;
    final selected =
        allExercises.where((e) => _selectedIds.contains(e.id)).toList();
    widget.onDone?.call(selected);
  }

  // ---------------------------------------------------------------------------
  // Client-side filtering & grouping
  // ---------------------------------------------------------------------------

  /// Returns the exercises from the provider, filtered by body part & category.
  List<Exercise> _getFilteredExercises() {
    final state = ref.read(exerciseListProvider);
    var exercises = state.exercises;

    if (_selectedBodyPart != null) {
      exercises = exercises
          .where((e) =>
              e.muscleGroup?.toLowerCase() == _selectedBodyPart!.toLowerCase())
          .toList();
    }

    if (_selectedCategory != null) {
      exercises = exercises
          .where((e) =>
              e.category?.toLowerCase() == _selectedCategory!.toLowerCase())
          .toList();
    }

    return exercises;
  }

  /// Groups exercises by their first letter (A-Z, then #).
  Map<String, List<Exercise>> _groupByFirstLetter(List<Exercise> exercises) {
    final map = <String, List<Exercise>>{};
    for (final ex in exercises) {
      final letter = ex.name.isNotEmpty
          ? ex.name[0].toUpperCase()
          : '#';
      // Only keep A-Z and #
      final code = letter.codeUnitAt(0);
      final key = (code >= 65 && code <= 90) ? letter : '#';
      map.putIfAbsent(key, () => []).add(ex);
    }
    // Sort keys: A-Z first, then #
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return {for (final k in sortedKeys) k: map[k]!};
  }

  /// Returns derived muscle groups from the current list.
  List<String> _getBodyParts() {
    final state = ref.read(exerciseListProvider);
    final result = state.exercises
        .map((e) => e.muscleGroup)
        .where((mg) => mg != null && mg.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return result.cast<String>();
  }

  /// Returns derived categories from the current list.
  List<String> _getCategories() {
    final state = ref.read(exerciseListProvider);
    final result = state.exercises
        .map((e) => e.category)
        .where((c) => c != null && c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return result.cast<String>();
  }

  // ---------------------------------------------------------------------------
  // Alphabet index scrolling
  // ---------------------------------------------------------------------------

  void _scrollToSection(String letter) {
    final key = _sectionKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.05,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(exerciseListProvider);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildSearchBar(theme),
          _buildFilterRow(theme),
          Expanded(child: _buildContent(theme, state)),
          if (_selectedIds.isNotEmpty) _buildBottomBar(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      leading: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Cancel',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      title: Text(
        'Add Exercise',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _selectedIds.isNotEmpty ? _onDone : null,
          child: Text(
            'Done',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _selectedIds.isNotEmpty
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.38),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search exercises...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _onSearchCleared,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter chips row
  // ---------------------------------------------------------------------------

  Widget _buildFilterRow(ThemeData theme) {
    final bodyParts = _getBodyParts();
    final categories = _getCategories();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          // -- Body part dropdown --
          _FilterChipDropdown<String>(
            label: _selectedBodyPart ?? 'Body Part',
            isActive: _selectedBodyPart != null,
            items: [
              const PopupMenuItem(
                value: null,
                child: Text('All Body Parts'),
              ),
              ...bodyParts.map(
                (bp) => PopupMenuItem(
                  value: bp,
                  child: Text(bp),
                ),
              ),
            ],
            onSelected: _onBodyPartChanged,
            theme: theme,
          ),
          const SizedBox(width: 8),
          // -- Category dropdown --
          _FilterChipDropdown<String>(
            label: _selectedCategory ?? 'Category',
            isActive: _selectedCategory != null,
            items: [
              const PopupMenuItem(
                value: null,
                child: Text('All Categories'),
              ),
              ...categories.map(
                (c) => PopupMenuItem(
                  value: c,
                  child: Text(c),
                ),
              ),
            ],
            onSelected: _onCategoryChanged,
            theme: theme,
          ),
          const SizedBox(width: 8),
          // -- Sort dropdown --
          _FilterChipDropdown<_SortMode>(
            label: switch (_sortMode) {
              _SortMode.aToZ => 'A-Z',
              _SortMode.mostUsed => 'Most Used',
              _SortMode.recentlyUsed => 'Recently Used',
            },
            isActive: true,
            items: [
              const PopupMenuItem(
                value: _SortMode.aToZ,
                child: Text('A-Z'),
              ),
              const PopupMenuItem(
                value: _SortMode.mostUsed,
                child: Text('Most Used'),
              ),
              const PopupMenuItem(
                value: _SortMode.recentlyUsed,
                child: Text('Recently Used'),
              ),
            ],
            onSelected: _onSortChanged,
            theme: theme,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content (loading / error / empty / list)
  // ---------------------------------------------------------------------------

  Widget _buildContent(ThemeData theme, ExerciseListState state) {
    // Initial / loading (no cached data)
    if (state.status == ExerciseListStatus.initial ||
        (state.isLoading && state.exercises.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (state.hasError && state.exercises.isEmpty) {
      return _buildErrorState(theme, state.error!);
    }

    // Apply client-side filters
    final filtered = _getFilteredExercises();

    // Empty after filtering
    if (filtered.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Sort / section
    if (_sortMode == _SortMode.aToZ) {
      return _buildSectionedList(theme, filtered, state.isLoadingMore);
    }

    // Flat list for Most Used / Recently Used
    return _buildFlatList(theme, filtered, state.isLoadingMore);
  }

  // ---------------------------------------------------------------------------
  // Sectioned list (A-Z)
  // ---------------------------------------------------------------------------

  Widget _buildSectionedList(
    ThemeData theme,
    List<Exercise> exercises,
    bool isLoadingMore,
  ) {
    final grouped = _groupByFirstLetter(exercises);
    final letters = grouped.keys.toList();

    // Update section keys
    for (final letter in letters) {
      _sectionKeys.putIfAbsent(letter, () => GlobalKey());
    }
    // Remove stale keys
    _sectionKeys.keys
        .where((k) => !grouped.containsKey(k))
        .toList()
        .forEach(_sectionKeys.remove);

    // Build flat item list
    final items = <Object>[];
    for (final letter in letters) {
      items.add(letter); // section header
      items.addAll(grouped[letter]!);
    }

    // Determine if we need the index bar (only when enough sections)
    final showIndex = letters.length > 3;

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: items.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
              );
            }
            final item = items[index];
            if (item is String) {
              // Section header
              return Padding(
                key: _sectionKeys[item],
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  item,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            // Exercise row
            final exercise = item as Exercise;
            return ExerciseRow(
              exercise: exercise,
              searchQuery: ref.read(exerciseListProvider).search,
              isSelected: _selectedIds.contains(exercise.id),
              onTap: () => _onExerciseTap(exercise),
            );
          },
        ),
        // Alphabet index (right side)
        if (showIndex)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onVerticalDragDown: (details) {
                _handleIndexDrag(details.localPosition, letters, context);
              },
              onVerticalDragUpdate: (details) {
                _handleIndexDrag(details.localPosition, letters, context);
              },
              child: Container(
                width: 28,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final letter in letters)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handleIndexDrag(
    Offset localPosition,
    List<String> letters,
    BuildContext context,
  ) {
    // Approximate: each letter takes ~13 logical pixels (10 font + 3 padding)
    const itemHeight = 13.0;
    final index = (localPosition.dy / itemHeight).floor();
    final clamped = index.clamp(0, letters.length - 1);
    _scrollToSection(letters[clamped]);
  }

  // ---------------------------------------------------------------------------
  // Flat list (Most Used / Recently Used)
  // ---------------------------------------------------------------------------

  Widget _buildFlatList(
    ThemeData theme,
    List<Exercise> exercises,
    bool isLoadingMore,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: exercises.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == exercises.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
          );
        }
        final exercise = exercises[index];
        return ExerciseRow(
          exercise: exercise,
          searchQuery: ref.read(exerciseListProvider).search,
          isSelected: _selectedIds.contains(exercise.id),
          onTap: () => _onExerciseTap(exercise),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

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
              onPressed: () =>
                  ref.read(exerciseListProvider.notifier).fetchExercises(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

// ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(ThemeData theme) {
    final searchText = _searchController.text;
    final hasSearch = searchText.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? "Couldn't find '$searchText'?" : 'No exercises found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Create a custom exercise to add to your library.'
                  : 'Try adjusting your search or filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasSearch) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showCreateExerciseDialog(context, searchText),
                icon: const Icon(Icons.add),
                label: Text('Create "$searchText"'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateExerciseDialog(BuildContext context, String exerciseName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Exercise'),
        content: Text('Create a custom exercise named "$exerciseName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Call exercise provider to create custom exercise
      // ref.read(exerciseListProvider.notifier).createCustomExercise(exerciseName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exercise "$exerciseName" created'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Dismiss this sheet and return to let user pick the new exercise
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Exercise Detail View
  // ---------------------------------------------------------------------------

  void _showExerciseDetail(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExerciseDetailSheet(exercise: exercise),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar ("Add N Exercises")
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _onDone,
            child: Text('Add ${_selectedIds.length} Exercise${_selectedIds.length == 1 ? '' : 's'}'),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Chip Dropdown
// ---------------------------------------------------------------------------

/// A [PopupMenuButton] styled as a chip/dropdown for filter rows.
class _FilterChipDropdown<T> extends StatelessWidget {
  const _FilterChipDropdown({
    required this.label,
    required this.isActive,
    required this.items,
    required this.onSelected,
    required this.theme,
  });

  final String label;
  final bool isActive;
  final List<PopupMenuItem<T>> items;
  final ValueChanged<T?> onSelected;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isActive
                    ? theme.colorScheme.onSecondaryContainer
                    : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isActive
                  ? theme.colorScheme.onSecondaryContainer
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise Detail Sheet
// ---------------------------------------------------------------------------

/// Exercise detail view matching iOS ExerciseDetailView
/// Shows: About / History / Charts / Records tabs
class _ExerciseDetailSheet extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseDetailSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Grab handle
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (exercise.muscleGroup != null) ...[
                              _buildTag(theme, exercise.muscleGroup!),
                              const SizedBox(width: 8),
                            ],
                            if (exercise.category != null)
                              _buildTag(theme, exercise.category!),
                            if (exercise.equipment != null) ...[
                              const SizedBox(width: 8),
                              _buildTag(theme, exercise.equipment!),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab bar
            TabBar(
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'History'),
                Tab(text: 'Charts'),
                Tab(text: 'Records'),
              ],
              isScrollable: true,
              tabAlignment: TabAlignment.start,
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _buildAboutTab(context, theme),
                  _buildHistoryTab(context, theme),
                  _buildChartsTab(context, theme),
                  _buildRecordsTab(context, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  Widget _buildAboutTab(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercise.description != null && exercise.description!.isNotEmpty) ...[
            Text(
              'Description',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.description!,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          if (exercise.videoUrl != null) ...[
            Text(
              'Video',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No history yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete sets of this exercise to see your history.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsTab(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No data yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete sets to see your progress charts.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsTab(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No records yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Set personal records to see them here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
