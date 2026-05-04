import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';

/// Screen for creating a new workout session.
class CreateSessionScreen extends ConsumerStatefulWidget {
  final DateTime initialDate;

  const CreateSessionScreen({
    super.key,
    required this.initialDate,
  });

  @override
  ConsumerState<CreateSessionScreen> createState() =>
      _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _selectedClientId;
  String? _selectedTemplateId;
  bool _isRecurring = false;
  String _recurrencePattern = 'weekly';
  bool _isLoading = false;

  // Mock data for clients and templates
  final List<Map<String, String>> _mockClients = [
    {'id': 'client-1', 'name': 'John Doe'},
    {'id': 'client-2', 'name': 'Jane Smith'},
    {'id': 'client-3', 'name': 'Mike Johnson'},
  ];

  final List<Map<String, String>> _mockTemplates = [
    {'id': 'template-1', 'name': 'Full Body Workout'},
    {'id': 'template-2', 'name': 'Upper Body Focus'},
    {'id': 'template-3', 'name': 'Lower Body Focus'},
    {'id': 'template-4', 'name': 'Cardio Session'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Adjust end time if needed
        if (_endTime.hour < picked.hour ||
            (_endTime.hour == picked.hour && _endTime.minute <= picked.minute)) {
          _endTime = TimeOfDay(
            hour: picked.hour + 1,
            minute: picked.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final data = {
      'name': _titleController.text.trim(),
      'clientId': _selectedClientId,
      if (_selectedTemplateId != null) 'templateId': _selectedTemplateId,
      'startTime': startDateTime.toIso8601String(),
      'endTime': endDateTime.toIso8601String(),
      if (_notesController.text.isNotEmpty)
        'notes': _notesController.text.trim(),
      'repeats': _isRecurring,
      if (_isRecurring) ...{
        'repeatWeeks': _recurrencePattern == 'daily'
            ? 0
            : _recurrencePattern == 'weekly'
                ? 1
                : _recurrencePattern == 'biweekly'
                    ? 2
                    : 4,
        'repeatDays': [startDateTime.weekday % 7],
      },
    };

    final success = await ref.read(calendarProvider.notifier).createSession(data);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session created successfully')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create session')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Session'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Session Title',
                hintText: 'Enter session title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Client selection
            DropdownButtonFormField<String>(
              initialValue: _selectedClientId,
              decoration: const InputDecoration(
                labelText: 'Select Client',
                prefixIcon: Icon(Icons.person),
              ),
              items: _mockClients.map((client) {
                return DropdownMenuItem(
                  value: client['id'],
                  child: Text(client['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClientId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a client';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Template selection
            DropdownButtonFormField<String>(
              initialValue: _selectedTemplateId,
              decoration: const InputDecoration(
                labelText: 'Workout Template (Optional)',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              items: _mockTemplates.map((template) {
                return DropdownMenuItem(
                  value: template['id'],
                  child: Text(template['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTemplateId = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Date and time section
            Text(
              'Date & Time',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Date picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            const SizedBox(height: 12),

            // Time pickers
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Start'),
                    subtitle: Text(_startTime.format(context)),
                    onTap: _selectStartTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time_filled),
                    title: const Text('End'),
                    subtitle: Text(_endTime.format(context)),
                    onTap: _selectEndTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recurrence section
            SwitchListTile(
              title: const Text('Recurring Session'),
              subtitle: const Text('Repeat this session'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _recurrencePattern,
                decoration: const InputDecoration(
                  labelText: 'Recurrence Pattern',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) {
                  setState(() {
                    _recurrencePattern = value!;
                  });
                },
              ),
            ],
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional notes',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Submit button
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Session'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
