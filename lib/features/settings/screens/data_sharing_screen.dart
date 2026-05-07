import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/settings/providers/data_sharing_provider.dart';

// ---------------------------------------------------------------------------
// Data Sharing Screen
// ---------------------------------------------------------------------------

/// Allows a client to choose which data categories to share with their trainer
/// and set a sharing duration (forever or until a custom date).
class DataSharingScreen extends ConsumerStatefulWidget {
  const DataSharingScreen({super.key});

  @override
  ConsumerState<DataSharingScreen> createState() => _DataSharingScreenState();
}

class _DataSharingScreenState extends ConsumerState<DataSharingScreen> {
  // Local copies of sharing preferences (edits are local until saved)
  bool _shareWorkouts = true;
  bool _shareMeasurements = true;
  bool _sharePhotos = true;
  bool _shareCheckIns = true;
  String _expirationType = 'forever';
  DateTime? _expirationDate;

  // Whether we have synced from the provider at least once
  bool _isSynced = false;
  // Whether the user has manually edited any toggle (avoid overwriting)
  bool _userHasEdited = false;

  @override
  void initState() {
    super.initState();
    // Initialize with provider's current state (defaults or cached data)
    final current = ref.read(dataSharingProvider);
    _initFrom(current);
    _isSynced = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dataSharingProvider.notifier).fetchSettings();
    });
  }

  void _initFrom(DataSharingState state) {
    _shareWorkouts = state.shareWorkouts;
    _shareMeasurements = state.shareMeasurements;
    _sharePhotos = state.sharePhotos;
    _shareCheckIns = state.shareCheckIns;
    _expirationType = state.expirationType;
    _expirationDate = state.expirationDate;
  }

  /// True when local state differs from the provider's saved state.
  bool _hasChanges(DataSharingState saved) {
    return _shareWorkouts != saved.shareWorkouts ||
        _shareMeasurements != saved.shareMeasurements ||
        _sharePhotos != saved.sharePhotos ||
        _shareCheckIns != saved.shareCheckIns ||
        _expirationType != saved.expirationType ||
        _expirationDate != saved.expirationDate;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataSharingProvider);
    final theme = Theme.of(context);

    // Listen for fetchSettings completion to sync local state ONE-TIME
    // after data loads (but only if the user hasn't started editing).
    ref.listen<DataSharingState>(dataSharingProvider, (prev, next) {
      if (_isSynced &&
          !_userHasEdited &&
          prev != null &&
          prev.isSaving &&
          !next.isSaving) {
        setState(() => _initFrom(next));
      }
    });

    final bool isLoading = !_isSynced || state.isSaving;

    return PopScope(
      canPop: !_hasChanges(state),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard(context);
        if (discard == true && mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Sharing'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _onCancel(state),
          ),
        ),
        body: isLoading && _isSynced
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(dataSharingProvider.notifier).fetchSettings(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error banner
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ErrorBanner(
                            message: state.error!,
                            onDismiss: () {
                              ref
                                  .read(dataSharingProvider.notifier)
                                  .fetchSettings();
                            },
                          ),
                        ),

                      // Description
                      Text(
                        'Choose what data to share with your trainer',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),

                      // -- Category Toggles --
                      const _SectionHeader(
                        icon: Icons.share,
                        title: 'Categories',
                      ),
                      const SizedBox(height: 12),
                      _SharingCategory(
                        icon: Icons.fitness_center,
                        title: 'Workouts',
                        description:
                            'Share your workout history and statistics',
                        value: _shareWorkouts,
                        onChanged: (v) => setState(() {
                          _shareWorkouts = v;
                          _userHasEdited = true;
                        }),
                      ),
                      const SizedBox(height: 8),
                      _SharingCategory(
                        icon: Icons.monitor_weight,
                        title: 'Measurements',
                        description:
                            'Share weight, body fat, and circumference data',
                        value: _shareMeasurements,
                        onChanged: (v) => setState(() {
                          _shareMeasurements = v;
                          _userHasEdited = true;
                        }),
                      ),
                      const SizedBox(height: 8),
                      _SharingCategory(
                        icon: Icons.photo_library,
                        title: 'Progress Photos',
                        description: 'Share your transformation photos',
                        value: _sharePhotos,
                        onChanged: (v) => setState(() {
                          _sharePhotos = v;
                          _userHasEdited = true;
                        }),
                      ),
                      const SizedBox(height: 8),
                      _SharingCategory(
                        icon: Icons.checklist,
                        title: 'Check-ins',
                        description: 'Share your weekly check-in data',
                        value: _shareCheckIns,
                        onChanged: (v) => setState(() {
                          _shareCheckIns = v;
                          _userHasEdited = true;
                        }),
                      ),
                      const SizedBox(height: 24),

                      // -- Duration Section --
                      const _SectionHeader(
                        icon: Icons.schedule,
                        title: 'Data Sharing Duration',
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How long should your trainer have access'
                                ' to your data?',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'forever',
                                    label: Text('Forever'),
                                  ),
                                  ButtonSegment(
                                    value: 'date',
                                    label: Text('Custom Date'),
                                  ),
                                ],
                                selected: {_expirationType},
                                onSelectionChanged: (selected) {
                                  setState(() {
                                    _expirationType = selected.first;
                                    _userHasEdited = true;
                                    if (_expirationType == 'date' &&
                                        _expirationDate == null) {
                                      _pickDate();
                                    }
                                  });
                                },
                              ),
                              if (_expirationType == 'date' &&
                                  _expirationDate != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Until ${_formatDate(_expirationDate!)}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Change'),
                                      onPressed: _pickDate,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // -- Save Button --
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: state.isSaving ? null : _save,
                          child: state.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _onCancel(DataSharingState state) async {
    if (_hasChanges(state)) {
      final discard = await _confirmDiscard(context);
      if (discard != true) return;
    }
    if (mounted) context.pop();
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. '
          'Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date != null && mounted) {
      setState(() => _expirationDate = date);
    } else if (_expirationDate == null && mounted) {
      // User cancelled and no date was set — revert to Forever
      setState(() => _expirationType = 'forever');
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(dataSharingProvider.notifier);
    final currentState = ref.read(dataSharingProvider);

    // Sync each changed field to the provider before saving
    if (_shareWorkouts != currentState.shareWorkouts) {
      notifier.toggleCategory('workouts');
    }
    if (_shareMeasurements != currentState.shareMeasurements) {
      notifier.toggleCategory('measurements');
    }
    if (_sharePhotos != currentState.sharePhotos) {
      notifier.toggleCategory('photos');
    }
    if (_shareCheckIns != currentState.shareCheckIns) {
      notifier.toggleCategory('checkIns');
    }
    if (_expirationType != currentState.expirationType ||
        _expirationDate != currentState.expirationDate) {
      notifier.setExpiration(_expirationType, _expirationDate);
    }

    await notifier.saveSettings();

    if (mounted) {
      final updatedState = ref.read(dataSharingProvider);
      if (updatedState.error == null) {
        context.pop();
      }
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

// ---------------------------------------------------------------------------
// Shared private widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _SharingCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SharingCategory({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.error,
                size: 20, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close,
                  size: 16, color: theme.colorScheme.onErrorContainer),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
