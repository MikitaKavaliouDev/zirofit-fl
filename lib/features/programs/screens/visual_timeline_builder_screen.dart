import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/features/programs/models/timeline_models.dart';
import 'package:zirofit_fl/features/programs/providers/timeline_builder_provider.dart';
import 'package:zirofit_fl/features/programs/widgets/template_picker_sheet.dart';

// ---------------------------------------------------------------------------
// Visual Timeline Builder Screen
// ---------------------------------------------------------------------------

/// Drag-and-drop week/day view for building a program timeline.
///
/// - Horizontal week tabs at the top for navigation and reorder.
/// - Vertical day list for the selected week, each with exercise slots.
/// - Template assignment to slots via the existing [TemplatePickerSheet].
class VisualTimelineBuilderScreen extends ConsumerStatefulWidget {
  const VisualTimelineBuilderScreen({super.key});

  @override
  ConsumerState<VisualTimelineBuilderScreen> createState() =>
      _VisualTimelineBuilderScreenState();
}

class _VisualTimelineBuilderScreenState
    extends ConsumerState<VisualTimelineBuilderScreen> {
  int _selectedWeekIndex = 0;
  final _nameController = TextEditingController();

  /// Local overrides for week names (display only until provider supports it).
  final Map<String, String> _weekNameOverrides = {};

  @override
  void initState() {
    super.initState();
    // Sync the text controller with the provider's current name.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(timelineBuilderProvider);
      _nameController.text = state.programName;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Returns the effective name for a week (local override > provider name).
  String _weekDisplayName(TimelineWeek week) {
    return _weekNameOverrides[week.id] ?? week.name;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineBuilderProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If the selected index is out of range (e.g. after delete), clamp it.
    if (_selectedWeekIndex >= state.weeks.length) {
      _selectedWeekIndex = (state.weeks.length - 1).clamp(0, 0);
    }

    return Scaffold(
      appBar: _buildAppBar(state, theme, colorScheme),
      body: _buildBody(state, theme, colorScheme),
      floatingActionButton: _buildAddWeekFAB(theme, colorScheme),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(
    TimelineBuilderState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      title: GestureDetector(
        onTap: () => _showEditNameDialog(state),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                state.programName.isEmpty ? 'Untitled Program' : state.programName,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.edit,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      actions: [
        // Save button
        IconButton(
          onPressed: state.isSaving ? null : _save,
          icon: state.isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.check),
          tooltip: 'Save Program',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _buildBody(
    TimelineBuilderState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Full-screen loading
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Full-screen error
    if (state.error != null && state.weeks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(timelineBuilderProvider.notifier)
                    .loadProgram(''),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state (shouldn't happen with default init, but handle gracefully)
    if (state.weeks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.view_timeline_outlined,
              size: 56,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No weeks yet. Add your first week to get started.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _addWeek,
              icon: const Icon(Icons.add),
              label: const Text('Add Week'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Week tabs
        _WeekTabsBar(
          weeks: state.weeks,
          weekDisplayNames:
              state.weeks.map((w) => _weekDisplayName(w)).toList(),
          selectedIndex: _selectedWeekIndex,
          onSelect: (index) => setState(() => _selectedWeekIndex = index),
          onLongPress: (index) =>
              _showWeekContextMenu(state.weeks[index], index),
        ),

        const Divider(height: 1),

        // Day list for selected week
        Expanded(
          child: _buildDaysList(
            state.weeks[_selectedWeekIndex],
            theme,
            colorScheme,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Days list
  // ---------------------------------------------------------------------------

  Widget _buildDaysList(
    TimelineWeek week,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), // bottom for FAB
      children: [
        // Week header info
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                '${_weekDisplayName(week)} — ${week.days.length} day${week.days.length == 1 ? '' : 's'}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Day rows
        ...week.days.asMap().entries.map((entry) {
          final dayIndex = entry.key;
          final day = entry.value;
          return _DayRow(
            key: ValueKey(day.id),
            day: day,
            weekId: week.id,
            dayIndex: dayIndex,
            totalDays: week.days.length,
            theme: theme,
            colorScheme: colorScheme,
            onAddSlot: () => _addSlot(week.id, day.id),
            onSlotTap: (slot) => _onSlotTap(slot),
            onRemoveDay: () => _confirmRemoveDay(week.id, day),
          );
        }),

        const SizedBox(height: 8),

        // Add Day button
        OutlinedButton.icon(
          onPressed: () => ref
              .read(timelineBuilderProvider.notifier)
              .addDay(week.id),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Day'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Add Week FAB
  // ---------------------------------------------------------------------------

  Widget? _buildAddWeekFAB(ThemeData theme, ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: _addWeek,
      icon: const Icon(Icons.add),
      label: const Text('Add Week'),
      tooltip: 'Add Week',
    );
  }

  // ---------------------------------------------------------------------------
  // Actions: Week
  // ---------------------------------------------------------------------------

  void _addWeek() {
    ref.read(timelineBuilderProvider.notifier).addWeek();
    setState(() {
      _selectedWeekIndex = ref.read(timelineBuilderProvider).weeks.length - 1;
    });
  }

  void _showWeekContextMenu(TimelineWeek week, int index) {
    final state = ref.read(timelineBuilderProvider);
    final totalWeeks = state.weeks.length;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _weekDisplayName(week),
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Divider(height: 1),

              // Move Left
              if (index > 0)
                ListTile(
                  leading: const Icon(Icons.arrow_back),
                  title: const Text('Move Left'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(timelineBuilderProvider.notifier)
                        .reorderWeeks(index, index - 1);
                    setState(() {
                      _selectedWeekIndex =
                          (_selectedWeekIndex - 1).clamp(0, totalWeeks - 1);
                    });
                  },
                ),

              // Move Right
              if (index < totalWeeks - 1)
                ListTile(
                  leading: const Icon(Icons.arrow_forward),
                  title: const Text('Move Right'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(timelineBuilderProvider.notifier)
                        .reorderWeeks(index, index + 1);
                    setState(() {
                      _selectedWeekIndex =
                          (_selectedWeekIndex + 1).clamp(0, totalWeeks - 1);
                    });
                  },
                ),

              // Rename
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameWeekDialog(week);
                },
              ),

              // Delete
              if (totalWeeks > 1)
                ListTile(
                  leading: Icon(Icons.delete,
                      color: Theme.of(ctx).colorScheme.error),
                  title: Text('Delete',
                      style:
                          TextStyle(color: Theme.of(ctx).colorScheme.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteWeek(week);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameWeekDialog(TimelineWeek week) {
    final controller = TextEditingController(text: _weekDisplayName(week));
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Rename Week'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Week Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  // Update the week name via the weeks list
                  _updateWeekName(week.id, newName);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  /// Updates a week's display name via local override.
  /// The provider does not expose renameWeek yet, so the new name is
  /// stored locally for display and will be persisted when the provider
  /// is extended in a future phase.
  void _updateWeekName(String weekId, String newName) {
    setState(() {
      _weekNameOverrides[weekId] = newName;
    });
  }

  void _confirmDeleteWeek(TimelineWeek week) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Week'),
          content: Text('Are you sure you want to delete "${_weekDisplayName(week)}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ref
                    .read(timelineBuilderProvider.notifier)
                    .removeWeek(week.id);
                setState(() {
                  final len = ref.read(timelineBuilderProvider).weeks.length;
                  if (_selectedWeekIndex >= len) {
                    _selectedWeekIndex = (len - 1).clamp(0, 0);
                  }
                });
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Actions: Day
  // ---------------------------------------------------------------------------

  void _confirmRemoveDay(String weekId, TimelineDay day) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Remove Day'),
          content: Text('Are you sure you want to remove "${day.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ref
                    .read(timelineBuilderProvider.notifier)
                    .removeDay(weekId, day.id);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Actions: Slot / Template
  // ---------------------------------------------------------------------------

  void _addSlot(String weekId, String dayId) {
    // Slots are added by default when a day is created. Additional slot
    // creation is a future enhancement. For now, we show a message.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Multiple slots per day coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSlotTap(TimelineSlot slot) {
    if (slot.hasTemplate) {
      _showSlotOptions(slot);
    } else {
      _showTemplatePicker(slot);
    }
  }

  void _showTemplatePicker(TimelineSlot slot) async {
    final template = await TemplatePickerSheet.show(context);
    if (template == null || !mounted) return;

    ref.read(timelineBuilderProvider.notifier).assignTemplate(
          slot.id,
          template.id,
          template.name,
          0, // exerciseCount — not available from WorkoutTemplate model yet
        );
  }

  void _showSlotOptions(TimelineSlot slot) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  slot.templateName ?? 'Assigned Template',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Change Template'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTemplatePicker(slot);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text('Remove Template',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(timelineBuilderProvider.notifier)
                      .removeTemplate(slot.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Edit program name
  // ---------------------------------------------------------------------------

  void _showEditNameDialog(TimelineBuilderState state) {
    final controller = TextEditingController(text: state.programName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Program Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter program name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref
                      .read(timelineBuilderProvider.notifier)
                      .setName(name);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final state = ref.read(timelineBuilderProvider);

    if (state.programName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a program name first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ref
        .read(timelineBuilderProvider.notifier)
        .saveProgram();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      final errorState = ref.read(timelineBuilderProvider);
      if (errorState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorState.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Week Tabs Bar
// ---------------------------------------------------------------------------

/// Horizontal scrollable list of week chips.
class _WeekTabsBar extends StatelessWidget {
  final List<TimelineWeek> weeks;
  final List<String> weekDisplayNames;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final void Function(int index) onLongPress;

  const _WeekTabsBar({
    required this.weeks,
    required this.weekDisplayNames,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: weeks.length,
        itemBuilder: (context, index) {
          final week = weeks[index];
          final displayName = weekDisplayNames[index];
          final isSelected = index == selectedIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: () => onLongPress(index),
              child: _WeekTabChip(
                week: week,
                displayName: displayName,
                isSelected: isSelected,
                onTap: () => onSelect(index),
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Single week chip in the tabs bar.
class _WeekTabChip extends StatelessWidget {
  final TimelineWeek week;
  final String displayName;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _WeekTabChip({
    required this.week,
    required this.displayName,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Week ${week.weekNumber}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day Row
// ---------------------------------------------------------------------------

/// A single day row containing the day header and its slot cards.
class _DayRow extends StatelessWidget {
  final TimelineDay day;
  final String weekId;
  final int dayIndex;
  final int totalDays;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onAddSlot;
  final void Function(TimelineSlot slot) onSlotTap;
  final VoidCallback onRemoveDay;

  const _DayRow({
    super.key,
    required this.day,
    required this.weekId,
    required this.dayIndex,
    required this.totalDays,
    required this.theme,
    required this.colorScheme,
    required this.onAddSlot,
    required this.onSlotTap,
    required this.onRemoveDay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header row
            Row(
              children: [
                // Day number badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.dayNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    day.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Remove day button
                if (totalDays > 1)
                  IconButton(
                    onPressed: onRemoveDay,
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Remove Day',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Slot cards
            ...day.slots.map((slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _SlotCard(
                    slot: slot,
                    onTap: () => onSlotTap(slot),
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                )),

            // Add slot button
            // Note: hidden for now; multi-slot support is a future enhancement
            // Align(
            //   alignment: Alignment.centerLeft,
            //   child: TextButton.icon(
            //     onPressed: onAddSlot,
            //     icon: const Icon(Icons.add, size: 16),
            //     label: const Text('Add Slot'),
            //     style: TextButton.styleFrom(
            //       visualDensity: VisualDensity.compact,
            //       foregroundColor: colorScheme.primary,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slot Card
// ---------------------------------------------------------------------------

/// Displays a single timeline slot — either empty or assigned to a template.
class _SlotCard extends StatelessWidget {
  final TimelineSlot slot;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _SlotCard({
    required this.slot,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (slot.hasTemplate) {
      return _AssignedSlotCard(
        slot: slot,
        onTap: onTap,
        colorScheme: colorScheme,
        theme: theme,
      );
    }

    return _EmptySlotCard(
      onTap: onTap,
      colorScheme: colorScheme,
      theme: theme,
    );
  }
}

/// Slot card with an assigned template.
class _AssignedSlotCard extends StatelessWidget {
  final TimelineSlot slot;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _AssignedSlotCard({
    required this.slot,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Template icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              // Template info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.templateName ?? 'Template',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (slot.exerciseCount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${slot.exerciseCount} exercise${slot.exerciseCount == 1 ? '' : 's'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Edit indicator
              Icon(
                Icons.edit,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty slot card prompting the user to assign a template.
class _EmptySlotCard extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _EmptySlotCard({
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
              Text(
                'Tap to assign template',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
