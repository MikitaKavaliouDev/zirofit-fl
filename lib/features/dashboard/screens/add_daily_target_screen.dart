import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:zirofit_fl/core/database/app_database.dart';
import 'package:zirofit_fl/core/database/database_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/daily_target_provider.dart';
import 'package:zirofit_fl/shared/widgets/ziro_sheet_header.dart';

// ---------------------------------------------------------------------------
// Target Frequency
// ---------------------------------------------------------------------------

enum TargetFrequency {
  daily('Daily'),
  weekly('Weekly'),
  custom('Custom');

  final String label;
  const TargetFrequency(this.label);
}

// ---------------------------------------------------------------------------
// Target Metric Types
// ---------------------------------------------------------------------------

enum TargetMetric {
  reps('Reps', 'reps', 'exercise'),
  weight('Weight', 'kg', 'exercise'),
  duration('Duration', 'min', 'workout'),
  distance('Distance', 'km', 'custom');

  final String label;
  final String defaultUnit;
  final String typeKey;

  const TargetMetric(this.label, this.defaultUnit, this.typeKey);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AddDailyTargetScreen extends ConsumerStatefulWidget {
  final DateTime? selectedDate;

  const AddDailyTargetScreen({super.key, this.selectedDate});

  @override
  ConsumerState<AddDailyTargetScreen> createState() =>
      _AddDailyTargetScreenState();
}

class _AddDailyTargetScreenState extends ConsumerState<AddDailyTargetScreen> {
  final _formKey = GlobalKey<FormState>();

  // State
  String _searchQuery = '';
  String? _selectedExerciseId;
  String? _selectedExerciseName;
  TargetMetric _selectedMetric = TargetMetric.reps;
  final _valueController = TextEditingController();
  int _stepperValue = 10;
  TargetFrequency _selectedFrequency = TargetFrequency.daily;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Debounce
  Timer? _debounceTimer;
  List<ExerciseSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  // Target list for frequency
  int _customDays = 3;
  final List<String> _selectedDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final Set<String> _customDaySelection = {'Mon', 'Wed', 'Fri'};

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _valueController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Exercise search (debounced from Drift DB)
  // ---------------------------------------------------------------------------

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchExercises(query);
    });
  }

  Future<void> _searchExercises(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final db = ref.read(databaseProvider);
      // Use a simple LIKE query via drift
      final results = await (db.select(db.exercises)
            ..where((tbl) => tbl.name.like('%$query%'))
            ..limit(20))
          .get();

      setState(() {
        _searchResults = results
            .map((r) => ExerciseSearchResult(
                  id: r.id,
                  name: r.name,
                  muscleGroup: r.muscleGroup ?? '',
                  category: r.category ?? '',
                ))
            .toList();
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectExercise(String id, String name) {
    setState(() {
      _selectedExerciseId = id;
      _selectedExerciseName = name;
      _searchQuery = name;
      _showSearchResults = false;
      _searchResults = [];
    });
  }

  void _clearExercise() {
    setState(() {
      _selectedExerciseId = null;
      _selectedExerciseName = null;
      _searchQuery = '';
      _searchResults = [];
    });
  }

  // ---------------------------------------------------------------------------
  // Stepper
  // ---------------------------------------------------------------------------

  void _stepperUp() {
    final current = _parseValue();
    final increment = _selectedMetric == TargetMetric.duration ? 5 : 10;
    setState(() {
      _stepperValue = current + increment;
    });
  }

  void _stepperDown() {
    final current = _parseValue();
    final decrement = _selectedMetric == TargetMetric.duration ? 5 : 10;
    setState(() {
      _stepperValue = (current - decrement).clamp(1, 99999);
    });
  }

  int _parseValue() {
    final text = _valueController.text.trim();
    final parsed = int.tryParse(text);
    return parsed ?? _stepperValue;
  }

  // ---------------------------------------------------------------------------
  // Metric selector
  // ---------------------------------------------------------------------------

  void _onMetricChanged(TargetMetric? metric) {
    if (metric == null || metric == _selectedMetric) return;
    setState(() {
      _selectedMetric = metric;
      _stepperValue = metric == TargetMetric.duration ? 30 : 10;
      _valueController.text = _stepperValue.toString();
    });
  }

  // ---------------------------------------------------------------------------
  // Frequency selector
  // ---------------------------------------------------------------------------

  void _toggleCustomDay(String day) {
    setState(() {
      if (_customDaySelection.contains(day)) {
        _customDaySelection.remove(day);
      } else {
        _customDaySelection.add(day);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedExerciseId == null) {
      setState(() => _errorMessage = 'Please select an exercise');
      return;
    }

    final value = _parseValue();
    if (value <= 0) {
      setState(() => _errorMessage = 'Target value must be greater than 0');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final title = _selectedExerciseName ?? 'Exercise Target';
    final date = widget.selectedDate ?? DateTime.now();

    final target = DailyTarget(
      id: const Uuid().v4(),
      title: title,
      description: '${_selectedMetric.label} target',
      type: _selectedMetric.typeKey,
      targetValue: value.toDouble(),
      unit: _selectedMetric.defaultUnit,
      date: date,
      currentValue: 0,
      isCompleted: false,
      order: 0,
    );

    try {
      await ref.read(dailyTargetProvider.notifier).addTarget(target);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$title" target added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to save target: $e';
      });
    }
  }

  void _onCancel() {
    if (_selectedExerciseId != null || _searchQuery.isNotEmpty ||
        _valueController.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard Target?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard this target?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header using existing ZiroSheetHeader pattern
            ZiroSheetHeader(
              title: 'Add Daily Target',
              showCancel: true,
              showDone: true,
              leadingText: 'Cancel',
              trailingText: 'Save',
              onCancel: _onCancel,
              onDone: _isSubmitting ? null : _onSave,
            ),

            // Error banner
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                color: theme.colorScheme.errorContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Search Exercise
                      _buildSectionLabel(theme, 'Exercise'),
                      const SizedBox(height: 8),
                      _buildExerciseSearchField(theme),

                      // Selected exercise chip
                      if (_selectedExerciseName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _buildSelectedExerciseChip(theme),
                        ),

                      const SizedBox(height: 24),

                      // Section: Target Type
                      _buildSectionLabel(theme, 'Target Type'),
                      const SizedBox(height: 8),
                      _buildMetricSelector(theme),

                      const SizedBox(height: 24),

                      // Section: Target Value with stepper
                      _buildSectionLabel(theme, 'Target Value'),
                      const SizedBox(height: 8),
                      _buildValueInput(theme),

                      const SizedBox(height: 24),

                      // Section: Frequency
                      _buildSectionLabel(theme, 'Frequency'),
                      const SizedBox(height: 8),
                      _buildFrequencySelector(theme),

                      // Custom day picker
                      if (_selectedFrequency == TargetFrequency.custom)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildCustomDayPicker(theme),
                        ),

                      const SizedBox(height: 24),

                      // Summary
                      _buildSummaryCard(theme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section label
  // ---------------------------------------------------------------------------

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Search
  // ---------------------------------------------------------------------------

  Widget _buildExerciseSearchField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Search exercises...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearExercise,
                      )
                    : null),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            if (_selectedExerciseId != null) {
              _clearExercise();
            } else {
              _onSearchChanged(value);
            }
          },
          controller: TextEditingController.fromValue(
            TextEditingValue(
              text: _searchQuery,
              selection: TextSelection.collapsed(
                offset: _searchQuery.length,
              ),
            ),
          ),
          validator: (_) {
            if (_selectedExerciseId == null) return 'Select an exercise';
            return null;
          },
        ),

        // Search results dropdown
        if (_showSearchResults && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return InkWell(
                  onTap: () =>
                      _selectExercise(result.id, result.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (result.muscleGroup.isNotEmpty)
                                Text(
                                  result.muscleGroup,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Empty results
        if (_showSearchResults &&
            _searchResults.isEmpty &&
            !_isSearching &&
            _searchQuery.length >= 2)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              'No exercises found for "$_searchQuery"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Selected Exercise Chip
  // ---------------------------------------------------------------------------

  Widget _buildSelectedExerciseChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            _selectedExerciseName!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearExercise,
            child: Icon(
              Icons.close,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Metric Type Selector
  // ---------------------------------------------------------------------------

  Widget _buildMetricSelector(ThemeData theme) {
    return Row(
      children: TargetMetric.values.map((metric) {
        final isSelected = metric == _selectedMetric;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: metric == TargetMetric.distance ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => _onMetricChanged(metric),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _metricIcon(metric),
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _metricIcon(TargetMetric metric) {
    switch (metric) {
      case TargetMetric.reps:
        return Icons.repeat;
      case TargetMetric.weight:
        return Icons.monitor_weight_outlined;
      case TargetMetric.duration:
        return Icons.timer_outlined;
      case TargetMetric.distance:
        return Icons.straighten_outlined;
    }
  }

  // ---------------------------------------------------------------------------
  // Value Input with Stepper
  // ---------------------------------------------------------------------------

  Widget _buildValueInput(ThemeData theme) {
    return Row(
      children: [
        // Decrement button
        IconButton.filled(
          onPressed: _stepperDown,
          icon: const Icon(Icons.remove, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Value input
        Expanded(
          child: TextFormField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Target',
              suffixText: _selectedMetric.defaultUnit,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            onChanged: (_) {
              setState(() {
                _errorMessage = null;
              });
            },
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final parsed = double.tryParse(v.trim());
              if (parsed == null || parsed <= 0) return 'Enter a valid number';
              return null;
            },
          ),
        ),

        const SizedBox(width: 12),

        // Increment button
        IconButton.filled(
          onPressed: _stepperUp,
          icon: const Icon(Icons.add, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Frequency Selector
  // ---------------------------------------------------------------------------

  Widget _buildFrequencySelector(ThemeData theme) {
    return Row(
      children: TargetFrequency.values.map((freq) {
        final isSelected = freq == _selectedFrequency;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: freq == TargetFrequency.custom ? 0 : 8,
            ),
            child: ChoiceChip(
              label: Text(
                freq.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedFrequency = freq);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Custom Day Picker
  // ---------------------------------------------------------------------------

  Widget _buildCustomDayPicker(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedDays.map((day) {
        final isSelected = _customDaySelection.contains(day);
        return GestureDetector(
          onTap: () => _toggleCustomDay(day),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Center(
              child: Text(
                day.substring(0, 1),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary Card
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCard(ThemeData theme) {
    final hasExercise = _selectedExerciseName != null;
    final value = _parseValue();

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Summary',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _summaryRow(
              theme,
              'Exercise',
              hasExercise ? _selectedExerciseName! : 'Not selected',
              hasExercise ? Colors.green : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            _summaryRow(
              theme,
              'Target',
              '$value ${_selectedMetric.defaultUnit}',
              theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            _summaryRow(
              theme,
              'Type',
              _selectedMetric.label,
              theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            _summaryRow(
              theme,
              'Frequency',
              _selectedFrequency == TargetFrequency.custom
                  ? '${_customDaySelection.length} days/week'
                  : _selectedFrequency.label,
              theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    ThemeData theme,
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search Result model
// ---------------------------------------------------------------------------

class ExerciseSearchResult {
  final String id;
  final String name;
  final String muscleGroup;
  final String category;

  const ExerciseSearchResult({
    required this.id,
    required this.name,
    this.muscleGroup = '',
    this.category = '',
  });
}
