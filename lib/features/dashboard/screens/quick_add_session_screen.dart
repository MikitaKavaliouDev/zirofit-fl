import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/shared/widgets/success_view.dart';

// ---------------------------------------------------------------------------
// Simple providers for clients and templates used by the form
// ---------------------------------------------------------------------------

/// A simple state holder for the creation form data.
class SessionCreationData {
  final List<Client> clients;
  final List<WorkoutTemplate> templates;

  const SessionCreationData({
    this.clients = const [],
    this.templates = const [],
  });
}

final sessionCreationDataProvider =
    FutureProvider<SessionCreationData>((ref) async {
  final api = ref.read(apiClientProvider);

  final clientsResponse = await api.get<Map<String, dynamic>>(
    ApiConstants.clients,
  );
  final templatesResponse = await api.get<Map<String, dynamic>>(
    ApiConstants.trainerWorkoutTemplates,
  );

  final clientsRaw =
      (clientsResponse['data'] as List<dynamic>?) ?? [];
  final templatesRaw =
      (templatesResponse['data'] as List<dynamic>?) ?? [];

  final clients = clientsRaw
      .map((e) => Client.fromJson(e as Map<String, dynamic>))
      .toList();
  final templates = templatesRaw
      .map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
      .toList();

  return SessionCreationData(clients: clients, templates: templates);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class QuickAddSessionScreen extends ConsumerStatefulWidget {
  const QuickAddSessionScreen({super.key});

  @override
  ConsumerState<QuickAddSessionScreen> createState() =>
      _QuickAddSessionScreenState();
}

class _QuickAddSessionScreenState
    extends ConsumerState<QuickAddSessionScreen> {
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
  bool _isSuccess = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedClient == null) return;
    if (_selectedTemplate == null) return;

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
          'workout_template_id': _selectedTemplate!.id,
          'start_time': startTime.toIso8601String(),
          'notes': _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        },
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });
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
      return 'Network error. Please try again.';
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return SuccessView(
        title: 'Session Created!',
        message: 'The workout session has been added to the calendar.',
        actionLabel: 'Done',
        onAction: () => Navigator.pop(context, true),
        onDismiss: () => Navigator.pop(context, true),
      );
    }

    final theme = Theme.of(context);
    final creationData = ref.watch(sessionCreationDataProvider);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Add Session'),
      ),
      body: creationData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Failed to load data', style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.invalidate(sessionCreationDataProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data.clients.isEmpty || data.templates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  data.clients.isEmpty
                      ? 'No clients found. Add clients first.'
                      : 'No workout templates found. Create templates first.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error,
                                size: 20,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Client picker
                  Text(
                    'Client',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Client>(
                    initialValue: _selectedClient,
                    hint: const Text('Select a client'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: data.clients.map((client) {
                      return DropdownMenuItem(
                        value: client,
                        child: Text(client.name),
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
                  ),
                  const SizedBox(height: 20),

                  // Template picker
                  Text(
                    'Workout Template',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<WorkoutTemplate>(
                    initialValue: _selectedTemplate,
                    hint: const Text('Select a template'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: data.templates.map((template) {
                      return DropdownMenuItem(
                        value: template,
                        child: Text(template.name),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() => _selectedTemplate = value);
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a template';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date picker
                  Text(
                    'Date',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
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
                  ),
                  const SizedBox(height: 20),

                  // Time picker
                  Text(
                    'Time',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
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
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  Text(
                    'Notes',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Optional notes for the session...',
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
          );
        },
      ),
    );
  }
}
