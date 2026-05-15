import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';

// =============================================================================
// Client Create Program Screen
// =============================================================================

/// Client-facing screen for creating a new program.
///
/// Supports two modes:
/// - **Manual**: name (required), description (optional), category (optional)
/// - **AI Generate**: duration (week/month), focus area (required)
///
/// Uses [clientProgramsProvider] for state management and API calls.
class ClientCreateProgramScreen extends ConsumerStatefulWidget {
  const ClientCreateProgramScreen({super.key});

  @override
  ConsumerState<ClientCreateProgramScreen> createState() =>
      _ClientCreateProgramScreenState();
}

class _ClientCreateProgramScreenState
    extends ConsumerState<ClientCreateProgramScreen> {
  final _formKey = GlobalKey<FormState>();

  // -- Mode --
  String _selectedMode = 'manual';

  // -- Manual fields --
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;

  // -- AI fields --
  String _selectedDuration = 'week';
  final _focusController = TextEditingController();

  // -- Submission guard --
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Submit: Manual
  // ---------------------------------------------------------------------------

  Future<void> _submitManual() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final result =
        await ref.read(clientProgramsProvider.notifier).createManualProgram(
              name: name,
              description: description.isNotEmpty ? description : null,
            );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program created!')),
      );
      context.pop(true);
    }
  }

  // ---------------------------------------------------------------------------
  // Submit: AI
  // ---------------------------------------------------------------------------

  Future<void> _submitAI() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final focus = _focusController.text.trim();

    final result =
        await ref.read(clientProgramsProvider.notifier).createAIProgram(
              duration: _selectedDuration,
              focus: focus,
            );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program created!')),
      );
      context.pop(true);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientProgramsProvider);
    final theme = Theme.of(context);
    final categories = state.library?.categories ?? [];

    final buttonLabel = _selectedMode == 'manual' ? 'Create Program' : 'Generate Program';
    final onPressed = _selectedMode == 'manual' ? _submitManual : _submitAI;
    final isBusy = _isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Program'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -- Error Banner --
              if (state.error != null && !_isSubmitting)
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
                            Icons.error_outline,
                            size: 20,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.error!,
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

              // -- Mode Toggle --
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'manual',
                    label: Text('Manual'),
                    icon: Icon(Icons.edit_outlined),
                  ),
                  ButtonSegment(
                    value: 'ai',
                    label: Text('AI Generate'),
                    icon: Icon(Icons.auto_awesome_outlined),
                  ),
                ],
                selected: {_selectedMode},
                onSelectionChanged: (value) {
                  setState(() => _selectedMode = value.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                ),
              ),
              const SizedBox(height: 24),

              // -- Content --
              if (_selectedMode == 'manual')
                _buildManualContent(theme, categories)
              else
                _buildAIContent(theme),

              const SizedBox(height: 24),

              // -- Submit Button --
              FilledButton(
                onPressed: isBusy ? null : onPressed,
                child: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Manual Mode Content
  // ---------------------------------------------------------------------------

  Widget _buildManualContent(ThemeData theme, List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Program Name',
            hintText: 'e.g. Beginner Full Body',
            isDense: true,
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'Brief description of the program',
            isDense: true,
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 16),

        // Category
        if (categories.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category (optional)',
              isDense: true,
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No category'),
              ),
              ...categories.map(
                (cat) => DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedCategory = value);
            },
          ),
        if (categories.isEmpty)
          DropdownButtonFormField<String>(
            initialValue: null,
            disabledHint: const Text('No categories available'),
            decoration: const InputDecoration(
              labelText: 'Category (optional)',
              isDense: true,
            ),
            isExpanded: true,
            items: const [],
            onChanged: null,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // AI Mode Content
  // ---------------------------------------------------------------------------

  Widget _buildAIContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          'Describe your program',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),

        // Duration
        Text(
          'Duration',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'week',
              label: Text('Week'),
              icon: Icon(Icons.calendar_view_week_outlined),
            ),
            ButtonSegment(
              value: 'month',
              label: Text('Month'),
              icon: Icon(Icons.date_range_outlined),
            ),
          ],
          selected: {_selectedDuration},
          onSelectionChanged: (value) {
            setState(() => _selectedDuration = value.first);
          },
          style: const ButtonStyle(
            visualDensity: VisualDensity.comfortable,
          ),
        ),
        const SizedBox(height: 20),

        // Focus
        TextFormField(
          controller: _focusController,
          decoration: const InputDecoration(
            labelText: 'Focus Area',
            hintText: 'e.g. strength training, hypertrophy, fat loss',
            isDense: true,
          ),
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Focus area is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Info text
        Text(
          'The AI will generate a complete program based on your focus area',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
