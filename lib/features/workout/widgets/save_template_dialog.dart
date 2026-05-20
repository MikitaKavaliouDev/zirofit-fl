import 'package:flutter/material.dart';

// =============================================================================
// SaveTemplateDialog
//
/// Matches the iOS `.alert("Save as Template")` pattern from
/// WorkoutSessionView.swift (lines 160–174).
///
/// Shows a dialog with a text field for the template name, a "Save" button,
/// and a "Cancel" button. Returns the entered name (trimmed) when saved, or
/// `null` when cancelled.
///
/// Usage:
/// ```dart
/// final name = await SaveTemplateDialog.show(context, initialName: 'My Workout');
/// if (name != null && name.isNotEmpty) {
///   // save template with name
/// }
/// ```
// =============================================================================

/// Shows the "Save as Template" dialog and returns the entered name, or `null`
/// if the user cancelled.
class SaveTemplateDialog extends StatefulWidget {
  /// Optional pre-filled template name.
  final String initialName;

  const SaveTemplateDialog({super.key, this.initialName = ''});

  /// Convenience method: shows the dialog and returns the entered name.
  ///
  /// Returns `null` when the user taps "Cancel" or dismisses the dialog.
  static Future<String?> show(BuildContext context, {String initialName = ''}) {
    return showDialog<String>(
      context: context,
      builder: (_) => SaveTemplateDialog(initialName: initialName),
    );
  }

  @override
  State<SaveTemplateDialog> createState() => _SaveTemplateDialogState();
}

class _SaveTemplateDialogState extends State<SaveTemplateDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Save as Template'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Template Name',
          hintText: 'Enter a name for this template',
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _onSave(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: _onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _onSave() {
    final name = _controller.text.trim();
    Navigator.of(context).pop(name);
  }
}
