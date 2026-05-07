import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmController = TextEditingController();
  String? _selectedReason;

  static const _reasons = [
    'Too expensive',
    'Not using enough',
    'Privacy concerns',
    'Other',
  ];

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authProvider.notifier)
          .deleteAccount(reason: _selectedReason);
      if (mounted) {
        context.go('/auth/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),

                  Icon(
                    Icons.warning_amber_rounded,
                    size: 72,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Are you sure?',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This action is permanent and cannot be undone. '
                    'All your data will be deleted and you will be signed out.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error banner
                  if (authState.hasError)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Reason dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                      prefixIcon: Icon(Icons.report_problem_outlined),
                    ),
                    items: _reasons
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedReason = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirmation text field
                  TextFormField(
                    controller: _confirmController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleDelete(),
                    decoration: const InputDecoration(
                      labelText: 'Type "DELETE" to confirm',
                      prefixIcon: Icon(Icons.keyboard),
                    ),
                    validator: (value) {
                      if (value == null || value.trim() != 'DELETE') {
                        return 'Please type DELETE to confirm';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      // Rebuild to keep button state in sync
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 24),

                  // Delete button
                  ElevatedButton(
                    onPressed: authState.isLoading ||
                            _confirmController.text.trim() != 'DELETE'
                        ? null
                        : _handleDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Permanently Delete Account'),
                  ),
                  const SizedBox(height: 16),

                  // Cancel
                  TextButton(
                    onPressed: authState.isLoading ? null : () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
