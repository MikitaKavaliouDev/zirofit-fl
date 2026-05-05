import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Loading / caching providers
// ---------------------------------------------------------------------------

/// Cached list of clients for the picker.
final _clientsProvider = FutureProvider<List<Client>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>(ApiConstants.clients);
  final raw = (response['data'] as List<dynamic>?) ?? [];
  return raw.map((e) => Client.fromJson(e as Map<String, dynamic>)).toList();
});

/// Cached list of workout templates for the picker.
final _templatesProvider = FutureProvider<List<WorkoutTemplate>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response =
      await api.get<Map<String, dynamic>>(ApiConstants.trainerWorkoutTemplates);
  final raw = (response['data'] as List<dynamic>?) ?? [];
  return raw
      .map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Recently used client IDs (SharedPreferences helper)
// ---------------------------------------------------------------------------

const _recentClientsPrefsKey = 'quick_add_recent_clients';

Future<List<String>> _loadRecentClientIds() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_recentClientsPrefsKey) ?? [];
}

Future<void> _saveRecentClientId(String clientId) async {
  final prefs = await SharedPreferences.getInstance();
  final recent = await _loadRecentClientIds();
  // Keep the newest at front, max 5 entries
  final updated = [clientId, ...recent.where((id) => id != clientId)].take(5).toList();
  await prefs.setStringList(_recentClientsPrefsKey, updated);
}

// ---------------------------------------------------------------------------
// Dialog widget
// ---------------------------------------------------------------------------

/// A modal bottom sheet for quickly creating a planned workout session.
///
/// Usage:
/// ```dart
/// final created = await QuickAddSessionDialog.show(context);
/// if (created == true) { /* refresh dashboard */ }
/// ```
class QuickAddSessionDialog extends ConsumerStatefulWidget {
  const QuickAddSessionDialog({super.key});

  /// Shows the dialog as a modal bottom sheet.
  ///
  /// Returns `true` if a session was successfully created, `null` if
  /// the user dismissed the sheet without creating.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _QuickAddSessionShell(),
    );
  }

  @override
  ConsumerState<QuickAddSessionDialog> createState() =>
      _QuickAddSessionDialogState();
}

/// Thin wrapper so the static [show] method can pass a [Consumer].
class _QuickAddSessionShell extends ConsumerWidget {
  const _QuickAddSessionShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const QuickAddSessionDialog();
  }
}

class _QuickAddSessionDialogState
    extends ConsumerState<QuickAddSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  Client? _selectedClient;
  WorkoutTemplate? _selectedTemplate;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay(
    hour: DateTime.now().hour,
    minute: DateTime.now().minute,
  );
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  // Track previous client to handle recent ordering
  List<Client> _clients = [];
  List<String> _recentClientIds = [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ---- Pickers -----------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select session date',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Select session time',
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  // ---- Submission --------------------------------------------------------

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedClient == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        ApiConstants.trainerCalendar,
        body: {
          'client_id': _selectedClient!.id,
          if (_selectedTemplate != null)
            'workout_template_id': _selectedTemplate!.id,
          'start_time': startTime.toIso8601String(),
          if (_notesController.text.trim().isNotEmpty)
            'notes': _notesController.text.trim(),
        },
      );

      await _saveRecentClientId(_selectedClient!.id);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = _extractErrorMessage(e);
      });
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final errorData = error.response!.data as Map;
        if (errorData['error'] is Map) {
          return (errorData['error'] as Map)['message'] as String? ??
              'An error occurred';
        }
        if (errorData['message'] is String) {
          return errorData['message'] as String;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }

  // ---- Build helpers -----------------------------------------------------

  void _sortByRecent(List<Client> clients) {
    // Move recently selected clients to the top
    if (_recentClientIds.isEmpty) return;
    final recent = <Client>[];
    final rest = <Client>[];
    for (final c in clients) {
      if (_recentClientIds.contains(c.id)) {
        recent.add(c);
      } else {
        rest.add(c);
      }
    }
    recent.sort(
      (a, b) =>
          _recentClientIds.indexOf(a.id).compareTo(
            _recentClientIds.indexOf(b.id),
          ),
    );
    _clients = [...recent, ...rest];
  }

  // ---- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Quick Add Session',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Form body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error banner
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.error,
                                        size: 20,
                                        color: theme.colorScheme.onErrorContainer),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color:
                                              theme.colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Client picker
                        _buildLabel(theme, 'Client'),
                        const SizedBox(height: 8),
                        _buildClientPicker(theme),

                        const SizedBox(height: 20),

                        // Template picker
                        _buildLabel(theme, 'Workout Template (optional)'),
                        const SizedBox(height: 8),
                        _buildTemplatePicker(theme),

                        const SizedBox(height: 20),

                        // Date
                        _buildLabel(theme, 'Date'),
                        const SizedBox(height: 8),
                        _buildDatePicker(theme, dateFormat),

                        const SizedBox(height: 20),

                        // Time
                        _buildLabel(theme, 'Time'),
                        const SizedBox(height: 8),
                        _buildTimePicker(theme),

                        const SizedBox(height: 20),

                        // Notes
                        _buildLabel(theme, 'Notes (optional)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText: 'Session notes...',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isSubmitting,
                        ),

                        const SizedBox(height: 24),

                        // Submit button
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(
                            _isSubmitting ? 'Creating...' : 'Create Session',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildClientPicker(ThemeData theme) {
    return ref.watch(_clientsProvider).when(
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => Text(
        'Failed to load clients',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      data: (clients) {
        if (clients.isEmpty) {
          return Text(
            'No clients found. Add clients first.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }

        // Load recent clients once
        if (_clients.isEmpty) {
          _clients = clients;
          _loadRecentClientIds().then((ids) {
            if (mounted) {
              setState(() {
                _recentClientIds = ids;
                _sortByRecent(clients);
              });
            }
          });
        }

        return DropdownButtonFormField<Client>(
          initialValue: _selectedClient,
          hint: const Text('Select a client'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
          items: _clients.map((client) {
            return DropdownMenuItem(
              value: client,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      client.name.isNotEmpty
                          ? client.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      client.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_recentClientIds.contains(client.id))
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.history,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: _isSubmitting
              ? null
              : (value) {
                  setState(() => _selectedClient = value);
                },
          validator: (value) {
            if (value == null) return 'Please select a client';
            return null;
          },
        );
      },
    );
  }

  Widget _buildTemplatePicker(ThemeData theme) {
    return ref.watch(_templatesProvider).when(
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => Text(
        'Failed to load templates',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      data: (templates) {
        return DropdownButtonFormField<WorkoutTemplate>(
          initialValue: _selectedTemplate,
          hint: const Text('None'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'No template',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...templates.map((template) {
              return DropdownMenuItem(
                value: template,
                child: Text(template.name),
              );
            }),
          ],
          onChanged: _isSubmitting
              ? null
              : (value) {
                  setState(() => _selectedTemplate = value);
                },
        );
      },
    );
  }

  Widget _buildDatePicker(ThemeData theme, DateFormat dateFormat) {
    return InkWell(
      onTap: _isSubmitting ? null : _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.calendar_month_outlined),
          suffixIcon: Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(),
        ),
        child: Text(
          dateFormat.format(_selectedDate),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildTimePicker(ThemeData theme) {
    return InkWell(
      onTap: _isSubmitting ? null : _pickTime,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.access_time),
          suffixIcon: Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _selectedTime.format(context),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
